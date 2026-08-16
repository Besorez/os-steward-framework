using System.ComponentModel;
using ModelContextProtocol.Server;
using OsSteward.Core.Snapshots;
using OsSteward.Core.Telemetry;
using OsSteward.Core.ToolResults;
using OsSteward.Platform.Windows;
using OsSteward.State;

namespace OsSteward.Mcp.Tools;

[McpServerToolType]
public static class SnapshotTools
{
    private static readonly RuntimePaths Paths = new();

    [McpServerTool(Name = "os_snapshot_create")]
    [Description("Captures the current state of one category ('processes' or 'startup') and stores it as a snapshot in local runtime storage (%LOCALAPPDATA%\\OSSteward). Creates a local file only; changes nothing on the system. Snapshots never enter Git.")]
    public static string SnapshotCreate(
        [Description("Snapshot category: 'processes' or 'startup'.")] string category)
        => ToolEnvelope.Guard("os_snapshot_create", () =>
        {
            Paths.EnsureCreated();
            var store = new SnapshotStore(Paths);
            var createdAt = DateTimeOffset.UtcNow;
            var snapshotId = SnapshotStore.NewSnapshotId(createdAt);

            int itemCount;
            IReadOnlyList<string> warnings;
            switch (category)
            {
                case SnapshotCategories.Processes:
                {
                    var (records, collectWarnings) = new ProcessCollector().CollectAll();
                    store.Save(new Snapshot<ProcessRecord>(
                        Snapshot<ProcessRecord>.CurrentSchemaVersion, category, snapshotId, createdAt, records));
                    itemCount = records.Count;
                    warnings = collectWarnings;
                    break;
                }

                case SnapshotCategories.Startup:
                {
                    var (entries, collectWarnings) = new StartupCollector().Collect();
                    store.Save(new Snapshot<StartupEntry>(
                        Snapshot<StartupEntry>.CurrentSchemaVersion, category, snapshotId, createdAt, entries));
                    itemCount = entries.Count;
                    warnings = collectWarnings;
                    break;
                }

                case SnapshotCategories.Services:
                {
                    var (records, collectWarnings) = new ServiceCollector().CollectAll();
                    store.Save(new Snapshot<ServiceRecord>(
                        Snapshot<ServiceRecord>.CurrentSchemaVersion, category, snapshotId, createdAt, records));
                    itemCount = records.Count;
                    warnings = collectWarnings;
                    break;
                }

                default:
                    return ToolEnvelope.Fail(
                        "os_snapshot_create", ErrorKind.InvalidRequest,
                        $"Unknown category '{category}'. Allowed: {string.Join(", ", SnapshotCategories.All)}.");
            }

            return ToolEnvelope.Ok("os_snapshot_create", new
            {
                snapshotId,
                category,
                itemCount,
                storageRoot = Paths.Root,
            }, warnings);
        });

    [McpServerTool(Name = "os_baseline_compare", ReadOnly = true)]
    [Description("Compares the CURRENT live state of a category ('processes' or 'startup') against a stored snapshot (latest by default, or a specific snapshotId). Reports added / removed / changed items. Detects deviation only — it does not judge whether a change is good or bad.")]
    public static string BaselineCompare(
        [Description("Category to compare: 'processes' or 'startup'.")] string category,
        [Description("Optional snapshot id to compare against. Omit to use the most recent snapshot.")]
        string? referenceSnapshotId = null)
        => ToolEnvelope.Guard("os_baseline_compare", () =>
        {
            var store = new SnapshotStore(Paths);
            switch (category)
            {
                case SnapshotCategories.Processes:
                {
                    var reference = referenceSnapshotId is null
                        ? store.LoadLatest<ProcessRecord>(category)
                        : store.Load<ProcessRecord>(category, referenceSnapshotId);
                    if (reference is null)
                    {
                        return NoReference(category, referenceSnapshotId);
                    }

                    var (current, warnings) = new ProcessCollector().CollectAll();
                    var diff = SnapshotComparer.Compare(
                        reference.Items, current, CategoryComparers.ProcessKey);
                    return DiffResult(reference.SnapshotId, reference.CreatedAt, category, diff, warnings);
                }

                case SnapshotCategories.Startup:
                {
                    var reference = referenceSnapshotId is null
                        ? store.LoadLatest<StartupEntry>(category)
                        : store.Load<StartupEntry>(category, referenceSnapshotId);
                    if (reference is null)
                    {
                        return NoReference(category, referenceSnapshotId);
                    }

                    var (current, warnings) = new StartupCollector().Collect();
                    var diff = SnapshotComparer.Compare(
                        reference.Items, current,
                        CategoryComparers.StartupKey,
                        CategoryComparers.StartupChangedFields);
                    return DiffResult(reference.SnapshotId, reference.CreatedAt, category, diff, warnings);
                }

                case SnapshotCategories.Services:
                {
                    var reference = referenceSnapshotId is null
                        ? store.LoadLatest<ServiceRecord>(category)
                        : store.Load<ServiceRecord>(category, referenceSnapshotId);
                    if (reference is null)
                    {
                        return NoReference(category, referenceSnapshotId);
                    }

                    var (current, warnings) = new ServiceCollector().CollectAll();
                    var diff = SnapshotComparer.Compare(
                        reference.Items, current,
                        CategoryComparers.ServiceKey,
                        CategoryComparers.ServiceChangedFields);
                    return DiffResult(reference.SnapshotId, reference.CreatedAt, category, diff, warnings);
                }

                default:
                    return ToolEnvelope.Fail(
                        "os_baseline_compare", ErrorKind.InvalidRequest,
                        $"Unknown category '{category}'. Allowed: {string.Join(", ", SnapshotCategories.All)}.");
            }
        });

    private static string NoReference(string category, string? referenceSnapshotId)
        => ToolEnvelope.Fail(
            "os_baseline_compare", ErrorKind.NoData,
            referenceSnapshotId is null
                ? $"No stored snapshot for category '{category}'. Create one first with os_snapshot_create."
                : $"Snapshot '{referenceSnapshotId}' not found for category '{category}'.");

    private static string DiffResult<TItem>(
        string referenceId,
        DateTimeOffset referenceCreatedAt,
        string category,
        SnapshotDiff<TItem> diff,
        IReadOnlyList<string> warnings)
        => ToolEnvelope.Ok("os_baseline_compare", new
        {
            category,
            referenceSnapshotId = referenceId,
            referenceCreatedAt,
            addedCount = diff.Added.Count,
            removedCount = diff.Removed.Count,
            changedCount = diff.Changed.Count,
            added = diff.Added,
            removed = diff.Removed,
            changed = diff.Changed,
        }, warnings);
}
