namespace OsSteward.Platform.Windows;

/// <summary>
/// Collector return contract: normalized data plus explicit warnings about
/// anything that could not be read. Collectors collect and normalize only —
/// they never classify or conclude.
/// </summary>
public sealed record CollectionOutcome<T>(T Data, IReadOnlyList<string> Warnings);
