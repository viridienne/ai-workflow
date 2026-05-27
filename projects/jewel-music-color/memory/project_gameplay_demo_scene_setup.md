---
name: project_gameplay_demo_scene_setup
description: Inspector/scene wiring required to complete gameplay demo implementation
metadata: 
  node_type: memory
  type: project
  originSessionId: b1b6894f-936c-43bb-b0a0-f852a94960d2
---

After gameplay demo scripts were written, the following Inspector/scene setup is still needed before the demo runs:

**GameplayManager (scene object):**
- Assign `BoardController` component ref
- Assign `GameplayCameraController` component ref
- Assign `GemSpriteConfig` asset ref

**Prefabs to create:**
- `GemObject.prefab` — needs `SpriteRenderer` + `Collider2D` (Collider2D required for `Physics2D.OverlapPoint` touch detection in `GemSelectionController`)
- `CellObject.prefab` — needs `SpriteRenderer` (background) + optional second `SpriteRenderer` for highlight

**GameplayView (Canvas):**
- Assign `TrayPanel` child ref in `GameplayView` Inspector

**TrayPanel:**
- Assign `TrayRow` prefab ref
- Assign `TraySlot` prefab ref

**Why:** All scripts compile clean but nothing renders or responds to input until prefabs and scene refs are wired.

**How to apply:** When user resumes gameplay demo work, start with this scene setup before testing.
