namespace OsSteward.Core.ToolResults;

/// <summary>
/// Explicit failure kinds. Access problems are never reported as "no anomaly"
/// (see docs/architecture/Constitution.md, error-handling rules).
/// </summary>
public enum ErrorKind
{
    NoData,
    PermissionDenied,
    CollectorFailed,
    Unsupported,
    NotAvailable,
    InvalidRequest,
}

/// <summary>
/// Whether the payload still contains raw local identifiers or has been
/// passed through the redaction layer (OsSteward.Privacy).
/// </summary>
public enum RedactionState
{
    RawLocal,
    Redacted,
}

public sealed record ToolError(ErrorKind Kind, string Message);

/// <summary>
/// The single output envelope for every OS Steward MCP tool.
/// Contract documented in mcp/README.md.
/// </summary>
public sealed record ToolResult(
    bool Success,
    DateTimeOffset Timestamp,
    string Source,
    object? Data,
    IReadOnlyList<string> Warnings,
    IReadOnlyList<ToolError> Errors,
    RedactionState RedactionState)
{
    public static ToolResult Ok(
        string source,
        object? data,
        IReadOnlyList<string>? warnings = null,
        RedactionState redactionState = RedactionState.RawLocal)
        => new(true, DateTimeOffset.UtcNow, source, data, warnings ?? [], [], redactionState);

    public static ToolResult Fail(string source, ErrorKind kind, string message)
        => new(false, DateTimeOffset.UtcNow, source, null, [], [new ToolError(kind, message)], RedactionState.RawLocal);

    public ToolResult AsRedacted() => this with { RedactionState = RedactionState.Redacted };
}
