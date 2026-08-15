using OsSteward.Core.Snapshots;
using OsSteward.State;
using Xunit;

namespace OsSteward.State.Tests;

public class RuntimePathsTests
{
    [Fact]
    public void ExplicitOverride_WinsOverEverything()
    {
        var paths = new RuntimePaths(@"C:\Users\TestUser\CustomRoot");

        Assert.Equal(@"C:\Users\TestUser\CustomRoot", paths.Root);
        Assert.StartsWith(paths.Root, paths.SnapshotsDir);
    }

    [Fact]
    public void EnvironmentVariable_OverridesDefault()
    {
        var previous = Environment.GetEnvironmentVariable(RuntimePaths.HomeEnvironmentVariable);
        try
        {
            Environment.SetEnvironmentVariable(RuntimePaths.HomeEnvironmentVariable, @"C:\Users\TestUser\EnvRoot");
            Assert.Equal(@"C:\Users\TestUser\EnvRoot", new RuntimePaths().Root);
        }
        finally
        {
            Environment.SetEnvironmentVariable(RuntimePaths.HomeEnvironmentVariable, previous);
        }
    }

    [Fact]
    public void Default_IsUnderLocalApplicationData()
    {
        var previous = Environment.GetEnvironmentVariable(RuntimePaths.HomeEnvironmentVariable);
        try
        {
            Environment.SetEnvironmentVariable(RuntimePaths.HomeEnvironmentVariable, null);
            var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            Assert.Equal(Path.Combine(localAppData, "OSSteward"), new RuntimePaths().Root);
        }
        finally
        {
            Environment.SetEnvironmentVariable(RuntimePaths.HomeEnvironmentVariable, previous);
        }
    }
}

public sealed class TempRuntime : IDisposable
{
    public TempRuntime()
    {
        var root = Path.Combine(Path.GetTempPath(), "ossteward-tests", Guid.NewGuid().ToString("N"));
        Paths = new RuntimePaths(root);
        Paths.EnsureCreated();
    }

    public RuntimePaths Paths { get; }

    // Test-harness cleanup of its own temp directory; the framework itself
    // exposes no delete capability.
    public void Dispose() => Directory.Delete(Paths.Root, recursive: true);
}

public class SnapshotStoreTests : IDisposable
{
    private readonly TempRuntime _runtime = new();

    public void Dispose() => _runtime.Dispose();

    [Fact]
    public void SaveAndLoad_RoundTrips()
    {
        var store = new SnapshotStore(_runtime.Paths);
        var snapshot = new Snapshot<string>(1, "processes", "20260101-000000-000",
            new DateTimeOffset(2026, 1, 1, 0, 0, 0, TimeSpan.Zero), ["alpha", "beta"]);

        var path = store.Save(snapshot);

        Assert.True(File.Exists(path));
        Assert.StartsWith(_runtime.Paths.SnapshotsDir, path);

        var loaded = store.Load<string>("processes", "20260101-000000-000");
        Assert.NotNull(loaded);
        Assert.Equal(snapshot.Items, loaded!.Items);
        Assert.Equal(snapshot.CreatedAt, loaded.CreatedAt);
    }

    [Fact]
    public void LoadLatest_ReturnsNewestByIdOrder()
    {
        var store = new SnapshotStore(_runtime.Paths);
        var older = new DateTimeOffset(2026, 1, 1, 0, 0, 0, TimeSpan.Zero);
        var newer = new DateTimeOffset(2026, 2, 1, 0, 0, 0, TimeSpan.Zero);
        store.Save(new Snapshot<string>(1, "startup", SnapshotStore.NewSnapshotId(older), older, ["old"]));
        store.Save(new Snapshot<string>(1, "startup", SnapshotStore.NewSnapshotId(newer), newer, ["new"]));

        var latest = store.LoadLatest<string>("startup");

        Assert.NotNull(latest);
        Assert.Equal(["new"], latest!.Items);
        Assert.Equal(2, store.ListIds("startup").Count);
    }

    [Fact]
    public void MissingSnapshot_ReturnsNull_NotFakeData()
    {
        var store = new SnapshotStore(_runtime.Paths);

        Assert.Null(store.Load<string>("processes", "nonexistent"));
        Assert.Null(store.LoadLatest<string>("processes"));
        Assert.Empty(store.ListIds("processes"));
    }
}

public class PreferencesStoreTests : IDisposable
{
    private readonly TempRuntime _runtime = new();

    public void Dispose() => _runtime.Dispose();

    [Fact]
    public void MissingFile_YieldsDefaultAutoLanguage()
        => Assert.Equal("auto", new PreferencesStore(_runtime.Paths).Load().Language);

    [Theory]
    [InlineData("en")]
    [InlineData("uk")]
    [InlineData("auto")]
    public void SaveAndLoad_RoundTripsAllowedLanguages(string language)
    {
        var store = new PreferencesStore(_runtime.Paths);

        store.Save(new Preferences(language));

        Assert.Equal(language, store.Load().Language);
    }

    [Fact]
    public void UnsupportedLanguage_IsRejected()
        => Assert.Throws<ArgumentException>(
            () => new PreferencesStore(_runtime.Paths).Save(new Preferences("de")));

    [Fact]
    public void CorruptFile_FallsBackToDefault()
    {
        File.WriteAllText(_runtime.Paths.PreferencesFile, "{not json");

        Assert.Equal("auto", new PreferencesStore(_runtime.Paths).Load().Language);
    }
}
