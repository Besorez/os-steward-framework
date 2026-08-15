namespace OsSteward.Core.Telemetry;

public enum StartupSource
{
    Registry,
    Folder,
}

public enum StartupScope
{
    Machine,
    User,
}

/// <summary>
/// Normalized startup / autorun entry (registry Run keys, startup folders).
/// </summary>
public sealed record StartupEntry(
    StartupSource Source,
    StartupScope Scope,
    string Location,
    string Name,
    string Command);
