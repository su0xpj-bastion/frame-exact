import Foundation

/// CMX3600-style edit decision list for one video track.
public enum EDL {
    public static func render(_ timeline: Timeline, title: String) -> String {
        let r = timeline.rate
        var lines = ["TITLE: \(title)", "FCM: \(r.dropFrame ? "DROP FRAME" : "NON-DROP FRAME")", ""]
        for (i, c) in timeline.clips.enumerated() {
            let recIn = timeline.recordStart(i)
            let tc = { (f: Int64) in Timecode.string(frame: f, rate: r) }
            let reel = c.reel.padding(toLength: 8, withPad: " ", startingAt: 0)
            lines.append(String(format: "%03d  %@ V     C        %@ %@ %@ %@", i + 1, reel,
                                tc(c.sourceIn), tc(c.sourceOut), tc(recIn), tc(recIn + c.recordLength)))
            if c.speed != Rational(1) {
                lines.append(String(format: "M2   %@ %05.1f    %@", reel, (c.speed * r.fps).double, tc(c.sourceIn)))
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
