using System.Text.Json;
using System.Text.Json.Serialization;

namespace OsSteward.Core.Serialization;

/// <summary>
/// Canonical JSON settings for all OS Steward artifacts (tool results,
/// snapshots, findings). camelCase properties, enums serialized as
/// camelCase strings. Identifiers are always English regardless of the
/// user's presentation language (OSF-INV-013/014).
/// </summary>
public static class OsJson
{
    public static readonly JsonSerializerOptions Options = new(JsonSerializerDefaults.Web)
    {
        WriteIndented = true,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) },
    };

    public static string Serialize<T>(T value) => JsonSerializer.Serialize(value, Options);

    public static T? Deserialize<T>(string json) => JsonSerializer.Deserialize<T>(json, Options);
}
