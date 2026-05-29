---
name: project_camera_pan_zoom
description: "Camera pan/zoom system in GameplayCameraController — pinch zoom, smooth LitMotion zoom, pan, board-clamped, config-driven"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2ddfbfd0-00c2-4ebf-827c-92f00dbf3a7c
---

Camera pan/zoom in `GameplayCameraController` (`Assets/_Echo/Scripts/Gameplay/Core/GameplayCameraController.cs`).

**Why:** Players zoom into board details and pan when zoomed in. Zoom-out capped at board-fit view.

**Architecture:**
- `[SerializeField] GameplayConfig _config` — direct SO ref, wired in Inspector
- All config reads via private properties (`ZoomSensitivity`, `ZoomEase`, etc.) — single null-check per property, read at use site, no cached copies
- `FocusOnBounds(Bounds)` — self-sources `BoardPadding` from config
- `EnableInput()` — just sets `_inputEnabled` and `_minOrthoSize`; no param passing needed
- `PlayState` calls `FocusOnBounds` + `EnableInput()` with no args

**Smooth zoom:** LitMotion tween on `_targetOrthoSize`; cancels/restarts on each scroll tick. `ZoomDuration=0` → instant.

**Editor helpers** (`#if UNITY_EDITOR` only):
- Left mouse drag pans: `Mouse X/Y * worldPerPixel * EditorPanMult`
- Scroll wheel: `ZoomSensitivity * EditorScrollMult`

**Config fields** in `GameplayConfig` SO:
- `BoardPadding` — padding around board for FocusOnBounds
- `MinZoomFactor` — fraction of board-fit ortho (zoom-in limit)
- `ZoomSensitivity`, `ZoomDuration`, `ZoomEase`
- `CameraMoveDuration`, `CameraMoveEase` — for `MoveToAsync`
- `PanExtraTop/Bottom/Left/Right` — extra clamp range per side (use to expose areas hidden by UI overlays)
- `EditorScrollMultiplier` — scroll speed multiplier in Editor
- `EditorPanMultiplier` — pan speed multiplier in Editor (worldPerPixel-scaled; 1.0 = natural, tune up)

**Pan clamping:** `panRange = boardExtents + padding - cameraHalfSize + PanExtra[side]`. Zero range = locked (board fits fully). `PanExtra` fields unlock extra travel beyond board edge.

**`InputConsumed` flag:** set true when camera consumed input; `PlayState.Update()` skips gem selection if true. Resets each frame at start of `UpdateInput()`.

**How to apply:** `UpdateInput()` must be called before selection logic in `PlayState.Update()`. Wire `_config` field in Inspector on GameplayCameraController component.
