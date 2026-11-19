# Bugs and findings while building frame-exact

Severity: S1 (data loss or privacy), S2 (wrong output), S3 (broken interaction), S4 (cosmetic).

### FE-1 · Summing seconds as `Double` loses a frame after 26 cuts at 23.976
**S2 / P0** · the reason time is kept as exact rationals

- **What happened.** With clip positions accumulated as floating-point seconds and truncated to frames, clip 27 started at frame 26.
- **Isolation.** The error appears only after enough cuts, and only at fractional rates (23.976, 29.97). Integer frames and rational time removed it.
- **Guard.** The record-position check across 1,000 cuts. The fault `floatTimeAccumulation` re-plants it.

### FE-2 · My own reference values were wrong at first
**Test bug**

- **What happened.** My first 59.94 drop-frame anchors were wrong, and so was my first hand-written golden EDL. Both were found and corrected before the first commit.
- **Fix.** The anchors were re-derived from the drop-frame rule. The golden EDL is now the engine's own output, checked by hand once and then pinned.
- **Lesson.** A reference value is code too. It needs a second, independent way of being computed.

### FE-3 · What each planted bug looks like when caught
The fault table in the README reads like a set of bug reports, for example:
- `frame 17982 -> 00:09:59;12, want 00:10:00;00` (drop-frame counted as non-drop)
- `29.97df: audio is -64735 samples (-1348 ms) off after 1h` (1601 whole samples per frame)
