---
name: project-tray-slot-tap
description: TraySlot Button-based tap-to-place implementation; Inspector wiring still needed
metadata: 
  node_type: memory
  type: project
  originSessionId: 53b2d0ec-2823-419c-b090-0d5e518dd468
---

Gem-to-tray tap placement implemented via Button on TraySlot. Physics2D kept for world gems; Button (event-driven, zero per-frame cost) used for UI tray slots.

**Why:** Tray is Canvas/RectTransform — Physics2D.OverlapPoint can't hit UI. Button onClick fires only on actual tap, no per-frame raycaster overhead.

**How to apply:** Don't add Physics2DRaycaster or IPointerClickHandler to gems — InputConsumed guard stays clean and centralized in PlayState.Update.

## What was done
- `TraySlot`: `[SerializeField] Button _button`; `SetOnTapped(Action<int,int>, trayIdx, slotIdx)`; `interactable=false` when occupied, `true` when clear
- `TrayRow.Initialize`: now takes `trayIndex` + `Action<int,int> onSlotTapped`, wires each slot
- `TrayPanel.Initialize`: takes `onSlotTapped`, propagates to rows
- `IGameplayView.InitializeTray` + `GameplayView`: updated signature with `Action<int,int> onSlotTapped`
- `GameplayViewData`: new `OnTraySlotTapped` field
- `GemSelectionController`: removed dead `IsOverTraySlot` stub; added `HandleTraySlotTapped(int trayIdx, int slotIdx)` — tapped slot gets first priority, remaining empty slots sorted by proximity to gems' centroid
- `PlayState`: passes `(trayIdx, slotIdx) => _selectionController?.HandleTraySlotTapped(...)` through `GameplayViewData.OnTraySlotTapped`

## Still needed (Inspector)
- `TraySlot` prefab: add `Button` component, assign to `_button` field

[[project-gameplay-demo-scene-setup]]
