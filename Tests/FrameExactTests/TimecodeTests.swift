import XCTest
import FrameExact

final class TimecodeTests: XCTestCase {
    func testDroppedLabelThrows() {
        XCTAssertThrowsError(try Timecode.frame("00:01:00;00", rate: .fps29_97DF)) { error in
            XCTAssertEqual(error as? TimecodeError, .droppedLabel("00:01:00;00"))
        }
    }

    func testMalformedThrows() {
        for s in ["", "01:00:00", "00:60:00:00", "00:00:00:24", "aa:bb:cc:dd"] {
            XCTAssertThrowsError(try Timecode.frame(s, rate: .fps24), s)
        }
    }

    func testOneHourOfDropFrameIsAlmostOneHour() throws {
        let f = try Timecode.frame("01:00:00;00", rate: .fps29_97DF)
        XCTAssertEqual(f, 107_892)
        XCTAssertEqual(FrameRate.fps29_97DF.seconds(frames: f), Rational(8_999_991, 2500))
    }
}
