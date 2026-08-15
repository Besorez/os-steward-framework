namespace OsSteward.State;

/// <summary>
/// Resolves the local runtime root. All machine state lives here — physically
/// outside the Git repository (OSF-INV-009/010).
///
/// Resolution order:
///   1. explicit constructor override (tests, tooling)
///   2. OSSTEWARD_HOME environment variable
///   3. %LOCALAPPDATA%\OSSteward
/// </summary>
public sealed class RuntimePaths
{
    public const string HomeEnvironmentVariable = "OSSTEWARD_HOME";

    public RuntimePaths(string? rootOverride = null)
    {
        Root = rootOverride
            ?? Environment.GetEnvironmentVariable(HomeEnvironmentVariable)
            ?? Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "OSSteward");
    }

    public string Root { get; }

    public string ConfigDir => Path.Combine(Root, "config");

    public string StateDir => Path.Combine(Root, "state");

    public string SnapshotsDir => Path.Combine(StateDir, "snapshots");

    public string BaselinesDir => Path.Combine(StateDir, "baselines");

    public string HistoryDir => Path.Combine(StateDir, "history");

    public string FindingsDir => Path.Combine(Root, "findings");

    public string ReportsDir => Path.Combine(Root, "reports");

    public string LogsDir => Path.Combine(Root, "logs");

    public string PreferencesFile => Path.Combine(ConfigDir, "preferences.json");

    public void EnsureCreated()
    {
        foreach (var dir in new[]
        {
            Root, ConfigDir, StateDir, SnapshotsDir, BaselinesDir,
            HistoryDir, FindingsDir, ReportsDir, LogsDir,
        })
        {
            Directory.CreateDirectory(dir);
        }
    }
}
