
# Loopline Architecture

## Flow
Launch (logo draw) → Onboarding (4 pages, name capture) → Level Map
(Duolingo trail + Daily card) → Game → Result (staged reveal + confetti)
→ Leaderboard sheet → back to Map.

## Key decisions
- **Deterministic dailies**: puzzle seeded by UTC date via SplitMix64 —
  no server generation needed; everyone plays the identical board.
- **Generator**: randomized DFS Hamiltonian path w/ Warnsdorff heuristic
  (most-constrained neighbor first) — <5ms even on 8×8.
- **Offline-first**: UserDefaults JSON is source of truth; Supabase syncs
  best-effort. App is fully playable with no network.
- **Streaks**: UTC day keys, evaluated on launch (reset if a day missed),
  incremented on daily solve. Same clock as puzzle rollover.
- **Leaderboard ranking** (LinkedIn parity): time ↑, then backtracks ↑,
  then hints ↑. Enforced by a Postgres view + composite index.
- **Delight budget**: Metal path-flow shader, win shimmer, CoreHaptics
  ramp (ticks sharpen as board fills), rising haptic arpeggio on win,
  Canvas confetti with flutter physics, squish button style everywhere.

## Input handling
Drag gesture maps touch → cell; fast swipes are bridged with L-shaped
interpolation so the line never breaks. Dragging backward rewinds
(counted as backtracks). Tapping an earlier path cell rewinds to it.
