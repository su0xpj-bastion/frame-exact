/// Audio sample positions that stay locked to video frames.
public struct AudioClock {
    public let rate: FrameRate
    public let sampleRate: Int64

    public init(rate: FrameRate, sampleRate: Int64 = 48_000) {
        self.rate = rate; self.sampleRate = sampleRate
    }

    /// Exact samples per video frame (1601.6 at 29.97, 2002 at 23.976).
    public var samplesPerFrame: Rational { Rational(sampleRate) / rate.fps }

    /// First audio sample that plays with a video frame.
    public func sample(atFrame frame: Int64) -> Int64 {
        if FaultInjection.on(.audioWholeSamplesPerFrame) { return frame * samplesPerFrame.floored }
        return (Rational(frame) * samplesPerFrame).rounded
    }

    /// Sample ranges for each clip on a timeline; adjacent ranges touch exactly.
    public func clipRanges(_ timeline: Timeline) -> [Range<Int64>] {
        (0..<timeline.clips.count).map { i in
            let s = timeline.recordStart(i)
            return sample(atFrame: s)..<sample(atFrame: s + timeline.clips[i].recordLength)
        }
    }
}
