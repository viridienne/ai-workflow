---
name: project_camera_pan_zoom
description: "Camera pan/zoom system added to GameplayCameraController — pinch zoom, single-touch pan, board-clamped scroll"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2ddfbfd0-00c2-4ebf-827c-92f00dbf3a7c
---

Camera pan/zoom implemented in `GameplayCameraController` (2026-05-27).

**Why:** Players need to zoom in on board details and pan when zoomed in. Zoom-out capped at board-fit view so board never leaves screen.

**What changed:**
- `FocusOnBounds` bug fixed: width padding now `(bounds.size.x / 2f + padding) / aspect` (was `bounds.size.x / (2f * aspect) + padding`)
- `UpdateInput()` method handles: pinch-to-zoom (mobile), scroll wheel + right-drag (Editor), single-touch pan
- `EnableInput(minZoomFactor, zoomSensitivity)` / `DisableInput()` called from `PlayState.Enter/Exit`
- `InputConsumed` flag lets `PlayState.Update()` skip gem selection when camera consumed the touch
- Selection moved to `TouchPhase.Ended` / `GetMouseButtonUp` so drag doesn't accidentally select gems

**Config fields** added to `GameplayConfig` SO:
- `MinZoomFactor = 0.3f` — fraction of board-fit ortho size (how far user can zoom in)
- `ZoomSensitivity = 0.05f`

**Pan clamping:** pan range = `boardExtents + padding - cameraHalfSize`; shrinks to zero at max zoom-out so camera stays centered when board fits in view.

**How to apply:** If touching camera input again, remember `UpdateInput()` must be called before selection logic in `PlayState.Update()`. `InputConsumed` resets to false each frame at start of `UpdateInput()`.
