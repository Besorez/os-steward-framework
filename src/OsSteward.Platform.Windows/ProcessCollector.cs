using System.Management;
using OsSteward.Core.Telemetry;

namespace OsSteward.Platform.Windows;

/// <summary>
/// Read-only process telemetry via WMI (Win32_Process). Command lines and
/// owners are only retrieved for single-process inspection, not for full
/// listings (minimum necessary data, OSF-INV-011).
/// </summary>
public sealed class ProcessCollector
{
    private const string ListQuery =
        "SELECT ProcessId, ParentProcessId, Name, ExecutablePath, CreationDate, WorkingSetSize, KernelModeTime, UserModeTime FROM Win32_Process";

    public CollectionOutcome<IReadOnlyList<ProcessRecord>> CollectAll()
    {
        var records = new List<ProcessRecord>();
        var warnings = new List<string>();

        using var searcher = new ManagementObjectSearcher(ListQuery);
        foreach (var obj in searcher.Get())
        {
            using var process = (ManagementObject)obj;
            records.Add(ToRecord(process));
        }

        if (records.Count == 0)
        {
            warnings.Add("processList:NoData WMI returned no processes; the collector likely failed.");
        }

        return new CollectionOutcome<IReadOnlyList<ProcessRecord>>(records, warnings);
    }

    public CollectionOutcome<ProcessInspection?> Inspect(int pid)
    {
        var warnings = new List<string>();
        var unavailable = new List<string>();

        using var searcher = new ManagementObjectSearcher(
            $"SELECT * FROM Win32_Process WHERE ProcessId = {pid}");
        using var results = searcher.Get();
        ManagementObject? process = null;
        foreach (var obj in results)
        {
            process = (ManagementObject)obj;
            break;
        }

        if (process is null)
        {
            return new CollectionOutcome<ProcessInspection?>(null, warnings);
        }

        try
        {
            var baseRecord = ToRecord(process);
            unavailable.AddRange(baseRecord.UnavailableFields);

            var commandLine = process["CommandLine"] as string;
            if (commandLine is null)
            {
                unavailable.Add("commandLine:NotAvailable");
            }

            var owner = GetOwner(process, unavailable);

            SignatureInfo? signature = null;
            string? sha256 = null;
            if (baseRecord.ExecutablePath is not null)
            {
                signature = SignatureInspector.Inspect(baseRecord.ExecutablePath);
                sha256 = FileHasher.TrySha256(baseRecord.ExecutablePath, unavailable);
            }
            else
            {
                unavailable.Add("signature:NotAvailable executable path unknown");
                unavailable.Add("sha256:NotAvailable executable path unknown");
            }

            var pidMap = BuildPidMap();
            var parentChain = BuildParentChain(baseRecord, pidMap);
            var children = pidMap.Values
                .Where(r => r.ParentPid == pid && r.Pid != pid)
                .Select(r => new ProcessRef(r.Pid, r.Name))
                .ToList();

            var inspection = new ProcessInspection(
                baseRecord.Pid,
                baseRecord.Name,
                baseRecord.ParentPid,
                baseRecord.ExecutablePath,
                commandLine,
                owner,
                baseRecord.StartTime,
                baseRecord.WorkingSetBytes,
                baseRecord.TotalCpuSeconds,
                signature,
                sha256,
                parentChain,
                children,
                unavailable);

            return new CollectionOutcome<ProcessInspection?>(inspection, warnings);
        }
        finally
        {
            process.Dispose();
        }
    }

    public CollectionOutcome<IReadOnlyList<ProcessTreeNode>> CollectTree(int? rootPid = null)
    {
        var (records, warnings) = CollectAll();
        var byPid = new Dictionary<int, ProcessRecord>();
        foreach (var record in records)
        {
            byPid.TryAdd(record.Pid, record);
        }

        var childrenByParent = records
            .Where(r => r.ParentPid is not null && r.ParentPid != r.Pid)
            .GroupBy(r => r.ParentPid!.Value)
            .ToDictionary(g => g.Key, g => g.ToList());

        List<ProcessRecord> roots;
        if (rootPid is int pid)
        {
            if (!byPid.TryGetValue(pid, out var rootRecord))
            {
                return new CollectionOutcome<IReadOnlyList<ProcessTreeNode>>(
                    [], [.. warnings, $"processTree:NoData no process with pid {pid}"]);
            }

            roots = [rootRecord];
        }
        else
        {
            // A root is a process whose parent is gone or unknown. PID reuse can
            // fabricate false parent links; the visited set below guards cycles.
            roots = records
                .Where(r => r.ParentPid is null || !byPid.ContainsKey(r.ParentPid.Value) || r.ParentPid == r.Pid)
                .ToList();
        }

        var visited = new HashSet<int>();
        var nodes = roots.Select(r => BuildNode(r, childrenByParent, visited)).ToList();
        return new CollectionOutcome<IReadOnlyList<ProcessTreeNode>>(nodes, warnings);
    }

    private static ProcessTreeNode BuildNode(
        ProcessRecord record,
        Dictionary<int, List<ProcessRecord>> childrenByParent,
        HashSet<int> visited)
    {
        visited.Add(record.Pid);
        var children = new List<ProcessTreeNode>();
        if (childrenByParent.TryGetValue(record.Pid, out var childRecords))
        {
            foreach (var child in childRecords.Where(c => !visited.Contains(c.Pid)))
            {
                children.Add(BuildNode(child, childrenByParent, visited));
            }
        }

        return new ProcessTreeNode(record.Pid, record.Name, record.ExecutablePath, children);
    }

    private Dictionary<int, ProcessRecord> BuildPidMap()
    {
        var (records, _) = CollectAll();
        var map = new Dictionary<int, ProcessRecord>();
        foreach (var record in records)
        {
            map.TryAdd(record.Pid, record);
        }

        return map;
    }

    private static IReadOnlyList<ProcessRef> BuildParentChain(
        ProcessRecord start,
        Dictionary<int, ProcessRecord> byPid)
    {
        var chain = new List<ProcessRef>();
        var seen = new HashSet<int> { start.Pid };
        var current = start;
        while (current.ParentPid is int parentPid
            && byPid.TryGetValue(parentPid, out var parent)
            && seen.Add(parentPid))
        {
            chain.Add(new ProcessRef(parent.Pid, parent.Name));
            current = parent;
        }

        return chain;
    }

    private static ProcessRecord ToRecord(ManagementObject process)
    {
        var unavailable = new List<string>();

        var pid = Convert.ToInt32(process["ProcessId"]);
        var name = process["Name"] as string ?? $"pid-{pid}";
        int? parentPid = process["ParentProcessId"] is null
            ? null
            : Convert.ToInt32(process["ParentProcessId"]);

        var executablePath = process["ExecutablePath"] as string;
        if (executablePath is null)
        {
            unavailable.Add("executablePath:NotAvailable");
        }

        DateTimeOffset? startTime = null;
        if (process["CreationDate"] is string creationDate)
        {
            try
            {
                startTime = ManagementDateTimeConverter.ToDateTime(creationDate);
            }
            catch (ArgumentOutOfRangeException)
            {
                unavailable.Add("startTime:NotAvailable unparsable CIM datetime");
            }
        }
        else
        {
            unavailable.Add("startTime:NotAvailable");
        }

        long? workingSet = process["WorkingSetSize"] is null
            ? null
            : Convert.ToInt64(process["WorkingSetSize"]);

        double? totalCpuSeconds = null;
        if (process["KernelModeTime"] is not null && process["UserModeTime"] is not null)
        {
            var totalHundredNs = Convert.ToUInt64(process["KernelModeTime"])
                + Convert.ToUInt64(process["UserModeTime"]);
            totalCpuSeconds = totalHundredNs / 10_000_000.0;
        }

        return new ProcessRecord(
            pid, name, parentPid, executablePath, startTime, workingSet, totalCpuSeconds, unavailable);
    }

    private static string? GetOwner(ManagementObject process, List<string> unavailable)
    {
        try
        {
            var outParams = process.InvokeMethod("GetOwner", null, null);
            var returnValue = Convert.ToInt32(outParams["ReturnValue"]);
            if (returnValue == 0 && outParams["User"] is string user)
            {
                var domain = outParams["Domain"] as string;
                return string.IsNullOrEmpty(domain) ? user : $"{domain}\\{user}";
            }

            unavailable.Add("owner:PermissionDenied");
            return null;
        }
        catch (ManagementException)
        {
            unavailable.Add("owner:PermissionDenied");
            return null;
        }
    }
}
