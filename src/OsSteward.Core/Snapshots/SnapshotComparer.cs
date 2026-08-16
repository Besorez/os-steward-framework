namespace OsSteward.Core.Snapshots;

public sealed record ChangedItem<TItem>(
    string Key,
    TItem Before,
    TItem After,
    IReadOnlyList<string> ChangedFields);

public sealed record SnapshotDiff<TItem>(
    IReadOnlyList<TItem> Added,
    IReadOnlyList<TItem> Removed,
    IReadOnlyList<ChangedItem<TItem>> Changed);

/// <summary>
/// Deterministic snapshot comparison. This is deliberately NOT a learned
/// baseline: it reports what differs between two captured states and makes
/// no judgement about whether a difference is malicious
/// (docs/concepts/Baseline-Model.md).
/// </summary>
public static class SnapshotComparer
{
    /// <param name="keySelector">Stable identity of an item across snapshots
    /// (e.g. executable path for processes, location + name for startup entries).
    /// Duplicate keys are collapsed to the first occurrence.</param>
    /// <param name="fieldComparer">Optional: returns the names of fields that
    /// differ between two items sharing a key. Null or empty = unchanged.</param>
    public static SnapshotDiff<TItem> Compare<TItem>(
        IReadOnlyList<TItem> reference,
        IReadOnlyList<TItem> current,
        Func<TItem, string> keySelector,
        Func<TItem, TItem, IReadOnlyList<string>>? fieldComparer = null)
    {
        var referenceByKey = ToFirstOccurrenceMap(reference, keySelector);
        var currentByKey = ToFirstOccurrenceMap(current, keySelector);

        var added = new List<TItem>();
        var changed = new List<ChangedItem<TItem>>();

        foreach (var (key, item) in currentByKey)
        {
            if (!referenceByKey.TryGetValue(key, out var before))
            {
                added.Add(item);
                continue;
            }

            if (fieldComparer is not null)
            {
                var changedFields = fieldComparer(before, item);
                if (changedFields is { Count: > 0 })
                {
                    changed.Add(new ChangedItem<TItem>(key, before, item, changedFields));
                }
            }
        }

        var removed = referenceByKey
            .Where(pair => !currentByKey.ContainsKey(pair.Key))
            .Select(pair => pair.Value)
            .ToList();

        return new SnapshotDiff<TItem>(added, removed, changed);
    }

    private static Dictionary<string, TItem> ToFirstOccurrenceMap<TItem>(
        IReadOnlyList<TItem> items,
        Func<TItem, string> keySelector)
    {
        var map = new Dictionary<string, TItem>(StringComparer.OrdinalIgnoreCase);
        foreach (var item in items)
        {
            var key = keySelector(item);
            if (!map.ContainsKey(key))
            {
                map[key] = item;
            }
        }

        return map;
    }
}
