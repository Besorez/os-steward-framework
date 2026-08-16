namespace OsSteward.Core.Findings;

public enum Severity
{
    Info,
    Low,
    Medium,
    High,
    Critical,
}

public enum Confidence
{
    Low,
    Medium,
    High,
}

public enum FindingStatus
{
    Detected,
    Investigating,
    EvidenceCollected,
    Explained,
    RecommendationAvailable,
    Resolved,
    InsufficientEvidence,
}

public sealed record EvidenceItem(
    string Source,
    string Description,
    string? Value);

public sealed record Hypothesis(
    string Description,
    Confidence Confidence,
    bool Rejected,
    string? RejectionReason);

/// <summary>
/// A first-class investigation artifact. A conclusion must reference
/// evidence; if evidence is insufficient, the status is
/// <see cref="FindingStatus.InsufficientEvidence"/> and the conclusion stays
/// null — certainty is never fabricated (OSF-INV-006).
/// Real findings live only in local runtime storage, never in Git.
/// Schema documented in docs/concepts/Finding-Model.md.
/// </summary>
public sealed record Finding(
    string FindingId,
    string Type,
    Severity Severity,
    Confidence Confidence,
    string Subject,
    DateTimeOffset ObservedAt,
    string Summary,
    IReadOnlyList<EvidenceItem> Evidence,
    IReadOnlyList<Hypothesis> Hypotheses,
    string? Conclusion,
    string? Recommendation,
    FindingStatus Status);
