---
name: project_auto_play
description: "AutoPlayController greedy solver — architecture, entry points, known bugs fixed"
metadata: 
  node_type: memory
  type: project
  originSessionId: e7ee9ce4-e013-45cc-ac2a-940840ed9209
---

AutoPlayController added at `Assets/_Echo/Scripts/Gameplay/Core/AutoPlayController.cs`.

**Why:** Testing and demo tool — auto-solves the board without human input.

**How to apply:** Toggle via SRDebugger Gameplay → ToggleAutoPlay. Adjust speed via `AutoPlayStepDelay` float field (0.05 fast, 0.3 default, 1.0 slow debug).

## Architecture

Plain C# class, no MonoBehaviour. Owned by `PlayState`. Created in `OnGameplayViewReady`, disposed on `Exit()`.

Solver is greedy, re-evaluates each step:
1. Tray gem → empty matching board cell (highest priority)
2. Board gem (wrong cell) → empty matching board cell (direct swap)
3. Board gem (wrong cell) → tray (dump when space available)
4. null → deadlock → `Debug.LogError` with full board/tray state dump

`StepDelay` controls pause between moves. `IsAnimating` polling waits for `GemSelectionController` to finish each animation before next move.

## Entry points added to GemSelectionController

- `IsAnimating` property (was private `_isAnimating`)
- `SelectBoardGemsAtCell(Vector2Int)` — programmatic board gem selection via grid pos
- `MoveSelectedBoardGemsToAsync(Vector2Int)` — programmatic board→board move
- `PlaceSelectedTrayGemsToCellAsync(Vector2Int)` — programmatic tray→board place

## Bug fixed during implementation

`BoardState.PlaceGemOnBoard` (tray→board path) was NOT incrementing `LockedCount` after placing a matching gem. `FlyToBoardWithDelayAsync` (board→board path) did increment it manually. Result: win condition never triggered when gems came from tray.

Fix: added `if (cell.IsLocked) LockedCount++` inside `PlaceGemOnBoard` in `BoardState.cs`.

**How to apply:** `LockedCount` must always be incremented by the path that calls `PlaceGemOnBoard`. Do not increment it separately if calling that method — it's now self-contained.
