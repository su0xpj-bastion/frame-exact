# frame-exact

<!-- plain-english:begin -->
[![ci](https://github.com/su0xpj-bastion/frame-exact/actions/workflows/ci.yml/badge.svg)](https://github.com/su0xpj-bastion/frame-exact/actions/workflows/ci.yml)

The timing engine behind a video editor, plus the tests that keep it exact.
North American TV runs at 29.97 frames per second, not 30. To keep the on-screen clock matching
real time, editors use "drop-frame" timecode, which skips some frame *numbers* every minute.
Get the rule slightly wrong and a one-hour programme ends 3.6 seconds out. Captions drift and
ads start late.

Editors spot a one-frame slip at a cut, or lip-sync that drifts after an
hour. A "does it play" test catches neither. These tests do.

- A small Swift edit engine: timecode at 8 frame rates; trim, split, ripple and lift; speed changes; 48 kHz audio sample sync; and EDL export (the edit list a TV station or colourist receives).
- 20 checks pinned to hard facts. For example, one hour at 29.97 drop-frame is exactly 107,892 frames.
- 8 deliberately planted bugs. The suite proves each one is caught by exactly the checks meant to catch it (the "fault matrix").

Swift, XCTest, rational time (no floating-point drift), golden EDL in
CMX3600 format with M2 speed lines, CI on GitHub Actions. See the badge above for current status.

---

## Technical detail
<!-- plain-english:end -->

A tiny edit engine for a video editor, written in **Swift**, and the **XCTest** suite that keeps it frame-accurate: SMPTE timecode (drop-frame and non-drop), trim, blade split, ripple and lift delete, constant-speed retime, audio sample sync at 48 kHz, and CMX3600 EDL export.

Editors notice a one-frame error at a cut, or a lip-sync drift that only shows up after an hour. A plain "does it render" test catches neither. Every check here has a planted bug it must catch, and the fault matrix proves it.

```bash
swift test                  # XCTest: one test per check + the fault matrix (needs Xcode)
swift run fe                # run the 20 checks, print PASS / FAIL
swift run fe faults         # switch on each planted bug, confirm exactly its checks fail
swift run fe edl            # print the sample edit as an EDL
swift run fe tc "01:00:00;00" 29.97df     # 107892  (3599.9964s)
swift run fe tc "00:01:00;00" 29.97df     # error: droppedLabel — that label doesn't exist
scripts/build-local.sh      # same CLI with plain swiftc, for machines with only Command Line Tools
```

## What is checked

| Area | Checks |
|---|---|
| Timecode | known frame ↔ label anchors at 29.97 DF, 59.94 DF and the non-drop rates; every frame of the first 11 minutes, plus every minute boundary for 24 h, round-trips at all 8 rates with no label used twice; labels that drop-frame skips (`00:01:00;00`) are rejected; a DF hour lands within 0.1 s of the wall clock (NDF 29.97 is 3.6 s long, shown on purpose); `;` vs `:` separator |
| Timeline | a split at any frame keeps every record frame showing the same source frame; split halves don't overlap; ripple closes the gap and lift leaves it; trims stay inside the media; retimed length rounds (101 frames at 2x = 51); a 2x clip shows every second source frame; record positions stay exact across 1,000 cuts |
| Audio | 29.97 sample cadence `1602, 1601, 1602, 1601, 1602` (8,008 per 5 frames); under 1 sample of drift after an hour at 29.97 DF, 59.94 DF, 23.976 and 25; per-clip sample ranges touch exactly |
| EDL | record timecodes are contiguous and end at the timeline duration; byte-for-byte golden EDL with M2 speed lines |

## Fault matrix

`swift run fe faults` turns each bug on by itself and checks that the set of failing checks is exactly the pinned one (`expectedFailures`). It also runs in CI as an XCTest. What each bug looks like when it is caught:

| Planted bug | Caught by | What the check reports |
|---|---|---|
| `dfCountedAsNonDrop` | 5 timecode + golden EDL | `frame 17982 -> 00:09:59;12, want 00:10:00;00` |
| `dfDropsEveryMinute` (also drops at minutes 0, 10, 20…) | 6 incl. round-trip | anchors and wall clock both off |
| `splitDuplicatesFrame` | 2 split checks | `halves hold 301 source frames, want 300` |
| `rippleLeavesGap` | ripple | black left in the cut |
| `retimeTruncates` | retime + golden EDL | `101 frames at 2x -> 50, want 51` |
| `audioWholeSamplesPerFrame` (1601 per frame) | cadence + 1-hour sync | `29.97df: audio is -64735 samples (-1348 ms) off after 1h` |
| `trimPastMedia` | trim | out point past the end of the media accepted |
| `floatTimeAccumulation` (sum seconds as `Double`, truncate) | 1,000-cut positions | `23.976: clip 27 starts at 26, want 27` |

The float bug is the interesting one: `Double` seconds look fine for 26 cuts at 23.976, then one frame goes missing. Positions are therefore kept as integer frames, and time as an exact `Rational` (like `CMTime`).

## Layout

```
Sources/FrameExact/        Rational, FrameRate, Timecode, Timeline, AudioClock, EDL, Faults
Sources/FrameExactChecks/  the 20 checks, the sample edit, the golden EDL, the pinned fault matrix
Sources/fe/                CLI
Tests/FrameExactTests/     XCTest: one test per check, fault matrix, timecode edge cases
```

## Where this stops

- One video track, constant speed. No speed ramps, transitions, multicam, or nested sequences.
- No decoding or rendering: this tests the edit math, not pixels. AVFoundation export with per-frame hash comparison is the next step.
- Checked locally with `scripts/build-local.sh` (the Mac it was written on has no Xcode). `swift test` runs on GitHub Actions macOS runners.

<!-- set:begin -->
---

Six small projects, one idea: test media apps with data that carries its own answer, and prove every test catches the bug it was written for.

- **[frame-exact](https://github.com/su0xpj-bastion/frame-exact)**: timecode and edit maths, to the frame
- [barcode-frames](https://github.com/su0xpj-bastion/barcode-frames): real video edits checked frame by frame
- [proof-sheet](https://github.com/su0xpj-bastion/proof-sheet): a photo/video app with all 45 workflows tested
- [enact-probe](https://github.com/su0xpj-bastion/enact-probe): live AI video, measured the way the viewer feels it
- [vision-gate](https://github.com/su0xpj-bastion/vision-gate): report cards for on-device AI photo features
- [timeline-ml](https://github.com/su0xpj-bastion/timeline-ml): beat detection and transcript search
<!-- set:end -->
