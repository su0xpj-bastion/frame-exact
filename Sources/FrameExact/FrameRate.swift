public struct FrameRate: Hashable, CustomStringConvertible {
    public let fps: Rational
    public let dropFrame: Bool
    public let name: String

    public init(_ num: Int64, _ den: Int64, dropFrame: Bool = false, name: String) {
        fps = Rational(num, den)
        precondition(!dropFrame || den == 1001, "drop-frame needs a 1001 rate")
        self.dropFrame = dropFrame
        self.name = name
    }

    public static let fps23_976 = FrameRate(24000, 1001, name: "23.976")
    public static let fps24 = FrameRate(24, 1, name: "24")
    public static let fps25 = FrameRate(25, 1, name: "25")
    public static let fps29_97NDF = FrameRate(30000, 1001, name: "29.97ndf")
    public static let fps29_97DF = FrameRate(30000, 1001, dropFrame: true, name: "29.97df")
    public static let fps30 = FrameRate(30, 1, name: "30")
    public static let fps59_94DF = FrameRate(60000, 1001, dropFrame: true, name: "59.94df")
    public static let fps60 = FrameRate(60, 1, name: "60")

    public static let all: [FrameRate] = [fps23_976, fps24, fps25, fps29_97NDF, fps29_97DF, fps30, fps59_94DF, fps60]

    public static func named(_ s: String) -> FrameRate? { all.first { $0.name == s } }

    /// Frames per timecode second (24 for 23.976, 30 for 29.97).
    public var nominal: Int64 { (fps.num + fps.den - 1) / fps.den }

    /// Labels skipped at the start of each non-10th minute.
    public var dropsPerMinute: Int64 { dropFrame ? nominal / 15 : 0 }

    public func seconds(frames: Int64) -> Rational { Rational(frames) / fps }
    public func frames(seconds: Rational) -> Int64 { (seconds * fps).rounded }

    public var description: String { name }
}
