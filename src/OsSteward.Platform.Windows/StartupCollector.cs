using System.Security;
using Microsoft.Win32;
using OsSteward.Core.Telemetry;

namespace OsSteward.Platform.Windows;

/// <summary>
/// Read-only startup inventory: registry Run/RunOnce keys and startup
/// folders. Opens registry keys for reading only; access problems are
/// reported as explicit warnings, never as an empty result.
/// </summary>
public sealed class StartupCollector
{
    private static readonly (RegistryKey Hive, string SubKey, StartupScope Scope)[] RegistryLocations =
    [
        (Registry.LocalMachine, @"SOFTWARE\Microsoft\Windows\CurrentVersion\Run", StartupScope.Machine),
        (Registry.LocalMachine, @"SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce", StartupScope.Machine),
        (Registry.LocalMachine, @"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run", StartupScope.Machine),
        (Registry.CurrentUser, @"SOFTWARE\Microsoft\Windows\CurrentVersion\Run", StartupScope.User),
        (Registry.CurrentUser, @"SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce", StartupScope.User),
    ];

    public CollectionOutcome<IReadOnlyList<StartupEntry>> Collect()
    {
        var entries = new List<StartupEntry>();
        var warnings = new List<string>();

        foreach (var (hive, subKey, scope) in RegistryLocations)
        {
            var location = $"{hive.Name}\\{subKey}";
            try
            {
                using var key = hive.OpenSubKey(subKey, writable: false);
                if (key is null)
                {
                    continue; // key does not exist on this machine — not an error
                }

                foreach (var valueName in key.GetValueNames())
                {
                    var command = key.GetValue(valueName)?.ToString() ?? string.Empty;
                    entries.Add(new StartupEntry(
                        StartupSource.Registry, scope, location, valueName, command));
                }
            }
            catch (SecurityException)
            {
                warnings.Add($"startup:PermissionDenied cannot read {location}");
            }
        }

        CollectFolder(
            Environment.GetFolderPath(Environment.SpecialFolder.Startup),
            StartupScope.User, entries, warnings);
        CollectFolder(
            Environment.GetFolderPath(Environment.SpecialFolder.CommonStartup),
            StartupScope.Machine, entries, warnings);

        return new CollectionOutcome<IReadOnlyList<StartupEntry>>(entries, warnings);
    }

    private static void CollectFolder(
        string folderPath,
        StartupScope scope,
        List<StartupEntry> entries,
        List<string> warnings)
    {
        if (string.IsNullOrEmpty(folderPath) || !Directory.Exists(folderPath))
        {
            return;
        }

        try
        {
            foreach (var file in Directory.GetFiles(folderPath))
            {
                var name = Path.GetFileName(file);
                if (name.Equals("desktop.ini", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                entries.Add(new StartupEntry(StartupSource.Folder, scope, folderPath, name, file));
            }
        }
        catch (UnauthorizedAccessException)
        {
            warnings.Add($"startup:PermissionDenied cannot list {folderPath}");
        }
    }
}
