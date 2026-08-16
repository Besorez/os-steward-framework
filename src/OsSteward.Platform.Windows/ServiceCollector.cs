using System.Management;
using OsSteward.Core.Telemetry;

namespace OsSteward.Platform.Windows;

/// <summary>
/// Read-only Windows service telemetry via WMI (Win32_Service). Descriptions
/// and binary signature/hash are only retrieved for single-service
/// inspection (minimum necessary data, OSF-INV-011).
/// </summary>
public sealed class ServiceCollector
{
    private const string ListQuery =
        "SELECT Name, DisplayName, State, StartMode, ProcessId, PathName, StartName FROM Win32_Service";

    public CollectionOutcome<IReadOnlyList<ServiceRecord>> CollectAll()
    {
        var records = new List<ServiceRecord>();
        var warnings = new List<string>();

        using var searcher = new ManagementObjectSearcher(ListQuery);
        foreach (var obj in searcher.Get())
        {
            using var service = (ManagementObject)obj;
            records.Add(ToRecord(service));
        }

        if (records.Count == 0)
        {
            warnings.Add("serviceList:NoData WMI returned no services; the collector likely failed.");
        }

        return new CollectionOutcome<IReadOnlyList<ServiceRecord>>(records, warnings);
    }

    public CollectionOutcome<ServiceInspection?> Inspect(string serviceName)
    {
        var warnings = new List<string>();
        var escapedName = serviceName.Replace("\\", "\\\\").Replace("'", "\\'");

        using var searcher = new ManagementObjectSearcher(
            $"SELECT * FROM Win32_Service WHERE Name = '{escapedName}'");
        using var results = searcher.Get();
        ManagementObject? service = null;
        foreach (var obj in results)
        {
            service = (ManagementObject)obj;
            break;
        }

        if (service is null)
        {
            return new CollectionOutcome<ServiceInspection?>(null, warnings);
        }

        try
        {
            var record = ToRecord(service);
            var unavailable = new List<string>(record.UnavailableFields);

            var description = service["Description"] as string;

            string? executablePath = null;
            SignatureInfo? signature = null;
            string? sha256 = null;
            if (record.PathName is not null)
            {
                executablePath = TryResolveExecutablePath(record.PathName);
                if (executablePath is null)
                {
                    unavailable.Add("executablePath:NotAvailable could not resolve from PathName");
                    unavailable.Add("signature:NotAvailable");
                    unavailable.Add("sha256:NotAvailable");
                }
                else
                {
                    signature = SignatureInspector.Inspect(executablePath);
                    sha256 = FileHasher.TrySha256(executablePath, unavailable);
                }
            }
            else
            {
                unavailable.Add("executablePath:NotAvailable no PathName");
            }

            var inspection = new ServiceInspection(
                record.Name,
                record.DisplayName,
                record.State,
                record.StartMode,
                record.ProcessId,
                record.PathName,
                record.Account,
                description,
                executablePath,
                signature,
                sha256,
                unavailable);

            return new CollectionOutcome<ServiceInspection?>(inspection, warnings);
        }
        finally
        {
            service.Dispose();
        }
    }

    /// <summary>
    /// Extracts the executable from a service command line. Quoted paths are
    /// taken verbatim; unquoted paths (which may legally contain spaces) are
    /// resolved by progressively extending the candidate and probing the
    /// filesystem — the same rule Windows itself applies.
    /// </summary>
    public static string? TryResolveExecutablePath(string pathName)
    {
        var trimmed = pathName.Trim();
        if (trimmed.Length == 0)
        {
            return null;
        }

        if (trimmed.StartsWith('"'))
        {
            var closing = trimmed.IndexOf('"', 1);
            return closing > 1 ? trimmed[1..closing] : null;
        }

        var parts = trimmed.Split(' ');
        var candidate = "";
        foreach (var part in parts)
        {
            candidate = candidate.Length == 0 ? part : candidate + " " + part;
            var probe = candidate.EndsWith(".exe", StringComparison.OrdinalIgnoreCase)
                ? candidate
                : candidate + ".exe";
            if (File.Exists(probe))
            {
                return probe;
            }

            if (File.Exists(candidate))
            {
                return candidate;
            }
        }

        // Nothing on disk matched (e.g. arguments only, or the binary is
        // gone) — fall back to the first token so evidence is still visible.
        return parts[0].Length > 0 ? parts[0] : null;
    }

    private static ServiceRecord ToRecord(ManagementObject service)
    {
        var unavailable = new List<string>();

        var name = service["Name"] as string ?? "?";
        var displayName = service["DisplayName"] as string ?? name;
        var state = service["State"] as string ?? "Unknown";
        var startMode = service["StartMode"] as string ?? "Unknown";

        int? processId = null;
        if (service["ProcessId"] is not null)
        {
            var pid = Convert.ToInt32(service["ProcessId"]);
            processId = pid == 0 ? null : pid;
        }

        var pathName = service["PathName"] as string;
        if (pathName is null)
        {
            unavailable.Add("pathName:NotAvailable");
        }

        var account = service["StartName"] as string;

        return new ServiceRecord(
            name, displayName, state, startMode, processId, pathName, account, unavailable);
    }
}
