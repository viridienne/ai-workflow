---
name: project_gem_placement_animation
description: "Gem placement animation system — board↔tray fly animation patterns, wave stagger refactor, bugs fixed, key decisions"
metadata: 
  node_type: memory
  type: project
  originSessionId: 63220875-881d-4fc6-9d21-35a6d414a3e8
---

## Gem placement animation (board ↔ tray)

### Current pattern: wave stagger (2026-05-28)
All 3 flows refactored from fully-sequential to **staggered-start + `UniTask.WhenAll`**:
- Gems start `i * WaveStaggerDelay` apart (default 0.08s)
- All share same duration — overlap in flight
- Effect: wave cascade, total time ≈ duration + (n-1)*stagger instead of n*duration

`WaveStaggerDelay` field added to `GameplayConfig.cs`, tunable in Inspector.

### 3 flows and their helpers
| Flow | Method | Helper |
|------|--------|--------|
| Board→tray | `PlaceBoardGemsInTrayAsync` | `FlyToTrayWithDelayAsync` |
| Board→board (+ board→tray) | `ExecuteMovesAsync` | `FlyToBoardWithDelayAsync` / `FlyToTrayWithDelayAsync` |
| Tray→board | `PlaceUIGemsSequentialAsync` | `AnimateTrayToBoardWithDelayAsync` |

All helpers: optional `await UniTask.Delay(delay)` then delegate to view/object fly method.

### State mutation timing (critical)
- **Board→tray (`PlaceBoardGemsInTrayAsync`)**: `cell.RemoveGem()`, `tray.TryAdd()`, `gemObj.Hide()` all synchronous before task fires. Post-WhenAll: `SortByColor()`, `RefreshTray()`.
- **Board→board (`ExecuteMovesAsync`)**: source removal synchronous before task fires. Board placement (`PlaceGem`, `gem.Location`, `SnapToPosition`) done inside `FlyToBoardWithDelayAsync` after animation — safe because `_isAnimating=true` blocks input until WhenAll.
- **Tray→board (`PlaceUIGemsSequentialAsync`)**: animation + `CreateGemObjectAt` + `PlaceGemOnBoard` inside helper (world gem spawns the moment canvas lands). `RemoveGemFromTray` deferred to post-WhenAll in **descending slot order** — prevents list compaction shifting unprocessed indices.

### GemSelectionController constructor (updated)
Now takes `GameplayConfig config` as 6th parameter. `PlayState` passes `Manager.GameplayConfig`.

### Canvas vs world space
- `FlyDuration` = world-space gem fly (`GemObject.FlyToAsync`, ~1-3 units travel)
- `TrayFlyDuration` = canvas fly (`GemCanvas.FlyAsync`, 100-900px travel) — needs longer duration
- `WaveStaggerDelay` = stagger between gem starts in wave
- All tunable in `GameplayConfig.asset` Inspector

### Key bugs fixed (historical)
1. `async void` → `async UniTask` — exceptions swallowed, `_isAnimating` stuck
2. `Slots[slotIdx] = gem` → `TrayState.PlaceAt` — `OccupiedCount` never updated
3. Too many gems vs tray slots — partial fill, deselect rest
4. Canvas snap — `FlyDuration=0.35f` too short for canvas pixel distances; added `TrayFlyDuration=0.6f`
5. Tray→board world gem not appearing until all animations done — moved `CreateGemObjectAt`+`PlaceGemOnBoard` inside helper, runs immediately on canvas animation complete

### Float-up animation
- `AnimateTrayGemFloatUp`: LitMotion, anchoredPosition origin→origin+(0,20f), 0.2s OutQuad
- Original position cached in `Dictionary<(trayIdx, slotIdx), Vector2>` in `GameplayView`
- `ResetTrayGemPosition` uses cached position — prevents drift

### Files
- `GemSelectionController.cs` — `PlaceBoardGemsInTrayAsync`, `ExecuteMovesAsync`, `PlaceUIGemsSequentialAsync`, 3 delay helpers
- `GameplayView.cs` — `FlyGemToTraySlotAsync`, `AnimateTrayGemToBoardAsync`, `AnimateTrayGemFloatUp`
- `GameplayConfig.cs` — `TrayFlyDuration`, `WaveStaggerDelay` fields
- `BoardController.cs` — `CreateGemObjectAt`
