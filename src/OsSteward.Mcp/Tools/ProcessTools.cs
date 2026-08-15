using System.ComponentModel;
using ModelContextProtocol.Server;
using OsSteward.Core.ToolResults;
using OsSteward.Platform.Windows;

namespace OsSteward.Mcp.Tools;

[McpServerToolType]
public static class ProcessTools
{
    [McpServerTool(Name = "os_process_list", ReadOnly = true)]
    [Description("Read-only list of running processes: pid, name, parent pid, executable path, start time, working set, total CPU seconds. Command lines are intentionally excluded; use os_process_inspect for one process.")]
    public static string ProcessList()
        => ToolEnvelope.Guard("os_process_list", () =>
        {
            var (records, warnings) = new ProcessCollector().CollectAll();
            return ToolEnvelope.Ok("os_process_list", new { count = records.Count, processes = records }, warnings);
        });

    [McpServerTool(Name = "os_process_inspect", ReadOnly = true)]
    [Description("Read-only in-depth inspection of one process by pid: command line, owner, parent chain, children, Authenticode signature status, SHA-256 of the binary. Unreadable fields are listed explicitly in unavailableFields.")]
    public static string ProcessInspect(
        [Description("Process id (pid) to inspect.")] int pid)
        => ToolEnvelope.Guard("os_process_inspect", () =>
        {
            var (inspection, warnings) = new ProcessCollector().Inspect(pid);
            if (inspection is null)
            {
                return ToolEnvelope.Fail(
                    "os_process_inspect", ErrorKind.NoData, $"No running process with pid {pid}.");
            }

            return ToolEnvelope.Ok("os_process_inspect", inspection, warnings);
        });

    [McpServerTool(Name = "os_process_tree", ReadOnly = true)]
    [Description("Read-only process ancestry tree. With pid: the subtree rooted at that process. Without pid: the full forest of processes whose parents are gone or unknown.")]
    public static string ProcessTree(
        [Description("Optional pid to root the tree at. Omit for the full tree.")] int? pid = null)
        => ToolEnvelope.Guard("os_process_tree", () =>
        {
            var (roots, warnings) = new ProcessCollector().CollectTree(pid);
            return ToolEnvelope.Ok("os_process_tree", new { roots }, warnings);
        });
}
