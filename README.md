# L'Envers

**La radiographie de ton récit.** — A native macOS reverse-outliner / "story X-ray".

L'Envers takes anything you've written — a screenplay, treatment, scene list, essay,
chapter — and reveals its hidden **skeleton**: not what each unit *says*, but what it
*does*. It exposes the structural problems your eye glosses over — three scenes doing
the same job, a flat stretch with no turn, a reveal that lands too early.

## What it does

1. **Intake.** Paste text, or open a `.txt` / `.md` / `.fountain` file. The source
   sits in a clean monospace reading pane.
2. **Radiographier.** Sends the document to `claude-opus-4-8` via a forced `tool_use`
   call that returns strict structured JSON: the text segmented into ordered **units**,
   each tagged with the *job it does* (a verb phrase), a type, and a tension value —
   plus a list of structural **holes**.
3. **The spine.** The units render as a vertical spine of cards, colour-coded by type,
   each with a tension bar — the X-ray.
4. **Tension EKG.** A sparkline of tension across all units, with **flatline** stretches
   (dramatically dead zones) shaded in oxblood.
5. **Repeats.** Units that do the same job cluster and colour in ochre.
6. **Holes panel.** The structural diagnoses; click one to light up the implicated units.
7. **Source linking.** Click any spine card → the source pane scrolls to and highlights
   the matching passage.
8. **Persistence.** Save radiographs locally (SwiftData). A sidebar lists them to reopen.
   Saving is always **explicit** — L'Envers never overwrites your work.
9. **Réglages.** Paste your Anthropic API key (stored in the Keychain, never in plain text).

## Design

An architect's drafting table: ink on bone-white paper, a blueprint-blue spine running
down the page, oxblood red reserved for the things that hurt — flatlines and holes. Serif
(New York) for labels and headings, monospace for source text. Calm, precise, drafting-table.

## Build

Requires [XcodeGen](https://github.com/yonyz/XcodeGen) (`brew install xcodegen`).

```sh
./gen.sh                              # regenerate LEnvers.xcodeproj (gitignored)
./run-mac.sh                          # build (Debug), sign, launch
# or
xcodebuild -scheme LEnvers -destination 'platform=macOS' build
xcodebuild -scheme LEnvers -destination 'platform=macOS' test
```

The icon is generated: `swift scripts/make-icon.swift`.

## Notes

- Sandboxed, with `network.client` (the app calls Anthropic directly with your key) and
  user-selected-file read.
- Needs an Anthropic API key pasted in **Réglages** on first run. Model: `claude-opus-4-8`.
- FR-first (Québécois), English fallback. macOS 14+.

© 2026 Jacques Gautreau
