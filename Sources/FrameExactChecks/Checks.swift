import FrameExact

/// A named check. `run` returns failure messages; empty means pass.
public struct Check {
    public let name: String
    public let run: () -> [String]
}

func expect(_ cond: Bool, _ msg: @autoclosure () -> String, _ out: inout [String]) {
    if !cond { out.append(msg()) }
}

func tc(_ f: Int64, _ r: FrameRate) -> String { Timecode.string(frame: f, rate: r) }

func anchors(_ rate: FrameRate, _ pairs: [(Int64, String)]) -> [String] {
    var out: [String] = []
    for (f, s) in pairs {
        expect(tc(f, rate) == s, "\(rate) frame \(f) -> \(tc(f, rate)), want \(s)", &out)
        let back = try? Timecode.frame(s, rate: rate)
        expect(back == f, "\(rate) \(s) -> \(back.map(String.init) ?? "error"), want \(f)", &out)
    }
    return out
}

/// A short cut with a retime and a gap, used by several checks.
public func sampleEdit(_ rate: FrameRate = .fps29_97DF) -> Timeline {
    try! Timeline(rate: rate, clips: [
        Clip(reel: "A001", mediaFrames: 9000, sourceIn: 1800, sourceOut: 2100),
        Clip(reel: "A002", mediaFrames: 9000, sourceIn: 300, sourceOut: 451, speed: Rational(2)),
        .gap(15),
        Clip(reel: "A001", mediaFrames: 9000, sourceIn: 107_000, sourceOut: 107_960)
            .withMedia(120_000),
        Clip(reel: "B001", mediaFrames: 2000, sourceIn: 0, sourceOut: 49, speed: Rational(1, 2)),
    ])
}

extension Clip {
    func withMedia(_ n: Int64) -> Clip { var c = self; c.mediaFrames = n; return c }
}

public let allChecks: [Check] = [
    // ---- timecode ----
    Check(name: "tc.df2997.anchors") {
        anchors(.fps29_97DF, [(0, "00:00:00;00"), (1799, "00:00:59;29"), (1800, "00:01:00;02"),
                              (17_982, "00:10:00;00"), (107_892, "01:00:00;00"), (2_589_407, "23:59:59;29")])
    },
    Check(name: "tc.df5994.anchors") {
        anchors(.fps59_94DF, [(3599, "00:00:59;59"), (3600, "00:01:00;04"), (35_964, "00:10:00;00"),
                              (215_784, "01:00:00;00")])
    },
    Check(name: "tc.ndf.anchors") {
        anchors(.fps24, [(86_400, "01:00:00:00")]) + anchors(.fps23_976, [(86_400, "01:00:00:00"), (23, "00:00:00:23")])
            + anchors(.fps25, [(90_000, "01:00:00:00")]) + anchors(.fps29_97NDF, [(108_000, "01:00:00:00")])
    },
    Check(name: "tc.roundtrip") {
        var out: [String] = []
        for r in FrameRate.all {
            let perMin = r.nominal * 60
            var frames = Array(Int64(0)..<(perMin * 11))
            for m in stride(from: Int64(11), to: 24 * 60, by: 1) {
                let base = m * perMin - r.dropsPerMinute * (m - m / 10)
                frames += (base - 3)...(base + 3)
            }
            for f in frames where f >= 0 {
                let s = tc(f, r)
                if (try? Timecode.frame(s, rate: r)) != f { out.append("\(r) \(f) -> \(s) does not round-trip"); break }
            }
            var prev = ""
            for f in Int64(0)..<(perMin * 11) {
                let s = tc(f, r)
                if s == prev { out.append("\(r) label \(s) used twice"); break }
                prev = s
            }
        }
        return out
    },
    Check(name: "tc.df.rejects-dropped-labels") {
        var out: [String] = []
        for s in ["00:01:00;00", "00:01:00;01", "00:59:00;01"] {
            expect((try? Timecode.frame(s, rate: .fps29_97DF)) == nil, "\(s) should not exist in 29.97 DF", &out)
        }
        for s in ["00:10:00;00", "00:01:00;02", "01:00:00;00"] {
            expect((try? Timecode.frame(s, rate: .fps29_97DF)) != nil, "\(s) should exist in 29.97 DF", &out)
        }
        return out
    },
    Check(name: "tc.df.matches-wall-clock") {
        var out: [String] = []
        for (r, hours) in [(FrameRate.fps29_97DF, Int64(1)), (.fps29_97DF, 24), (.fps59_94DF, 1)] {
            let f = (try? Timecode.frame("\(hours < 10 ? "0" : "")\(hours):00:00;00", rate: r)) ?? -1
            let drift = (r.seconds(frames: f) - Rational(hours * 3600)).double
            expect(abs(drift) <= 0.1, "\(r) \(hours)h label is \(drift)s off wall clock", &out)
        }
        let ndf = (try? Timecode.frame("01:00:00:00", rate: .fps29_97NDF)) ?? -1
        expect(FrameRate.fps29_97NDF.seconds(frames: ndf) == Rational(36036, 10), "29.97 NDF hour should be 3603.6s", &out)
        return out
    },
    Check(name: "tc.separator") {
        var out: [String] = []
        for r in FrameRate.all {
            let want: Character = r.dropFrame ? ";" : ":"
            expect(Array(tc(1, r))[8] == want, "\(r) uses wrong frame separator in \(tc(1, r))", &out)
        }
        return out
    },
    // ---- timeline ----
    Check(name: "tl.split.keeps-every-frame") {
        var out: [String] = []
        let tl = sampleEdit()
        for cut in stride(from: Int64(1), to: tl.duration, by: 7) {
            var t = tl
            try? t.split(atRecord: cut)
            expect(t.duration == tl.duration, "split at \(cut) changed duration \(tl.duration) -> \(t.duration)", &out)
            for f in stride(from: Int64(0), to: tl.duration, by: 1) where t.source(atRecord: f)?.frame != tl.source(atRecord: f)?.frame {
                out.append("split at \(cut): record \(f) now shows a different source frame"); break
            }
            if !out.isEmpty { break }
        }
        return out
    },
    Check(name: "tl.split.no-overlap") {
        var out: [String] = []
        var t = sampleEdit()
        try? t.split(atRecord: 100)
        let a = t.clips[0], b = t.clips[1]
        expect(a.sourceOut == b.sourceIn, "halves overlap or leave a hole: \(a.sourceIn)..<\(a.sourceOut) | \(b.sourceIn)..<\(b.sourceOut)", &out)
        expect(a.sourceLength + b.sourceLength == 300, "halves hold \(a.sourceLength + b.sourceLength) source frames, want 300", &out)
        return out
    },
    Check(name: "tl.ripple.closes-gap") {
        var out: [String] = []
        let tl = sampleEdit()
        var t = tl
        let removed = t.clips[1].recordLength
        t.rippleDelete(1)
        expect(t.duration == tl.duration - removed, "ripple delete: duration \(t.duration), want \(tl.duration - removed)", &out)
        expect(t.recordStart(1) == tl.recordStart(2) - removed, "ripple delete: next clip did not move up", &out)
        expect(!t.clips.contains { $0.isGap && $0.recordLength == removed }, "ripple delete left black", &out)
        return out
    },
    Check(name: "tl.lift.keeps-gap") {
        var out: [String] = []
        let tl = sampleEdit()
        var t = tl
        t.liftDelete(1)
        expect(t.duration == tl.duration, "lift changed duration", &out)
        expect(t.recordStart(3) == tl.recordStart(3), "lift moved later clips", &out)
        return out
    },
    Check(name: "tl.trim.stays-in-media") {
        var out: [String] = []
        var t = sampleEdit()
        for (i, o) in [(Int64(-1), Int64(10)), (8990, 9001), (50, 50), (60, 40)] {
            expect((try? t.trim(0, sourceIn: i, sourceOut: o)) == nil, "trim \(i)..<\(o) of 9000-frame media was accepted", &out)
        }
        expect((try? t.trim(0, sourceIn: 0, sourceOut: 9000)) != nil, "trim to full media was rejected", &out)
        return out
    },
    Check(name: "tl.retime.length") {
        var out: [String] = []
        let cases: [(Int64, Rational, Int64)] = [(100, Rational(2), 50), (101, Rational(2), 51), (100, Rational(1, 2), 200),
                                                 (10, Rational(3), 3), (11, Rational(3), 4), (49, Rational(1, 2), 98)]
        for (n, s, want) in cases {
            let c = Clip(reel: "X", mediaFrames: 1000, sourceIn: 0, sourceOut: n, speed: s)
            expect(c.recordLength == want, "\(n) frames at \(s)x -> \(c.recordLength), want \(want)", &out)
        }
        return out
    },
    Check(name: "tl.retime.source-mapping") {
        var out: [String] = []
        let t = try! Timeline(rate: .fps23_976, clips: [Clip(reel: "X", mediaFrames: 1000, sourceIn: 100, sourceOut: 300, speed: Rational(2))])
        for k in Int64(0)..<t.duration where t.source(atRecord: k)?.frame != 100 + 2 * k {
            out.append("2x: record \(k) shows \(t.source(atRecord: k)?.frame ?? -1), want \(100 + 2 * k)"); break
        }
        return out
    },
    Check(name: "tl.record-positions.many-cuts") {
        var out: [String] = []
        for (r, len) in [(FrameRate.fps23_976, Int64(1)), (.fps29_97DF, 7), (.fps59_94DF, 3)] {
            let clips = (0..<1000).map { Clip(reel: "C\($0)", mediaFrames: 100, sourceIn: 0, sourceOut: len) }
            let t = try! Timeline(rate: r, clips: clips)
            for i in 0..<clips.count where t.recordStart(i) != Int64(i) * len {
                out.append("\(r): clip \(i) starts at \(t.recordStart(i)), want \(Int64(i) * len)"); break
            }
        }
        return out
    },
    // ---- audio ----
    Check(name: "av.cadence") {
        var out: [String] = []
        let a = AudioClock(rate: .fps29_97DF)
        let want: [Int64] = [0, 1602, 3203, 4805, 6406, 8008]
        let got = (0...5).map { a.sample(atFrame: Int64($0)) }
        expect(got == want, "29.97 sample cadence \(got), want \(want)", &out)
        expect(AudioClock(rate: .fps23_976).sample(atFrame: 10) == 20_020, "23.976 should be exactly 2002 samples/frame", &out)
        return out
    },
    Check(name: "av.sync.one-hour") {
        var out: [String] = []
        for r in [FrameRate.fps29_97DF, .fps59_94DF, .fps23_976, .fps25] {
            let a = AudioClock(rate: r)
            let f = r.frames(seconds: Rational(3600))
            let drift = Double(a.sample(atFrame: f)) - (r.seconds(frames: f) * Rational(48_000)).double
            expect(abs(drift) <= 1, "\(r): audio is \(Int(drift)) samples (\(Int(drift / 48)) ms) off after 1h", &out)
        }
        return out
    },
    Check(name: "av.clip-ranges-touch") {
        var out: [String] = []
        let t = sampleEdit()
        let ranges = AudioClock(rate: t.rate).clipRanges(t)
        for i in 1..<ranges.count {
            expect(ranges[i - 1].upperBound == ranges[i].lowerBound, "audio gap/overlap between clip \(i) and \(i + 1)", &out)
        }
        return out
    },
    // ---- EDL ----
    Check(name: "edl.record-contiguous") {
        var out: [String] = []
        let t = sampleEdit()
        let events = EDL.render(t, title: "x").split(separator: "\n").filter { $0.first?.isNumber == true }
        let recs = events.map { $0.split(separator: " ").suffix(2).map(String.init) }
        for i in 1..<recs.count { expect(recs[i - 1][1] == recs[i][0], "event \(i) ends \(recs[i - 1][1]) but \(i + 1) starts \(recs[i][0])", &out) }
        expect(recs.last?[1] == tc(t.duration, t.rate), "last record out \(recs.last?[1] ?? "-") != duration \(tc(t.duration, t.rate))", &out)
        return out
    },
    Check(name: "edl.golden") {
        let got = EDL.render(sampleEdit(), title: "FRAME EXACT SAMPLE")
        return got == goldenEDL ? [] : ["EDL differs from golden:\n\(got)"]
    },
]

public let goldenEDL = """
TITLE: FRAME EXACT SAMPLE
FCM: DROP FRAME

001  A001     V     C        00:01:00;02 00:01:10;02 00:00:00;00 00:00:10;00
002  A002     V     C        00:00:10;00 00:00:15;01 00:00:10;00 00:00:12;16
M2   A002     059.9    00:00:10;00
003  BL       V     C        00:00:00;00 00:00:00;15 00:00:12;16 00:00:13;01
004  A001     V     C        00:59:30;08 01:00:02;08 00:00:13;01 00:00:45;01
005  B001     V     C        00:00:00;00 00:00:01;19 00:00:45;01 00:00:48;09
M2   B001     015.0    00:00:00;00

"""

/// Which checks each fault must break. Pinned: a change here is a review signal.
public let expectedFailures: [Fault: Set<String>] = [
    .dfDropsEveryMinute: ["tc.df2997.anchors", "tc.df5994.anchors", "tc.roundtrip", "tc.df.rejects-dropped-labels",
                          "tc.df.matches-wall-clock", "edl.golden"],
    .dfCountedAsNonDrop: ["tc.df2997.anchors", "tc.df5994.anchors", "tc.df.rejects-dropped-labels",
                          "tc.df.matches-wall-clock", "edl.golden"],
    .splitDuplicatesFrame: ["tl.split.keeps-every-frame", "tl.split.no-overlap"],
    .rippleLeavesGap: ["tl.ripple.closes-gap"],
    .retimeTruncates: ["tl.retime.length", "edl.golden"],
    .audioWholeSamplesPerFrame: ["av.cadence", "av.sync.one-hour"],
    .trimPastMedia: ["tl.trim.stays-in-media"],
    .floatTimeAccumulation: ["tl.record-positions.many-cuts"],
]
