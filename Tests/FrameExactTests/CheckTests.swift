import XCTest
import FrameExact
import FrameExactChecks

/// One XCTest per check, so Xcode and CI report each by name.
final class CheckTests: XCTestCase {
    override func setUp() { FaultInjection.active = [] }

    func assertPasses(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let check = allChecks.first(where: { $0.name == name }) else {
            return XCTFail("no check named \(name)", file: file, line: line)
        }
        for failure in check.run() { XCTFail(failure, file: file, line: line) }
    }

    func testEveryCheckHasATest() {
        XCTAssertEqual(allChecks.count, 20)
    }

    func test_tc_df2997_anchors() { assertPasses("tc.df2997.anchors") }
    func test_tc_df5994_anchors() { assertPasses("tc.df5994.anchors") }
    func test_tc_ndf_anchors() { assertPasses("tc.ndf.anchors") }
    func test_tc_roundtrip() { assertPasses("tc.roundtrip") }
    func test_tc_df_rejects_dropped_labels() { assertPasses("tc.df.rejects-dropped-labels") }
    func test_tc_df_matches_wall_clock() { assertPasses("tc.df.matches-wall-clock") }
    func test_tc_separator() { assertPasses("tc.separator") }
    func test_tl_split_keeps_every_frame() { assertPasses("tl.split.keeps-every-frame") }
    func test_tl_split_no_overlap() { assertPasses("tl.split.no-overlap") }
    func test_tl_ripple_closes_gap() { assertPasses("tl.ripple.closes-gap") }
    func test_tl_lift_keeps_gap() { assertPasses("tl.lift.keeps-gap") }
    func test_tl_trim_stays_in_media() { assertPasses("tl.trim.stays-in-media") }
    func test_tl_retime_length() { assertPasses("tl.retime.length") }
    func test_tl_retime_source_mapping() { assertPasses("tl.retime.source-mapping") }
    func test_tl_record_positions_many_cuts() { assertPasses("tl.record-positions.many-cuts") }
    func test_av_cadence() { assertPasses("av.cadence") }
    func test_av_sync_one_hour() { assertPasses("av.sync.one-hour") }
    func test_av_clip_ranges_touch() { assertPasses("av.clip-ranges-touch") }
    func test_edl_record_contiguous() { assertPasses("edl.record-contiguous") }
    func test_edl_golden() { assertPasses("edl.golden") }
}
