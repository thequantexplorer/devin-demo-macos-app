---
name: design
description: Visual design for the Pomodoro menu bar panel. Read before building or changing the UI.
---

## Direction: a native Mac utility

Small, quiet and precise, like a built-in macOS menu bar extra.

- Panel: about 280 pt wide, with a material background (`.regularMaterial` or `NSVisualEffectView`), 16 pt padding.
- Phase name at the top, small and uppercase with letter spacing, in the phase color: Focus `#FF5A36`, Short break `#2BB673`, Long break `#3B82F6`.
- The time in the middle of a circular progress ring (about 160 pt, 8 pt line, rounded line caps, the ring in the phase color over a faint track). The time uses `.monospacedDigit()` at 40 pt, medium weight. The ring animates smoothly each second.
- Start / Pause as a large capsule button in the phase color (`.borderedProminent`, `.controlSize(.large)`), full width.
- Reset and Skip side by side under it as quieter bordered buttons with SF Symbols (`arrow.counterclockwise`, `forward.end`).
- "Completed: N" in secondary text. Quit at the bottom under a divider, small and plain.
- Keep every accessibility identifier from docs/spec.md exactly as written.
- Works in light and dark mode.

States to screenshot: the panel at Focus 25:00, while running, on a short break, in dark mode.

## Rules for every screen

- One clear visual direction, used everywhere. No default framework or browser look (no unstyled inputs, no default blue links, no stock Material purple).
- Sans-serif type only. Use a real type scale with a few sizes, not many. Large, confident headings; quiet secondary text.
- Mostly neutral colors plus one accent. Use color for meaning (selected, done, error), not decoration. No purple or pink.
- Even spacing on an 8 px grid. Generous margins. Line up edges.
- Every interactive element has hover (or pressed), focus and disabled states.
- Design the empty state, the error state and the full state, not just one.
- Small, quick motion (150 to 250 ms) when things appear, change or finish.
- Support light and dark appearance if the platform has it, and check both.

## Check before you open the pull request

1. Take screenshots of every screen and state in the list above.
2. Look at each one at full size. Fix anything that is misaligned, cramped, clipped, low contrast or looks unfinished.
3. Put the final screenshots in the pull request description.
