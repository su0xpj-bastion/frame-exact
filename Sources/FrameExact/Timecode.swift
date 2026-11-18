public enum TimecodeError: Error, Equatable {
    case malformed(String)
    case droppedLabel(String)
}

/// SMPTE timecode <-> frame count. Drop-frame uses ';' before frames.
public enum Timecode {
    public static func string(frame: Int64, rate: FrameRate) -> String {
        let n = rate.nominal
        var f = frame
        if rate.dropFrame && !FaultInjection.on(.dfCountedAsNonDrop) {
            let d = rate.dropsPerMinute
            let perMin = n * 60 - d
            if FaultInjection.on(.dfDropsEveryMinute) {
                f += d * (f / perMin)
            } else {
                let per10 = n * 600 - d * 9
                let tens = f / per10, rem = f % per10
                f += d * 9 * tens + (rem > d ? d * ((rem - d) / perMin) : 0)
            }
        }
        let ff = f % n, ss = (f / n) % 60, mm = (f / (n * 60)) % 60, hh = f / (n * 3600)
        let sep = rate.dropFrame ? ";" : ":"
        return "\(pad(hh)):\(pad(mm)):\(pad(ss))\(sep)\(pad(ff))"
    }

    public static func frame(_ tc: String, rate: FrameRate) throws -> Int64 {
        let parts = tc.split(whereSeparator: { $0 == ":" || $0 == ";" }).map { Int64($0) }
        guard parts.count == 4, let hh = parts[0], let mm = parts[1], let ss = parts[2], let ff = parts[3],
              mm < 60, ss < 60, ff < rate.nominal, hh >= 0, mm >= 0, ss >= 0, ff >= 0
        else { throw TimecodeError.malformed(tc) }
        let n = rate.nominal
        var frames = (hh * 3600 + mm * 60 + ss) * n + ff
        if rate.dropFrame && !FaultInjection.on(.dfCountedAsNonDrop) {
            let d = rate.dropsPerMinute
            let everyMinute = FaultInjection.on(.dfDropsEveryMinute)
            if ss == 0 && ff < d && (everyMinute || mm % 10 != 0) { throw TimecodeError.droppedLabel(tc) }
            let minutes = hh * 60 + mm
            frames -= everyMinute ? d * minutes : d * (minutes - minutes / 10)
        }
        return frames
    }

    static func pad(_ v: Int64) -> String { v < 10 ? "0\(v)" : "\(v)" }
}
