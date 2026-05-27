---
name: gameplay-config-so
description: "GameplayConfig ScriptableObject — what it contains, where it lives, how it's injected, and what was removed from other configs"
metadata: 
  node_type: memory
  type: project
  originSessionId: 908d2863-d385-4242-881e-608c5dea2602
---

`GameplayConfig` SO created at `Assets/_Echo/Scripts/Gameplay/Data/GameplayConfig.cs`.
Asset: `Assets/_Echo/Resources/GameplayConfig.asset`.

**Fields:**
- Board: `CellSize` (1f), `CellZOffset` (0f), `GemZOffset` (0.1f), `GemScale` (0.15f)
- Gem Animation: `SelectedFloatOffset`, `FloatDuration`, `FlyDuration`, `SelectEase`, `DeselectEase`, `FlyEase`
- Camera: `BoardPadding` (0.5f)

**Injection path:**
- `GameplayManager.[SerializeField] GameplayConfig _gameplayConfig` → Inspector assign
- `PlayState.Enter()` passes to `BoardController.Initialize(gridData, boardState, config)` and `CameraController.FocusOnBounds(bounds, config.BoardPadding)`
- `BoardController.InitializeGemSprites(spriteConfig)` passes stored `_config` to `GemObject.Initialize(gem, spriteConfig, gameplayConfig)`
- `GemObject.Initialize` applies `transform.localScale = Vector3.one * config.GemScale`
- `GridEditorWindow` auto-loads via `Resources.Load<GameplayConfig>("GameplayConfig")`; passes to `GridPreviewRenderer.Render(data, gemConfig, showGems, gameplayConfig)`

**Removed from other files:**
- `BoardController._cellSize` [SerializeField] — gone, use `config.CellSize`
- `GemObject` const floats (`SelectedFloatOffset`, `FloatDuration`, `FlyDuration`) + hardcoded `Ease` values — gone
- `GemSpriteConfig.gemScale` / `GemScale` — removed; `GemScale` now lives in `GameplayConfig`

**Why:** Single tunable SO for all gameplay geometry + animation constants. Designer-tunable at runtime without recompile. [[feedback-library-preferences]]
**How to apply:** When adding new gameplay constants, put them in `GameplayConfig` not as hardcoded values in MonoBehaviours.
