# Test plan: frame-exact

Follows the shared [test strategy](https://github.com/su0xpj-bastion/proof-sheet/blob/main/docs/TEST_STRATEGY.md). Real bugs from building it are in [BUGS.md](BUGS.md).

**In scope:** the timing engine of a video editor: timecode at 8 frame rates, trim, split, ripple and lift, constant-speed retime, 48 kHz audio sample sync, and EDL export.

**Out of scope:** rendering and decoding (see barcode-frames); speed ramps; transitions; multicam.

## What must be true, and how it's checked

| Requirement | Priority | How it is checked |
|---|---|---|
| Drop-frame timecode labels and the wall clock | P0 | known anchors (1 h at 29.97 DF = 107,892 frames); round trip of every frame for 11 min plus every minute for 24 h |
| Cuts keep every frame on the source frame it promised | P0 | split, ripple and lift checks; 1,000-cut position check |
| Audio stays on picture for an hour | P0 | sample cadence 1602/1601…; under 1 sample of drift after 1 h |
| EDL a TV station or colourist can use | P1 | contiguous record timecodes; byte-for-byte golden EDL with M2 speed lines |
| Retime rounding | P1 | 101 frames at 2x = 51 |

## How it runs

- **Every push (CI):** all checks, then the fault matrix (each planted bug switched on alone must fail exactly its pinned checks).
- **Locally:** the same checks through the command-line tool (`scripts/build-local.sh`), on a Mac with only the Command Line Tools.

## Exit criteria

20 checks pass at every rate; the fault matrix is exact (8/8). CI is green on the default branch.

## Risks

- Test media is generated, so every answer is exact. Real-world media needs licensed sets run through the same checks.
- Simulators and CI machines are not real devices. Timing and hardware behaviour need a real-device pass before release.
