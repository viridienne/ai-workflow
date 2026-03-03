# Hexa Music - Agent Guide

Unity hexagonal puzzle game (Amanotes NGD)
- Unity 2022.3.62f2 LTS, URP, iOS/Android, C# (.NET Standard 2.1)
- Namespace: `Amanotes.Echo.HexaMusic` (default), check folder for variations
- Repo: `gitlab.amanotes.net/echo/hexa-music` (main: prod, dev: development)

## CRITICAL: Tool Usage for Spawned Agents

**C# Code - Serena MCP ONLY:**
✅ `find_symbol`, `get_symbols_overview`, `replace_symbol_body`, `insert_after/before_symbol`, `rename_symbol`, `find_referencing_symbols`, `search_for_pattern`
❌ FORBIDDEN: Read, Edit, Write, Grep, Glob (for .cs files)

**Workflow:** `get_symbols_overview` → `find_symbol` → modify → report

**UnityMCP:** `read_console`, `refresh_unity`, `manage_scene`, `manage_gameobject`, `manage_components`, `manage_prefabs`, `batch_execute`
**Other:** Bash (git, build), Read/Write/Edit (non-C#), Context7 MCP (docs)

**Quick Reference:**
| Task | Use | NOT |
|------|-----|-----|
| Find class/method | `find_symbol` | ❌ Grep/Read |
| See file structure | `get_symbols_overview` | ❌ Read entire |
| Modify method | `replace_symbol_body` | ❌ Edit |
| Add code | `insert_after_symbol` | ❌ Edit |
| Check compilation | `read_console` | ❌ Bash tail |
| Find scene objects | `find_gameobjects` | ❌ Manual |

**⚠️ CRITICAL: insert_after_symbol / insert_before_symbol Usage:**
- These tools insert AFTER/BEFORE the symbol's body (after closing brace)
- ❌ To add methods to class: `insert_after_symbol(name_path="ClassName")` → inserts OUTSIDE class
- ✅ To add methods to class: `insert_after_symbol(name_path="ClassName/LastMethodName")` → target LAST METHOD
- Always use `find_symbol(depth=1)` first to identify the correct target symbol

## Architecture

### Core Systems

**Cell System** (inherits `CellBehaviour<TData>`):
- Types: StackedCell, NumberCell, PauseCell, TurnCell, RotateCell, BladeCell, DropZoneCell, BlockerCell, EmptyCell
- Interfaces: `IHexagonContainer`, `IInteractiveCell`, `ICellVisualReferences`

**Managers** (`Assets/_Echo/Scripts/Managers/`):
- GridManager: grid lifecycle, cell tracking
- GameplayManager: state machine singleton
- LevelsManager: level loading, database
- Others: HexagonMovementManager, BoosterManager, VFXManager, LiveManager, DailyQuestManager

**State Machine:** NoneState → StartState → PlayState → WinState/LoseState/PauseState

**Data:** ScriptableObjects (LevelData, LevelDatabase, Configuration, *ConfigSO)
**Player Data:** Partial classes (Level, Currency, Booster, Life, DailyQuest, Tutorial, Profile)

### Grid & Level Management

**GameSessionData:**
- `LevelId`: "1", "Grid_12" (Quick Play)
- `GridId`: "1", "12" (actual file: `Levels/Grids/{GridId}.json`)

**Cache:** `GridDataManager._grids` + `GridConfigManager._gridCache` (both use GridId)
- Invalidate: `LevelsManager.InvalidateGridCache(gridId)` + `GridConfigManager.InvalidateGridCache(gridId)`
- Editor: `LevelGridEditor.InvalidateCache()` after bulk ops

**Level Creator:** LevelCreatorWindow (7 partials) - SetupTab, GameplayTab, GridTab, ImportTab, ToolsTab, OverviewTab, PuzzleTab
- CSV Import: `CsvToGridConverter` (x, y, direction, type, branches)
- Runtime Editor: pause/edit/save in PlayMode

### Tech Stack

**Animation:** LitMotion (preferred), DOTween Pro, VisualState2
**Async:** UniTask (replaces Coroutines)
```csharp
public async UniTask<bool> DoAsync(CancellationToken ct) {
    await UniTask.Delay(100, cancellationToken: ct);
    return true;
}
```
**Communication:** C# Events, KEventBus (Orchestra)
- **Event-Driven Pattern:** Use UniTaskCompletionSource for request/response
- Reduces tight coupling, enables optional features
- Pattern: `var req = new GetDataRequestEvent(); KEventBus.Dispatch(req); var data = await req.CompletionSource.Task;`

**Pooling:** BaseObjectPool<T> + IPoolable
**UI:** Odin Inspector, TextMeshPro, uGUI
**Performance:** ZLinq v1.5.3, Hot Reload

## Code Style

**Never Allowed:**
❌ Comments (except non-obvious), XML docs, #region/#pragma
❌ try/catch (use early returns; try-finally OK), MonoBehaviour constructors
❌ Tiny methods (<5 lines), PlayerPrefs (except local), over-engineering

**Preferences:**
✅ Fields > properties, early returns, `Init()` methods, `Array.Empty<T>()`
✅ Extension methods (`Utils/Extensions/`), one file per class

**Namespace & Using Directives:**
```csharp
namespace Amanotes.Echo.HexaMusic { } // Default
// Others: Leaderboard.UI, Analytics, Tutorial, PlayerData
```

**CRITICAL: Always use `using` directives at top, never fully qualified names in code.**
```csharp
// ❌ WRONG - Fully qualified in code
var levelId = HexaMusic.GameplayManager.Instance?.GetCurrentGameSession()?.LevelId;
HexaMusic.Analytics.AnalyticsManager.LogEvent(levelId);

// ✅ CORRECT - Using directives at top
using Amanotes.Echo.HexaMusic;
using Amanotes.Echo.HexaMusic.Analytics;

var levelId = GameplayManager.Instance?.GetCurrentGameSession()?.LevelId;
AnalyticsManager.LogEvent(levelId);
```

**Odin Inspector:** Always wrap with `#if ODIN_INSPECTOR`

**Performance:**
- ZLinq: `dict.Values.AsValueEnumerable().OfType<T>()` ✅
- Object pooling, cache components, avoid `.ToArray()` in hot paths

## File Organization

- Code: `Assets/_Echo/Scripts/`
- Artwork: `Assets/_Echo/Artworks/`
- Prefabs: `Assets/_Echo/Prefabs/`
- Data: `Assets/_Echo/Data/`

## Common Workflows

**Modify Cell:** Find in `Behaviors/`, read partials, understand interfaces, minimal changes, verify compilation
**Add Feature:** Use managers, ScriptableObjects for config, event-driven, UniTask for async, pooling
**Debug Race Conditions:** Check `_isRotating`, `_hasDropZoneAnimations` flags
**Artwork:** Scene View for transforms, X rotation = 65° validation

## Key Features (Summary)

**Daily Rewards:** Turn-based, cooldown between turns, configurable reset
- Components: DailyRewardsManager, DailyRewardsConfigSO, PlayerDailyRewards, DailyRewardContainer
- Types: FreeAdsCoin (watch ad), DailyFreeCoin (free)

**Leaderboard:** Time-based contests, bot AI, snapshot cheat detection
- Location: `Assets/_Echo/Scripts/Leaderboard/`, Leaderboard.md
- Events: LeaderboardReadyEvent, RankChangedEvent, PodiumAchievedEvent
- Competition: Rank-based bot behavior (6+: normal, 4-5: slow, 1-3: aggressive)

**PopupSequence:** Priority-based queuing, 30s timeout, event-driven
- Namespace: `Amanotes.Echo` (shared)
- Pattern: BaseShowPopupStrategy → CanShow() → ShowImplementation() → _onCloseCallback()
- Critical: Always invoke `_onCloseCallback` to prevent timeout

**Shop System:** Shared ShopContentView in ShopView (lobby) + ShopPopup (gameplay)
- Composition pattern, single source of truth
- IAP + daily rewards + starter pack

**StarterPackPopup:** IAP popup with level-based + daily triggers
- Trigger: level >= starterPackLevel, first time today, not purchased
- Priority: 95, IsOneTimeOnly: false

**FTUE Hint System:** Idle/repeated click detection, popup-aware
- Triggers: 10s idle OR 3+ clicks on unresolvable tile
- Shows text + hand pointer immediately, dismisses on tile resolution or PopupBuyMove
- Components: HintHelper, PlayState, TutorialUIManager, GameplayManager

**Zoom & Drag Tutorial:** One-time guide for large grids (>= ZOOM_GUIDE_MIN_CELLS)
- Zooms 1.3x, tracks movement, dismisses after drag (2 units) or zoom (0.15 change)
- Components: NewFeatureGuideManager, GridCameraController

**Level Variant A/B Test:** Firebase variant assignment, folder version mapping
- Config: folderVersionByVariant { "A": 2, "B": 3 }
- Variant A = folderVersion, B = folderVersion + 1

**CSV to Grid Converter:** Import grids from Excel/Sheets
- Format: x, y, direction, type, branches
- Auto-detects delimiters, configurable type mappings, branch resolution

## Editor Button Colors

Cyan (40px): Mode | Bright Green (35px): Save | Bright Blue (35px): Load
Green (30px): Create | Yellow (30px): Validate | Red (30px): Destruct
Blue (30px): Update | Purple (30px): Quick Play | Cyan (30px): Regenerate

## Notes

- 90+ Serena memories for detailed patterns
- All SerializedFields in main file (partial classes)
- PlayerDataManager + LoadSaveData (no PlayerPrefs for progression)
- Prefer SerializeField refs over singletons (except VFXManager, GameplayManager)
- Always verify compilation, code quality > speed
- Unity JSON: no parameterized constructors, read-only fields, properties without `[field: SerializeField]`

## Memory Sync Protocol

When user says "update memories":
1. Check this file for gaps
2. Extract new patterns/fixes from conversation
3. Update AGENTS.md with concise additions
