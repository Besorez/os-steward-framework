using System.ComponentModel;
using ModelContextProtocol.Server;
using OsSteward.Core.ToolResults;
using OsSteward.Platform.Windows;

namespace OsSteward.Mcp.Tools;

[McpServerToolType]
public static class ServiceTools
{
    [McpServerTool(Name = "os_service_list", ReadOnly = true)]
    [Description("Read-only list of Windows services: name, display name, state, start mode, pid, command line (PathName), account. Descriptions and binary signatures are intentionally excluded; use os_service_inspect for one service.")]
    public static string ServiceList()
        => ToolEnvelope.Guard("os_service_list", () =>
        {
            var (records, warnings) = new ServiceCollector().CollectAll();
            return ToolEnvelope.Ok("os_service_list", new { count = records.Count, services = records }, warnings);
        });

    [McpServerTool(Name = "os_service_inspect", ReadOnly = true)]
    [Description("Read-only in-depth inspection of one Windows service by its short name: description, resolved executable path, Authenticode signature status, SHA-256 of the binary. Unreadable fields are listed explicitly in unavailableFields.")]
    public static string ServiceInspect(
        [Description("Short service name (e.g. 'Spooler'), not the display name.")] string name)
        => ToolEnvelope.Guard("os_service_inspect", () =>
        {
            var (inspection, warnings) = new ServiceCollector().Inspect(name);
            if (inspection is null)
            {
                return ToolEnvelope.Fail(
                    "os_service_inspect", ErrorKind.NoData, $"No service named '{name}'.");
            }

            return ToolEnvelope.Ok("os_service_inspect", inspection, warnings);
        });
}
