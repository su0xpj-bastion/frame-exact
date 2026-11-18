import XCTest
import FrameExact
import FrameExactChecks

/// Each injected bug must break exactly the checks pinned in `expectedFailures`.
final class FaultMatrixTests: XCTestCase {
    override func tearDown() { FaultInjection.active = [] }

    func failing(with faults: Set<Fault>) -> Set<String> {
        FaultInjection.active = faults
        return Set(allChecks.filter { !$0.run().isEmpty }.map { $0.name })
    }

    func testCleanRunPasses() {
        XCTAssertEqual(failing(with: []), [])
    }

    func testEveryFaultIsCaughtByItsPinnedChecks() {
        for fault in Fault.allCases {
            let got = failing(with: [fault])
            XCTAssertFalse(got.isEmpty, "\(fault) slipped through every check")
            XCTAssertEqual(got, expectedFailures[fault] ?? [], "\(fault)")
        }
    }
}
