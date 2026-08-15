using OsSteward.Core.Serialization;
using OsSteward.Core.Snapshots;

namespace OsSteward.State;

/// <summary>
/// Stores snapshots as JSON files under &lt;runtime&gt;/state/snapshots/&lt;category&gt;/.
/// Append-only by design: the store can create and read snapshots but has no
/// delete capability (OSF-INV-001).
/// </summary>
public sealed class SnapshotStore(RuntimePaths paths)
{
    public static string NewSnapshotId(DateTimeOffset createdAt)
        => createdAt.ToUniversalTime().ToString("yyyyMMdd-HHmmss-fff");

    public string Save<TItem>(Snapshot<TItem> snapshot)
    {
        var categoryDir = CategoryDir(snapshot.Category);
        Directory.CreateDirectory(categoryDir);
        var filePath = Path.Combine(categoryDir, snapshot.SnapshotId + ".json");
        File.WriteAllText(filePath, OsJson.Serialize(snapshot));
        return filePath;
    }

    public IReadOnlyList<string> ListIds(string category)
    {
        var categoryDir = CategoryDir(category);
        if (!Directory.Exists(categoryDir))
        {
            return [];
        }

        return Directory.GetFiles(categoryDir, "*.json")
            .Select(Path.GetFileNameWithoutExtension)
            .Where(id => id is not null)
            .Select(id => id!)
            .OrderBy(id => id, StringComparer.Ordinal)
            .ToList();
    }

    public Snapshot<TItem>? Load<TItem>(string category, string snapshotId)
    {
        var filePath = Path.Combine(CategoryDir(category), snapshotId + ".json");
        if (!File.Exists(filePath))
        {
            return null;
        }

        return OsJson.Deserialize<Snapshot<TItem>>(File.ReadAllText(filePath));
    }

    public Snapshot<TItem>? LoadLatest<TItem>(string category)
    {
        var latestId = ListIds(category).LastOrDefault();
        return latestId is null ? null : Load<TItem>(category, latestId);
    }

    private string CategoryDir(string category)
        => Path.Combine(paths.SnapshotsDir, category);
}
