namespace OsSteward.Core.Telemetry;

public sealed record MemoryStatus(
    long TotalBytes,
    long AvailableBytes,
    double UsedPercent);

public sealed record DiskActivity(
    double PercentDiskTime,
    double AvgQueueLength);

public sealed record ProcessConsumption(
    int Pid,
    string Name,
    double? CpuPercent,
    long WorkingSetBytes);

/// <summary>
/// Point-in-time performance snapshot (os.performance.snapshot).
/// Disk is null when performance counters are unavailable — a warning
/// explains why; unavailability is never reported as "no activity".
/// </summary>
public sealed record PerformanceSnapshot(
    double CpuTotalPercent,
    int ProcessorCount,
    MemoryStatus Memory,
    DiskActivity? Disk,
    IReadOnlyList<ProcessConsumption> TopCpu,
    IReadOnlyList<ProcessConsumption> TopMemory,
    int SampleMilliseconds);
