namespace OsSteward.Core.Snapshots;

/// <summary>
/// Machine state captured at a point in time. Snapshots are stored ONLY in
/// local runtime storage (%LOCALAPPDATA%\OSSteward), never in the repository.
/// Schema documented in docs/concepts/Snapshot-Model.md.
/// </summary>
public sealed record Snapshot<TItem>(
    int SchemaVersion,
    string Category,
    string SnapshotId,
    DateTimeOffset CreatedAt,
    IReadOnlyList<TItem> Items)
{
    public const int CurrentSchemaVersion = 1;
}

public static class SnapshotCategories
{
    public const string Processes = "processes";
    public const string Startup = "startup";
    public const string Services = "services";

    public static readonly IReadOnlyList<string> All = [Processes, Startup, Services];
}
