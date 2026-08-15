using System.Text.RegularExpressions;

namespace OsSteward.Privacy;

/// <summary>
/// Deterministic redaction of machine-identifying values in text destined
/// to leave raw local storage (MCP tool output, exports).
///
/// Rules:
///   current user profile path -> %USERPROFILE%
///   any other user-profile segment -> &lt;USER&gt;
///   current machine name -> &lt;LOCAL_MACHINE&gt;
///   current username token -> &lt;USER&gt;
///
/// Patterns tolerate single backslashes, JSON-escaped double backslashes,
/// and forward slashes so redaction can safely run over serialized JSON.
/// Canonical rules: docs/privacy/Privacy-Model.md.
/// </summary>
public sealed class Redactor
{
    private static readonly string[] WellKnownProfiles =
        ["Public", "Default", "Default User", "All Users", "TestUser", "ExampleUser"];

    private readonly List<(Regex Pattern, string Replacement)> _rules = [];

    public Redactor(string userName, string userProfilePath, string machineName)
    {
        if (!string.IsNullOrWhiteSpace(userProfilePath))
        {
            _rules.Add((BuildPathPattern(userProfilePath), "%USERPROFILE%"));
        }

        var wellKnown = string.Join("|", WellKnownProfiles.Select(Regex.Escape));
        _rules.Add((
            new Regex(
                $@"(?<prefix>[A-Za-z]:[\\/]{{1,2}}Users[\\/]{{1,2}})(?!(?:{wellKnown}|<USER>)(?:[\\/""']|$))(?<user>[^\\/:*?""<>|\r\n]+)",
                RegexOptions.IgnoreCase | RegexOptions.CultureInvariant),
            "${prefix}<USER>"));

        if (!string.IsNullOrWhiteSpace(machineName) && machineName.Length >= 4)
        {
            _rules.Add((
                new Regex($@"\b{Regex.Escape(machineName)}\b",
                    RegexOptions.IgnoreCase | RegexOptions.CultureInvariant),
                "<LOCAL_MACHINE>"));
        }

        if (!string.IsNullOrWhiteSpace(userName) && userName.Length >= 3)
        {
            _rules.Add((
                new Regex($@"\b{Regex.Escape(userName)}\b",
                    RegexOptions.IgnoreCase | RegexOptions.CultureInvariant),
                "<USER>"));
        }
    }

    public static Redactor ForCurrentMachine() => new(
        Environment.UserName,
        Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
        Environment.MachineName);

    public string Redact(string text)
    {
        foreach (var (pattern, replacement) in _rules)
        {
            text = pattern.Replace(text, replacement);
        }

        return text;
    }

    /// <summary>
    /// Builds a pattern matching the given filesystem path with any of
    /// "\", "\\" (JSON-escaped) or "/" as separators, case-insensitively.
    /// </summary>
    private static Regex BuildPathPattern(string path)
    {
        var segments = path
            .Split(['\\', '/'], StringSplitOptions.RemoveEmptyEntries)
            .Select(Regex.Escape);
        var pattern = string.Join(@"[\\/]{1,2}", segments);
        return new Regex(pattern, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
    }
}
