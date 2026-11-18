/// Exact rational number, like CMTime without the timescale bookkeeping.
public struct Rational: Hashable, Comparable, CustomStringConvertible {
    public let num: Int64
    public let den: Int64

    public init(_ num: Int64, _ den: Int64 = 1) {
        precondition(den != 0, "zero denominator")
        let g = Rational.gcd(Swift.abs(num), Swift.abs(den))
        let sign: Int64 = den < 0 ? -1 : 1
        self.num = sign * num / Swift.max(g, 1)
        self.den = sign * den / Swift.max(g, 1)
    }

    static func gcd(_ a: Int64, _ b: Int64) -> Int64 { b == 0 ? a : gcd(b, a % b) }

    public static func + (a: Rational, b: Rational) -> Rational { Rational(a.num * b.den + b.num * a.den, a.den * b.den) }
    public static func - (a: Rational, b: Rational) -> Rational { Rational(a.num * b.den - b.num * a.den, a.den * b.den) }
    public static func * (a: Rational, b: Rational) -> Rational { Rational(a.num * b.num, a.den * b.den) }
    public static func / (a: Rational, b: Rational) -> Rational { Rational(a.num * b.den, a.den * b.num) }
    public static func < (a: Rational, b: Rational) -> Bool { a.num * b.den < b.num * a.den }

    /// Round half away from zero.
    public var rounded: Int64 {
        let q = num / den, r = num % den
        return 2 * Swift.abs(r) >= den ? q + (num < 0 ? -1 : 1) : q
    }

    /// Round toward negative infinity.
    public var floored: Int64 {
        let q = num / den
        return (num % den != 0 && num < 0) ? q - 1 : q
    }

    public var double: Double { Double(num) / Double(den) }
    public var description: String { den == 1 ? "\(num)" : "\(num)/\(den)" }
}
