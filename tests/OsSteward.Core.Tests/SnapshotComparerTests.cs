using OsSteward.Core.Serialization;
using OsSteward.Core.Snapshots;
using OsSteward.Core.Telemetry;
using Xunit;

namespace OsSteward.Core.Tests;

public class SnapshotComparerTests
{
    private static Snapshot<TItem> LoadFixture<TItem>(string fileName)
    {
        var path = Path.Combine(AppContext.BaseDirectory, "fixtures", fileName);
        var snapshot = OsJson.Deserialize<Snapshot<TItem>>(File.ReadAllText(path));
        Assert.NotNull(snapshot);
        return snapshot!;
    }

    [Fact]
    public void ProcessDiff_ReportsAddedAndRemoved()
    {
        var before = LoadFixture<ProcessRecord>("process-snapshot-before.json");
        var after = LoadFixture<ProcessRecord>("process-snapshot-after.json");

        var diff = SnapshotComparer.Compare(
            before.Items, after.Items,
            p => $"{p.Name}|{p.ExecutablePath ?? "?"}");

        Assert.Single(diff.Added);
        Assert.Equal("newtool.exe", diff.Added[0].Name);
        Assert.Single(diff.Removed);
        Assert.Equal("testapp.exe", diff.Removed[0].Name);
        Assert.Empty(diff.Changed);
    }

    [Fact]
    public void StartupDiff_ReportsChangedCommand()
    {
        var before = LoadFixture<StartupEntry>("startup-snapshot-before.json");
        var after = LoadFixture<StartupEntry>("startup-snapshot-after.json");

        var diff = SnapshotComparer.Compare(
            before.Items, after.Items,
            e => $"{e.Location}|{e.Name}",
            (b, a) => b.Command == a.Command ? [] : new[] { "command" });

        Assert.Single(diff.Added);
        Assert.Equal("NewTool", diff.Added[0].Name);
        Assert.Empty(diff.Removed);
        Assert.Single(diff.Changed);
        Assert.Equal(["command"], diff.Changed[0].ChangedFields);
        Assert.Equal("TestSync", diff.Changed[0].After.Name);
    }

    [Fact]
    public void DuplicateKeys_CollapseToFirstOccurrence()
    {
        var reference = new[] { "a", "a", "b" };
        var current = new[] { "a", "c" };

        var diff = SnapshotComparer.Compare(reference, current, s => s);

        Assert.Equal(["c"], diff.Added);
        Assert.Equal(["b"], diff.Removed);
    }
}
