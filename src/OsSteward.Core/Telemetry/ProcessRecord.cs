namespace OsSteward.Core.Telemetry;

/// <summary>
/// Normalized process inventory item as produced by a process collector.
/// Fields that could not be read (e.g. protected processes) are listed in
/// <see cref="UnavailableFields"/> as "field:reason" instead of being
/// silently omitted.
/// </summary>
public sealed record ProcessRecord(
    int Pid,
    string Name,
    int? ParentPid,
    string? ExecutablePath,
    DateTimeOffset? StartTime,
    long? WorkingSetBytes,
    double? TotalCpuSeconds,
    IReadOnlyList<string> UnavailableFields);

public sealed record ProcessRef(int Pid, string Name);

public enum SignatureStatus
{
    Signed,
    Unsigned,
    Invalid,
    Unknown,
}

public sealed record SignatureInfo(SignatureStatus Status, string? Signer);

/// <summary>
/// In-depth inspection of a single process (os.process.inspect).
/// </summary>
public sealed record ProcessInspection(
    int Pid,
    string Name,
    int? ParentPid,
    string? ExecutablePath,
    string? CommandLine,
    string? Owner,
    DateTimeOffset? StartTime,
    long? WorkingSetBytes,
    double? TotalCpuSeconds,
    SignatureInfo? Signature,
    string? Sha256,
    IReadOnlyList<ProcessRef> ParentChain,
    IReadOnlyList<ProcessRef> Children,
    IReadOnlyList<string> UnavailableFields);

public sealed record ProcessTreeNode(
    int Pid,
    string Name,
    string? ExecutablePath,
    IReadOnlyList<ProcessTreeNode> Children);
