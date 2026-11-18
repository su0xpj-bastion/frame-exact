public enum EditError: Error, Equatable {
    case outsideMedia(String)
    case badRange(String)
    case noClipAt(Int64)
}

public struct Clip: Equatable {
    public var reel: String
    /// Frames of source media available (handles included).
    public var mediaFrames: Int64
    public var sourceIn: Int64
    /// Exclusive.
    public var sourceOut: Int64
    /// 2 = twice as fast. Constant speed only.
    public var speed: Rational
    public var isGap: Bool { reel == "BL" }

    public init(reel: String, mediaFrames: Int64, sourceIn: Int64, sourceOut: Int64, speed: Rational = Rational(1)) {
        self.reel = reel; self.mediaFrames = mediaFrames
        self.sourceIn = sourceIn; self.sourceOut = sourceOut; self.speed = speed
    }

    public static func gap(_ frames: Int64) -> Clip { Clip(reel: "BL", mediaFrames: frames, sourceIn: 0, sourceOut: frames) }

    public var sourceLength: Int64 { sourceOut - sourceIn }

    /// Frames this clip occupies on the record side after retiming.
    public var recordLength: Int64 {
        let exact = Rational(sourceLength) / speed
        return FaultInjection.on(.retimeTruncates) ? exact.floored : exact.rounded
    }

    func validate() throws {
        guard sourceIn < sourceOut, speed > Rational(0) else { throw EditError.badRange("\(reel) \(sourceIn)..<\(sourceOut)") }
        if FaultInjection.on(.trimPastMedia) { return }
        guard sourceIn >= 0, sourceOut <= mediaFrames else { throw EditError.outsideMedia("\(reel) \(sourceIn)..<\(sourceOut) of \(mediaFrames)") }
    }
}

/// A single-track edit: clips and gaps laid end to end.
public struct Timeline {
    public let rate: FrameRate
    public private(set) var clips: [Clip] = []

    public init(rate: FrameRate, clips: [Clip] = []) throws {
        self.rate = rate
        for c in clips { try append(c) }
    }

    public var duration: Int64 { clips.reduce(0) { $0 + $1.recordLength } }

    public func recordStart(_ index: Int) -> Int64 {
        if FaultInjection.on(.floatTimeAccumulation) {
            let fps = rate.fps.double
            let secs = clips[..<index].reduce(0.0) { $0 + Double($1.recordLength) / fps }
            return Int64(secs * fps)
        }
        return clips[..<index].reduce(0) { $0 + $1.recordLength }
    }

    public mutating func append(_ clip: Clip) throws {
        try clip.validate()
        clips.append(clip)
    }

    public mutating func trim(_ index: Int, sourceIn: Int64, sourceOut: Int64) throws {
        var c = clips[index]
        c.sourceIn = sourceIn; c.sourceOut = sourceOut
        try c.validate()
        clips[index] = c
    }

    /// Index of the clip under a record frame and the offset into it.
    public func locate(_ recordFrame: Int64) -> (index: Int, offset: Int64)? {
        var start: Int64 = 0
        for (i, c) in clips.enumerated() {
            if recordFrame >= start && recordFrame < start + c.recordLength { return (i, recordFrame - start) }
            start += c.recordLength
        }
        return nil
    }

    /// Source frame shown at a record frame (nil over gaps or past the end).
    public func source(atRecord frame: Int64) -> (reel: String, frame: Int64)? {
        guard let (i, off) = locate(frame), !clips[i].isGap else { return nil }
        let c = clips[i]
        return (c.reel, c.sourceIn + (Rational(off) * c.speed).floored)
    }

    /// Blade cut at a record frame. The frame at the cut starts the second half.
    public mutating func split(atRecord frame: Int64) throws {
        guard let (i, off) = locate(frame) else { throw EditError.noClipAt(frame) }
        guard off > 0 else { return }
        let c = clips[i]
        let cut = c.sourceIn + (Rational(off) * c.speed).floored
        var a = c, b = c
        a.sourceOut = cut
        b.sourceIn = FaultInjection.on(.splitDuplicatesFrame) ? cut - 1 : cut
        clips.replaceSubrange(i...i, with: [a, b])
    }

    /// Remove a clip and close the hole.
    public mutating func rippleDelete(_ index: Int) {
        if FaultInjection.on(.rippleLeavesGap) {
            clips[index] = .gap(clips[index].recordLength)
        } else {
            clips.remove(at: index)
        }
    }

    /// Remove a clip and leave black in its place.
    public mutating func liftDelete(_ index: Int) {
        clips[index] = .gap(clips[index].recordLength)
    }
}
