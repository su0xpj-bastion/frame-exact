import Foundation

/// Bugs that can be switched on to prove the checks catch them.
/// Each one is a real class of editing-engine defect.
public enum Fault: String, CaseIterable {
    /// Drop-frame timecode drops labels every minute, including every 10th.
    case dfDropsEveryMinute
    /// 29.97 / 59.94 drop-frame rates are counted as non-drop.
    case dfCountedAsNonDrop
    /// Split gives the frame at the cut point to both halves.
    case splitDuplicatesFrame
    /// Ripple delete leaves a gap instead of closing it.
    case rippleLeavesGap
    /// Retimed clip length is truncated instead of rounded.
    case retimeTruncates
    /// Audio uses a whole number of samples per video frame (1601 at 29.97).
    case audioWholeSamplesPerFrame
    /// Trim accepts in/out points outside the source media.
    case trimPastMedia
    /// Record positions are summed as Double seconds and truncated back to frames.
    case floatTimeAccumulation
}

public enum FaultInjection {
    /// Active faults. Starts from the FE_FAULTS env var (comma-separated names).
    public static var active: Set<Fault> = {
        let raw = ProcessInfo.processInfo.environment["FE_FAULTS"] ?? ""
        return Set(raw.split(separator: ",").compactMap { Fault(rawValue: String($0)) })
    }()

    static func on(_ fault: Fault) -> Bool { active.contains(fault) }
}
