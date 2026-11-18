import FrameExact
import FrameExactChecks
import Foundation

func runAll() -> [String: [String]] {
    var res: [String: [String]] = [:]
    for c in allChecks { res[c.name] = c.run() }
    return res
}

let args = Array(CommandLine.arguments.dropFirst())
switch args.first ?? "check" {
case "check":
    let res = runAll()
    var failed = 0
    for c in allChecks {
        let f = res[c.name]!
        print("\(f.isEmpty ? "PASS" : "FAIL")  \(c.name)")
        for m in f.prefix(3) { print("      \(m)") }
        if !f.isEmpty { failed += 1 }
    }
    print("\n\(allChecks.count - failed)/\(allChecks.count) checks passed")
    exit(failed == 0 ? 0 : 1)
case "faults":
    var bad = 0
    FaultInjection.active = []
    let clean = runAll().filter { !$0.value.isEmpty }.keys.sorted()
    print("clean run: \(clean.isEmpty ? "all pass" : "FAILING \(clean)")")
    if !clean.isEmpty { bad += 1 }
    for fault in Fault.allCases {
        FaultInjection.active = [fault]
        let failing = Set(runAll().filter { !$0.value.isEmpty }.keys)
        let want = expectedFailures[fault] ?? []
        let ok = !failing.isEmpty && failing == want
        if !ok { bad += 1 }
        print("\(ok ? "CAUGHT" : "MISMATCH")  \(fault.rawValue): \(failing.sorted().joined(separator: ", "))")
        if !ok && failing != want { print("          expected: \(want.sorted().joined(separator: ", "))") }
    }
    FaultInjection.active = []
    print("\n\(Fault.allCases.count + 1 - bad)/\(Fault.allCases.count + 1) fault-matrix rows as pinned")
    exit(bad == 0 ? 0 : 1)
case "edl":
    print(EDL.render(sampleEdit(), title: "FRAME EXACT SAMPLE"), terminator: "")
case "tc":
    guard args.count == 3, let rate = FrameRate.named(args[2]) else {
        print("usage: fe tc <frame|HH:MM:SS:FF> <rate>   rates: \(FrameRate.all.map { $0.name }.joined(separator: " "))"); exit(2)
    }
    if let f = Int64(args[1]) { print(Timecode.string(frame: f, rate: rate)) }
    else {
        do { let f = try Timecode.frame(args[1], rate: rate); print("\(f)  (\(rate.seconds(frames: f).double)s)") }
        catch { print("error: \(error)"); exit(1) }
    }
default:
    print("usage: fe [check | faults | edl | tc <frame|timecode> <rate>]"); exit(2)
}
