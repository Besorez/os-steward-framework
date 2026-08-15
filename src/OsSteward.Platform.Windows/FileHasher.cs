using System.Security.Cryptography;

namespace OsSteward.Platform.Windows;

public static class FileHasher
{
    /// <summary>
    /// SHA-256 of a file, or null with an explicit reason appended to
    /// <paramref name="unavailable"/> — hash failures are never silent.
    /// </summary>
    public static string? TrySha256(string filePath, List<string> unavailable)
    {
        try
        {
            using var stream = File.OpenRead(filePath);
            var hash = SHA256.HashData(stream);
            return Convert.ToHexStringLower(hash);
        }
        catch (UnauthorizedAccessException)
        {
            unavailable.Add("sha256:PermissionDenied");
            return null;
        }
        catch (IOException ex)
        {
            unavailable.Add($"sha256:CollectorFailed {ex.GetType().Name}");
            return null;
        }
    }
}
