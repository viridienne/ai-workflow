---
name: project_save_resume
description: "Per-level save/resume system — SavedGamesWrapper list, PlayLevel entry point, completionPercent for gallery"
metadata: 
  node_type: memory
  type: project
  originSessionId: 6558cb88-2975-45cb-80a7-12fceeb0b2a0
---

Per-level save slots. Each `levelIndex` gets its own `SavedGameData` entry in `_savedGames` (`SavedGamesWrapper` wrapping `List<SavedGameData>`). JsonUtility-compatible.

**Storage split (2026-05-29):** `SavedGamesWrapper` moved out of `PlayerData` into its own `SavedGames.txt` file. `PlayerDataManager` holds two repos: `Repository` (`PlayerData.txt`) and `SavedGamesRepository` (`SavedGames.txt`). Frequent saves (30s + pause) only write `SavedGames.txt`; profile data untouched. Corrupt save = discard, profile survives. `SaveSync()` writes both. `ClearData()` deletes both.

**Entry point:** `GameplayManager.PlayLevel(int levelIndex)` — checks save internally, calls `ResumeLevelAsync` or `StartLevelAsync`. Callers never decide.

**Save triggers:** back button, `OnApplicationPause`, periodic timer (30s default via `GameplayConfig.AutoSaveIntervalSeconds`). All guarded by `_isExiting` flag in `PlayState`.

**Clear triggers:** `WinState.Enter()`, `LoseState.Enter()`, resume-fails-with-missing-data.

**`completionPercent`** (0–1) stored at save time = `LockedCount / ActiveCellCount`. Available for future gallery % display via `GetAllSavedGames()`.

**Resume restore:** `BoardStateFactory.BuildEmpty()` (cells + AllGems, no placement) → `BoardStateSaveHelper.RestoreBoardState()`. `RestoredTimeRemaining` on `GameSessionData` carries time-attack state back to `PlayState`.

**Visual restore bugs (fixed):** `CreateGem` always places `GemObject` at design-time `item.CellPosition`. After restore, `InitializeGemSprites` must: (1) `Hide()` any gem whose `Location.Kind == Tray`; (2) `SnapToPosition(GetCanonicalGemPos(gem.Location.BoardPosition))` for board gems — their saved position may differ from original design position. Missing either step = phantom sprites at wrong cells or visible board gems for tray-slot gems.

**Why:** Single `savedGame` field replaced with list so any level can be saved independently, not just the last-played level.

**How to apply:**
- Always call `Manager.PlayLevel(levelIndex)` from lobby, not `StartLevel`/`ResumeLevel` directly
- `GetAllSavedGames()` returns all slots — use for gallery progress display
- Inspector: `_buttonBack` on GameplayView must be `Button` type (not GameObject)
- `SavedGamesRepository` is separate `FileDataRepository<SavedGamesWrapper>` — fail-safe loads empty on error
- Truth doc: `docs/truths/save-resume.md`

See [[project_time_attack]] for `RestoredTimeRemaining` usage in PlayState.
