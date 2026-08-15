using System.ComponentModel;
using System.Diagnostics;
using System.Runtime.InteropServices;
using OsSteward.Core.Telemetry;

namespace OsSteward.Platform.Windows;

/// <summary>
/// Point-in-time performance snapshot: two-point CPU sampling across all
/// processes, physical memory via GlobalMemoryStatusEx, and disk activity
/// via performance counters where available.
/// </summary>
public sealed class PerformanceCollector
{
    private const int TopConsumerCount = 5;

    public CollectionOutcome<PerformanceSnapshot> Collect(int sampleMilliseconds = 500)
    {
        var warnings = new List<string>();
        var processorCount = Environment.ProcessorCount;

        var diskCounters = TryCreateDiskCounters(warnings);

        var firstSample = SampleProcesses(out var inaccessibleFirst);

        Thread.Sleep(sampleMilliseconds);

        var secondSample = SampleProcesses(out var inaccessibleSecond);
        var inaccessible = Math.Max(inaccessibleFirst, inaccessibleSecond);
        if (inaccessible > 0)
        {
            warnings.Add(
                $"processCpu:PermissionDenied CPU time unreadable for {inaccessible} process(es); totals exclude them.");
        }

        var consumptions = new List<ProcessConsumption>();
        double totalCpuDeltaMs = 0;
        foreach (var (pid, current) in secondSample)
        {
            double? cpuPercent = null;
            if (current.CpuTime is TimeSpan currentCpu
                && firstSample.TryGetValue(pid, out var previous)
                && previous.CpuTime is TimeSpan previousCpu)
            {
                var deltaMs = (currentCpu - previousCpu).TotalMilliseconds;
                if (deltaMs >= 0)
                {
                    totalCpuDeltaMs += deltaMs;
                    cpuPercent = Math.Round(deltaMs / (sampleMilliseconds * (double)processorCount) * 100, 1);
                }
            }

            consumptions.Add(new ProcessConsumption(pid, current.Name, cpuPercent, current.WorkingSetBytes));
        }

        var cpuTotalPercent = Math.Clamp(
            Math.Round(totalCpuDeltaMs / (sampleMilliseconds * (double)processorCount) * 100, 1), 0, 100);

        var memory = ReadMemoryStatus(warnings);
        var disk = ReadDiskActivity(diskCounters, warnings);

        var snapshot = new PerformanceSnapshot(
            cpuTotalPercent,
            processorCount,
            memory,
            disk,
            consumptions
                .Where(c => c.CpuPercent is > 0)
                .OrderByDescending(c => c.CpuPercent)
                .Take(TopConsumerCount)
                .ToList(),
            consumptions
                .OrderByDescending(c => c.WorkingSetBytes)
                .Take(TopConsumerCount)
                .ToList(),
            sampleMilliseconds);

        return new CollectionOutcome<PerformanceSnapshot>(snapshot, warnings);
    }

    private static Dictionary<int, (string Name, TimeSpan? CpuTime, long WorkingSetBytes)> SampleProcesses(
        out int inaccessibleCount)
    {
        var sample = new Dictionary<int, (string, TimeSpan?, long)>();
        inaccessibleCount = 0;
        foreach (var process in Process.GetProcesses())
        {
            using (process)
            {
                TimeSpan? cpuTime = null;
                long workingSet = 0;
                try
                {
                    workingSet = process.WorkingSet64;
                    cpuTime = process.TotalProcessorTime;
                }
                catch (Exception ex) when (ex is Win32Exception or InvalidOperationException)
                {
                    inaccessibleCount++;
                }

                sample[process.Id] = (process.ProcessName, cpuTime, workingSet);
            }
        }

        return sample;
    }

    private static (PerformanceCounter Time, PerformanceCounter Queue)? TryCreateDiskCounters(
        List<string> warnings)
    {
        try
        {
            var time = new PerformanceCounter("PhysicalDisk", "% Disk Time", "_Total", readOnly: true);
            var queue = new PerformanceCounter("PhysicalDisk", "Avg. Disk Queue Length", "_Total", readOnly: true);

            // First read primes the counter; the real value comes after the sample interval.
            time.NextValue();
            queue.NextValue();
            return (time, queue);
        }
        catch (Exception ex) when (ex is InvalidOperationException or UnauthorizedAccessException or Win32Exception)
        {
            warnings.Add(
                $"disk:NotAvailable performance counters unreadable ({ex.GetType().Name}); " +
                "disk activity is unknown, not zero.");
            return null;
        }
    }

    private static DiskActivity? ReadDiskActivity(
        (PerformanceCounter Time, PerformanceCounter Queue)? counters,
        List<string> warnings)
    {
        if (counters is not { } c)
        {
            return null;
        }

        try
        {
            using (c.Time)
            using (c.Queue)
            {
                return new DiskActivity(
                    Math.Round(Math.Min(c.Time.NextValue(), 100), 1),
                    Math.Round(c.Queue.NextValue(), 2));
            }
        }
        catch (InvalidOperationException ex)
        {
            warnings.Add($"disk:CollectorFailed {ex.GetType().Name} while reading counters.");
            return null;
        }
    }

    private static MemoryStatus ReadMemoryStatus(List<string> warnings)
    {
        var status = new MemoryStatusEx { Length = (uint)Marshal.SizeOf<MemoryStatusEx>() };
        if (!GlobalMemoryStatusEx(ref status))
        {
            warnings.Add("memory:CollectorFailed GlobalMemoryStatusEx returned false.");
            return new MemoryStatus(0, 0, 0);
        }

        var total = (long)status.TotalPhys;
        var available = (long)status.AvailPhys;
        var usedPercent = total == 0 ? 0 : Math.Round((total - available) / (double)total * 100, 1);
        return new MemoryStatus(total, available, usedPercent);
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GlobalMemoryStatusEx(ref MemoryStatusEx buffer);

    [StructLayout(LayoutKind.Sequential)]
    private struct MemoryStatusEx
    {
        public uint Length;
        public uint MemoryLoad;
        public ulong TotalPhys;
        public ulong AvailPhys;
        public ulong TotalPageFile;
        public ulong AvailPageFile;
        public ulong TotalVirtual;
        public ulong AvailVirtual;
        public ulong AvailExtendedVirtual;
    }
}
