using System.ComponentModel;
using ModelContextProtocol.Server;
using OsSteward.Platform.Windows;

namespace OsSteward.Mcp.Tools;

[McpServerToolType]
public static class PerformanceTools
{
    [McpServerTool(Name = "os_performance_snapshot", ReadOnly = true)]
    [Description("Read-only point-in-time performance snapshot: total CPU percent, memory usage, disk activity (when counters are readable), and top CPU / memory consuming processes. Uses a short sampling interval.")]
    public static string PerformanceSnapshot(
        [Description("Sampling interval in milliseconds (100-5000, default 500).")] int sampleMilliseconds = 500)
        => ToolEnvelope.Guard("os_performance_snapshot", () =>
        {
            var clamped = Math.Clamp(sampleMilliseconds, 100, 5000);
            var (snapshot, warnings) = new PerformanceCollector().Collect(clamped);
            return ToolEnvelope.Ok("os_performance_snapshot", snapshot, warnings);
        });
}
