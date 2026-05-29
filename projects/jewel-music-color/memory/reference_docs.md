---
name: reference_docs
description: "Location and purpose of docs/ folder — truths, specs, bugs, PRD"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 6558cb88-2975-45cb-80a7-12fceeb0b2a0
---

Project docs at `/Users/anh.th/jewel-music-color/docs/`.

## Structure

| Folder | Purpose |
|--------|---------|
| `docs/truths/` | Authoritative ground-truth docs for implemented systems. Update when system changes. |
| `docs/specs/` | Feature proposals / design explorations. Not necessarily implemented. |
| `docs/specs/decisions/` | ADRs — why X was chosen over Y. Records outcome of decisions, not exploration. |
| `docs/specs/ref/` | Screenshots and reference images for specs. |
| `docs/bugs/` | Bug post-mortems — symptom, root cause, fix, files changed. |
| `docs/prd/` | Product requirement docs from GD/PO. Read-only input — do not write here. |
| `docs/handoff/` | (empty) Handoff notes. |

## Current truths docs

| File | System |
|------|--------|
| `truths/auto-play-system.md` | AutoPlayController, greedy solver, SRDebugger integration |
| `truths/behavior-matrix.md` | Full gem selection state machine — all tap scenarios → outcomes |
| `truths/time-attack-mode.md` | LevelData.TimeLimit, countdown in PlayState, GameplayTimerView |
| `truths/save-resume.md` | Per-level save, SavedGameData, BoardStateSaveHelper, PlayLevel entry point |

## How to apply

- Before implementing any system in the above list: read the relevant truth doc first.
- After implementing or changing a system covered by a truth doc: update that doc.
- When creating a new system worth documenting: create a new file in `truths/`.
- Bug post-mortems go in `bugs/` — format: symptom → root cause → fix → files.
