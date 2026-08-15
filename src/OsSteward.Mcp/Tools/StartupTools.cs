using System.ComponentModel;
using ModelContextProtocol.Server;
using OsSteward.Platform.Windows;

namespace OsSteward.Mcp.Tools;

[McpServerToolType]
public static class StartupTools
{
    [McpServerTool(Name = "os_startup_list", ReadOnly = true)]
    [Description("Read-only inventory of startup entries: registry Run/RunOnce keys (machine and user) and startup folders. Access problems appear as explicit warnings, never as an empty result.")]
    public static string StartupList()
        => ToolEnvelope.Guard("os_startup_list", () =>
        {
            var (entries, warnings) = new StartupCollector().Collect();
            return ToolEnvelope.Ok("os_startup_list", new { count = entries.Count, entries }, warnings);
        });
}
