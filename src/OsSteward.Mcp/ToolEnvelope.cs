using OsSteward.Core.Serialization;
using OsSteward.Core.ToolResults;
using OsSteward.Privacy;

namespace OsSteward.Mcp;

/// <summary>
/// Every tool response leaves the server as a redacted, serialized
/// <see cref="ToolResult"/> envelope. Redaction runs over the serialized JSON
/// so no code path can leak a raw identifier by forgetting a field.
/// </summary>
internal static class ToolEnvelope
{
    private static readonly Redactor Redactor = Redactor.ForCurrentMachine();

    public static string Ok(string source, object? data, IReadOnlyList<string>? warnings = null)
        => Finish(ToolResult.Ok(source, data, warnings, RedactionState.Redacted));

    public static string Fail(string source, ErrorKind kind, string message)
        => Finish(ToolResult.Fail(source, kind, message).AsRedacted());

    public static string Guard(string source, Func<string> action)
    {
        try
        {
            return action();
        }
        catch (Exception ex)
        {
            return Fail(source, ErrorKind.CollectorFailed, $"{ex.GetType().Name}: {ex.Message}");
        }
    }

    private static string Finish(ToolResult result)
        => Redactor.Redact(OsJson.Serialize(result));
}
