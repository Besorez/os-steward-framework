using System.ComponentModel;
using ModelContextProtocol.Server;
using OsSteward.Core.ToolResults;
using OsSteward.State;

namespace OsSteward.Mcp.Tools;

[McpServerToolType]
public static class ConfigTools
{
    private static readonly RuntimePaths Paths = new();

    [McpServerTool(Name = "os_config_get", ReadOnly = true)]
    [Description("Reads OS Steward user preferences from local runtime storage. Currently: interaction language ('auto', 'en', 'uk'). Internal schema identifiers stay English regardless of language.")]
    public static string ConfigGet()
        => ToolEnvelope.Guard("os_config_get", () =>
        {
            var preferences = new PreferencesStore(Paths).Load();
            return ToolEnvelope.Ok("os_config_get", new
            {
                preferences.Language,
                allowedLanguages = PreferencesStore.AllowedLanguages,
            });
        });

    [McpServerTool(Name = "os_config_set")]
    [Description("Sets an OS Steward user preference in local runtime storage (a config file only; no system change). Supported key: 'language' with value 'auto', 'en', or 'uk'.")]
    public static string ConfigSet(
        [Description("Preference key. Supported: 'language'.")] string key,
        [Description("Preference value. For 'language': 'auto', 'en', or 'uk'.")] string value)
        => ToolEnvelope.Guard("os_config_set", () =>
        {
            if (key != "language")
            {
                return ToolEnvelope.Fail(
                    "os_config_set", ErrorKind.InvalidRequest,
                    $"Unknown preference key '{key}'. Supported: language.");
            }

            if (!PreferencesStore.AllowedLanguages.Contains(value))
            {
                return ToolEnvelope.Fail(
                    "os_config_set", ErrorKind.InvalidRequest,
                    $"Unsupported language '{value}'. Allowed: {string.Join(", ", PreferencesStore.AllowedLanguages)}.");
            }

            Paths.EnsureCreated();
            new PreferencesStore(Paths).Save(new Preferences(value));
            return ToolEnvelope.Ok("os_config_set", new { language = value });
        });
}
