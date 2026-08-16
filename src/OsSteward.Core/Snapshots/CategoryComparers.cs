using OsSteward.Core.Telemetry;

namespace OsSteward.Core.Snapshots;

/// <summary>
/// Identity keys and changed-field detectors per snapshot category, shared
/// by baseline comparison. Deviation detection only — no judgement.
/// </summary>
public static class CategoryComparers
{
    public static string ProcessKey(ProcessRecord p) => $"{p.Name}|{p.ExecutablePath ?? "?"}";

    public static string StartupKey(StartupEntry e) => $"{e.Location}|{e.Name}";

    public static string ServiceKey(ServiceRecord s) => s.Name;

    public static IReadOnlyList<string> StartupChangedFields(StartupEntry before, StartupEntry after)
        => before.Command == after.Command ? [] : new[] { "command" };

    /// <summary>
    /// Configuration changes only: state flips (running/stopped) are normal
    /// operation, not a change worth flagging in a baseline diff.
    /// </summary>
    public static IReadOnlyList<string> ServiceChangedFields(ServiceRecord before, ServiceRecord after)
    {
        var changed = new List<string>();
        if (!string.Equals(before.PathName, after.PathName, StringComparison.OrdinalIgnoreCase))
        {
            changed.Add("pathName");
        }

        if (!string.Equals(before.StartMode, after.StartMode, StringComparison.OrdinalIgnoreCase))
        {
            changed.Add("startMode");
        }

        if (!string.Equals(before.Account, after.Account, StringComparison.OrdinalIgnoreCase))
        {
            changed.Add("account");
        }

        return changed;
    }
}
