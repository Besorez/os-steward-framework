using OsSteward.Core.Serialization;

namespace OsSteward.State;

/// <summary>
/// User preferences. Stored locally in &lt;runtime&gt;/config/preferences.json,
/// never in Git. Internal identifiers stay English; only the presentation
/// layer localizes (OSF-INV-013/014).
/// </summary>
public sealed record Preferences(string Language)
{
    public static readonly Preferences Default = new("auto");
}

public sealed class PreferencesStore(RuntimePaths paths)
{
    public static readonly IReadOnlyList<string> AllowedLanguages = ["auto", "en", "uk"];

    public Preferences Load()
    {
        if (!File.Exists(paths.PreferencesFile))
        {
            return Preferences.Default;
        }

        try
        {
            var loaded = OsJson.Deserialize<Preferences>(File.ReadAllText(paths.PreferencesFile));
            if (loaded is null || !AllowedLanguages.Contains(loaded.Language))
            {
                return Preferences.Default;
            }

            return loaded;
        }
        catch (System.Text.Json.JsonException)
        {
            return Preferences.Default;
        }
    }

    public void Save(Preferences preferences)
    {
        if (!AllowedLanguages.Contains(preferences.Language))
        {
            throw new ArgumentException(
                $"Unsupported language '{preferences.Language}'. Allowed: {string.Join(", ", AllowedLanguages)}.",
                nameof(preferences));
        }

        Directory.CreateDirectory(paths.ConfigDir);
        File.WriteAllText(paths.PreferencesFile, OsJson.Serialize(preferences));
    }
}
