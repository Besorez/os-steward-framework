namespace OsSteward.Core.Telemetry;

/// <summary>
/// Normalized Windows service inventory item. State and startMode keep the
/// provider's English identifiers (e.g. "Running", "Auto").
/// </summary>
public sealed record ServiceRecord(
    string Name,
    string DisplayName,
    string State,
    string StartMode,
    int? ProcessId,
    string? PathName,
    string? Account,
    IReadOnlyList<string> UnavailableFields);

/// <summary>
/// In-depth inspection of a single service (os.service.inspect): adds the
/// description, the resolved executable, its signature and hash.
/// </summary>
public sealed record ServiceInspection(
    string Name,
    string DisplayName,
    string State,
    string StartMode,
    int? ProcessId,
    string? PathName,
    string? Account,
    string? Description,
    string? ExecutablePath,
    SignatureInfo? Signature,
    string? Sha256,
    IReadOnlyList<string> UnavailableFields);
