---
name: tray-refactor
description: Tray system refactored from Array to List with stateless UI pattern; stable sort preserves insertion order within color groups
metadata: 
  node_type: memory
  type: project
  originSessionId: 57e486cb-bd51-45c8-862c-39a2f241276a
---

Tray system refactored 2026-05-28 to fix cross-color selection bug caused by UI/data desync.

**Why:** Array-based approach with manual compaction updated data layer but not UI layer, causing slot indices to mismatch. Tapping one gem color selected different colors.

**Architecture change:**
- Data: `TrayState` uses `List<GemInstance>` (auto-compacting on `RemoveAt()`)
- UI: `TraySlot` stateless with `Refresh(GemInstance, GemSpriteConfig)` method (no `_currentGem` field)
- Sync: Explicit `RefreshTray(trayIdx)` call after data mutations
- Sort: Stable sort groups by first-appearance order, not enum value

**Key methods:**
- `TrayState.GetGemAt(int)` — safe accessor, returns null if out of range
- `TrayState.TryAdd(GemInstance)` — FIFO append to end
- `TrayState.RemoveAt(int)` — List auto-compacts, updates gem locations
- `TrayState.SortByColor()` — groups matching colors together; group order = first appearance in list (not enum index)
- `TraySlot.AnimateFloatUp()` / `ResetPosition()` — slot owns its own gem image animation (originalPos always zero)
- `TrayPanel.AnimateSlotFloatUp(int,int)` / `ResetSlotPosition(int,int)` — delegates to slot
- `TrayPanel.RefreshTray(int)` — syncs UI from data
- `GameplayView.RefreshTray(int)` — delegates to TrayPanel
- `GameplayView` no longer owns `_originalGemPositions` cache or animation logic — all tray-slot animation in TraySlot
- `IGameplayView.AnimateTraySlotToSlot` removed (never called)

**How to apply:**
- Always call `RefreshTray()` after tray data mutations
- Never store gem state in UI components
- Use `GetGemAt()` instead of direct array access
- List auto-compacts on `RemoveAt()` — adjust indices if removing multiple gems in loop
- Selection reads from data layer only (never UI state)

**Related:** [[gem-placement-animation]] for tray↔board fly animations
