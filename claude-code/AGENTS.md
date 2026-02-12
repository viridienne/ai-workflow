# AGENTS.md

Guidance for Agent Coding Tool working with Hexa Music codebase.

## Project Info

**Hexa Music** - Unity hexagonal puzzle game (Amanotes NGD)
- Unity 2022.3.62f2 LTS, URP, iOS/Android
- C# (.NET Standard 2.1), Single namespace: `Amanotes.Echo.HexaMusic`

## CRITICAL: Tool Usage Protocol for Spawned Agents

**If you are a spawned agent (via Task tool), READ THIS SECTION FIRST!**

### Mandatory Tool Selection

**For C# Code Operations - USE SERENA MCP EXCLUSIVELY:**
- ✅ `find_symbol` - Locate classes/methods/fields by name path
- ✅ `get_symbols_overview` - Understand file structure and hierarchy
- ✅ `replace_symbol_body` - Modify method/class implementations
- ✅ `insert_after_symbol` / `insert_before_symbol` - Add new code
- ✅ `rename_symbol` - Rename across entire codebase
- ✅ `find_referencing_symbols` - Understand dependencies and usage
- ✅ `search_for_pattern` - Search codebase with regex patterns
- ✅ `think_about_collected_information` - After research phase
- ✅ `think_about_task_adherence` - Before claiming completion

**FORBIDDEN for C# files (.cs):**
- ❌ Read tool (except for initial context if unavoidable)
- ❌ Edit tool
- ❌ Write tool
- ❌ Grep tool (use Serena `search_for_pattern` instead)
- ❌ Glob tool (use Serena `find_file` or `search_for_pattern` instead)

**Allowed Standard Tools:**
- Bash (git, npm, build commands)
- Read/Write/Edit for non-C# files (.md, .json, .txt, .csv)
- Context7 MCP for library documentation
- UnityMCP for Unity Editor operations (compilation, scene, assets, prefabs)

### Standard Agent Workflow

1. **Understand Context**: Use `get_symbols_overview(file_path)` to see file structure
2. **Locate Target**: Use `find_symbol(name_path, relative_path, include_body=true)`
3. **Study Pattern**: Read related symbols to understand existing patterns
4. **Modify Code**: Use `replace_symbol_body` or `insert_after_symbol`
5. **Think**: Call `think_about_task_adherence` before completion
6. **Report**: Return concise results to orchestrator

### Serena Name Path Examples

```csharp
// File: GridManager.cs
public class GridManager {
    public void OnCellInteracted() { }
    private bool _isRotating;
}

// Serena queries:
find_symbol("GridManager", "GridManager.cs", depth=1)  // Get class + methods
find_symbol("OnCellInteracted", "GridManager.cs", include_body=true)  // Get method body
find_symbol("_isRotating", "GridManager.cs")  // Get field
```

### Why Serena Over Standard Tools

| Scenario | Why Serena Wins |
|----------|----------------|
| Modify method | Precise symbol replacement, preserves formatting |
| Add new code | `insert_after_symbol` maintains proper indentation |
| Understand file | `get_symbols_overview` shows structure without full read |
| Find usages | `find_referencing_symbols` shows call sites with context |
| Rename safely | `rename_symbol` updates all references automatically |
| Search code | `search_for_pattern` respects symbol boundaries |

### Violation Consequences

Using forbidden tools for C# operations = **Task Failure**
- Orchestrator will reject your changes
- You'll be respawned with stricter instructions
- Wasted API calls and time

### Quick Reference Card

| I need to... | Use this Serena tool | NOT this |
|--------------|---------------------|----------|
| Find a class/method | `find_symbol` | ❌ Grep/Read |
| See file structure | `get_symbols_overview` | ❌ Read entire file |
| Modify a method | `replace_symbol_body` | ❌ Edit |
| Add new method | `insert_after_symbol` | ❌ Edit |
| Search for pattern | `search_for_pattern` | ❌ Grep |
| Find who calls X | `find_referencing_symbols` | ❌ Grep |
| Rename variable | `rename_symbol` | ❌ Multi-Edit |
| Check compilation | UnityMCP `read_console` | ❌ Bash `tail Editor.log` |
| Trigger recompile | UnityMCP `refresh_unity` | ❌ Bash `osascript` |
| Find scene objects | UnityMCP `find_gameobjects` | ❌ Manual inspection |
| Modify prefab | UnityMCP `manage_prefabs` | ❌ Direct file edit |
| Add component | UnityMCP `manage_components` | ❌ Manual |

**Remember**: Follow the Tool Preferences section below for all code operations!

---

## Dev Commands

```bash
# Git (main: production, dev: development)
git status && git diff
git add <files> && git commit -m "msg"
git push
```

**Prefer UnityMCP over Bash for Unity operations:**
- Compilation check: `read_console(types=["error"])` instead of `tail Editor.log | grep`
- Force recompile: `refresh_unity(compile="request")` instead of `osascript`
- Scene info: `manage_scene(action="get_hierarchy")` instead of manual inspection

## Architecture

### Core Systems

**Cell System** (Polymorphic, inherits `CellBehaviour<TData>`):
- StackedCell, NumberCell, PauseCell, TurnCell, RotateCell (5 partials)
- BladeCell, DropZoneCell, BlockerCell, EmptyCell
- Interfaces: `IHexagonContainer`, `IInteractiveCell`, `ICellVisualReferences`

**Managers** (`Assets/_Echo/Scripts/Managers/`):
- GridManager - Grid lifecycle, cell tracking
- GameplayManager - State machine (singleton), manages scene-scoped objects (light/camera/grid persist across levels, only destroyed with manager)
- LevelsManager - Level loading, database
- HexagonMovementManager - Movement animations
- BoosterManager, VFXManager, LiveManager, DailyQuestManager

**State Machine**: NoneState → StartState → PlayState → WinState/LoseState/PauseState

**Data**: ScriptableObjects (LevelData, LevelDatabase, Configuration, *ConfigSO)

**Player Data**: Partial classes (Level, Currency, Booster, Life, DailyQuest, Tutorial, Profile)

### Game Session & Grid ID Management

**GameSessionData** stores authoritative grid ID:
```csharp
public class GameSessionData {
    public string LevelId;      // e.g., "1", "Grid_12" (Quick Play)
    public string GridId;       // e.g., "1", "12" (actual grid file name)
    public int MoveRemaining;
    // ... other fields
}
```

**Grid Loading Flow**:
1. Regular level: `LevelData.GridId` → Set in `GameSessionData.GridId`
2. Quick Play: Dummy `LevelData` with `GridId = gridId` → Set in `GameSessionData.GridId`
3. Grid files: `Assets/_Echo/Resources/Levels/Grids/{GridId}.json`

**Cache Management**:
- `GridDataManager._grids` - Local grid data cache
- `GridConfigManager._gridCache` - Remote grid data cache
- Both use `GridId` as key (not LevelId)
- Invalidate both after saving: `LevelsManager.InvalidateGridCache(gridId)` + `GridConfigManager.InvalidateGridCache(gridId)`

**Grid Editor Cache**:
- `LevelGridEditor.InvalidateCache()` - Clears position caches and marks dirty flag
- Call after bulk cell operations (add/remove/regenerate) to refresh gizmos
- Clears: `_cachedValidPositions`, `_cachedOccupiedPositions`, `_cachedCellsByPosition`

### Level Creator (Editor Tools)

**LevelCreatorWindow** (7 partial files):
- SetupTab - Grid creation, Quick Play
- GameplayTab - Runtime controls, runtime editor
- GridTab - Grid settings, artwork, boundary DropZone regeneration (simplified to focus button only)
- ImportTab - JSON import, CSV import
- ToolsTab - Creator mode
- OverviewTab - Bulk operations
- PuzzleTab, Validation

**ImportTab** (`LevelCreatorWindow.ImportTab`):
- JSON Import - Paste JSON from web, validate, save to file
- CSV Import - Import grids from Excel/Sheets exports

**CSV to Grid Converter** (`ImportTab`):
- Converts CSV/TSV files to Unity grid scenes
- Configurable type mappings via `CsvToGridConfigSO`
- Auto-detects delimiters (tab/comma), flexible column ordering
- Branch dependency resolution for RotateCells (Euclidean distance + angle calculation)
- Preview before import with cell type breakdown
- Auto-assigns next available GridId
- Location: `Assets/_Echo/Scripts/Editor/LevelCreator/CsvToGridConverter.cs`

**CSV Format:**
```csv
x,y,direction,type,branches
0,0,up,normal,
1,1,none,rotate,"up,up-R,dn-R"
```

**Required Columns:** x, y, direction, type  
**Optional Columns:** branches (for rotation cells, comma-separated directions)  
**Direction Values:** none, up, up-R, dn-R, down, dn-L, up-L  
**Type Mapping:** Configured via CsvToGridConfigSO (default: normal→Stacked, empty→Empty, rotate→Rotation)

**Branch Specification:**
- For rotation cells, specify branches directly in `branches` column
- Format: comma/semicolon/pipe-separated directions: `"up,up-R,dn-R"`
- Branches are parsed and added to RotateCell's Branches list
- Leave empty for rotation cells with no branches

**Usage:**
1. Create CsvToGridConfig asset (Assets > Create > Echo > CSV to Grid Config)
2. Configure type mappings in Inspector
3. Export grid from Excel/Sheets as CSV
4. In LevelCreator Import tab:
   - Assign CSV Config
   - Browse CSV file
   - Enter Grid ID (required)
   - Set Max Steps and Difficulty (optional)
   - Preview (optional) → Create Grid
5. Grid appears in scene and automatically enters Creator Mode
6. Edit grid, add artwork, adjust settings
7. Save to JSON via Setup tab

**Files:**
- `Assets/_Echo/Scripts/Data/Editor/CsvToGridConfigSO.cs` - Config ScriptableObject
- `Assets/_Echo/Scripts/Editor/LevelCreator/CsvToGridConverter.cs` - Parser utility
- `Assets/_Echo/Scripts/Editor/LevelCreatorWindow.ImportTab.cs` - UI integration
- `Assets/_Echo/Resources/Levels/CSV_IMPORT_README.md` - User guide
- `Assets/_Echo/Resources/Levels/sample_grid.csv` - Example

**See:** `csv_to_grid_converter_feature` memory for full details

**Runtime Editor** (`RuntimeLevelEditor`):
- Connects to running game via GameplayManager + GridManager
- Gets `GridId` from `GameSession.GridId` (not constructed)
- Pause/resume gameplay, edit cells in scene view
- Tracks changes via `RuntimeCellChangeTracker`
- Save → Merges changes → Writes JSON → Invalidates caches → Auto-resumes

**Boundary DropZone Regeneration** (`LevelCreatorWindow.GridTab`):
- Regenerates DropZones around existing grid cells
- Toggle to remove existing DropZones before regenerating
- Uses hexagonal neighbor calculation (6 directions)
- Invalidates grid editor cache to refresh gizmos
- Pattern: Scan cells → Check neighbors → Create DropZones at empty positions

**Quick Play Flow** (during Play mode):
1. Set `LevelCreator_QuickPlayWaiting = true`
2. `GameplayManager.CleanupCurrentLevel()` + `PlayGrid(gridId)`
3. Clear flag after completion (prevents stuck popup)

### Hexagonal Grid

**Coordinates**: Offset (Vector2Int) ↔ World (Vector3)
**Extensions**: `OffsetToWorldPosition()`, `WorldPositionToOffset()`, `GetNeighbors()`, `IsNeighbor()`

### Communication

**C# Events**: Direct component-to-component
**KEventBus**: Cross-system (Orchestra framework)

### Animation

- **LitMotion** (preferred, modern)
- DOTween Pro (legacy)
- VisualState2 (UI transitions)

### Async

**UniTask** (replaces Coroutines):
```csharp
public async UniTask<bool> DoAsync(CancellationToken ct) {
    await UniTask.Delay(100, cancellationToken: ct);
    return true;
}
CancellationToken _token = this.GetCancellationTokenOnDestroy();
```

### Pooling

**BaseObjectPool<T>** with **IPoolable** interface (OnPoolCreate/Get/Release/Destroy)

## Code Style

### Never Allowed
❌ Comments (except non-obvious), XML docs, #region/#pragma
❌ try/catch (use early returns; try-finally OK for critical cleanup)
❌ MonoBehaviour constructors, tiny methods (<5 lines), PlayerPrefs (except local)
❌ Over-engineering, premature abstractions

### Preferences
✅ Fields > properties, early returns, `Init()` methods, `Array.Empty<T>()`
✅ Extension methods (`Utils/Extensions/`), one file per class
✅ Partial classes OK (SerializedFields in main file)

### Namespace & Using
**CRITICAL: Always check the correct namespace before implementing!**
- Main: `Amanotes.Echo.HexaMusic` (default)
- Leaderboard: `Amanotes.Echo.Leaderboard.UI`
- Analytics: `Amanotes.Echo.HexaMusic.Analytics`
- Tutorial: `Amanotes.Echo.Tutorial`
- PlayerData: `Amanotes.Echo.PlayerData`
- Use same namespace as existing files in the same folder

```csharp
namespace Amanotes.Echo.HexaMusic { }  // Default namespace
using UnityEngine;  // Always use directives, never fully qualified names
```

### Odin Inspector
**Always wrap Odin attributes with `#if ODIN_INSPECTOR`**:
```csharp
#if ODIN_INSPECTOR
using Sirenix.OdinInspector;
#endif

#if ODIN_INSPECTOR
[Title("Section")]
[Button]
#endif
public void Method() { }
```

### Performance
**Always use ZLinq** for Dictionary.Values/HashSet:
```csharp
dict.Values.AsValueEnumerable().OfType<T>()  // ✅
dict.Values.OfType<T>()  // ❌
```
- Object pooling, cache components, avoid `.ToArray()` in hot paths
- Pre-allocate collections, avoid LINQ in Update()

## Key Tech Stack

**Animation**: LitMotion (preferred), DOTween Pro, VisualState2
**Async**: UniTask
**UI**: Odin Inspector, TextMeshPro, uGUI
**Architecture**: Orchestra (KEventBus), Reflex (DI, sparingly)
**Performance**: ZLinq v1.5.3, Hot Reload
**Debug**: SRDebugger

## Tool Preferences

**Serena MCP** (MANDATORY for C# code - prefer over ALL standard tools):
- `find_symbol`, `find_referencing_symbols`, `get_symbols_overview`
- `replace_symbol_body`, `insert_after/before_symbol`, `rename_symbol`
- `search_for_pattern`, `read_file`, `create_text_file`
- `think_about_collected_information`, `think_about_task_adherence`

**⚠️ SPAWNED AGENTS**: This applies to YOU with ZERO exceptions!
- When spawned via Task tool, you MUST use Serena for ALL C# operations
- Standard Edit/Read/Write tools are FORBIDDEN for .cs files
- See "CRITICAL: Tool Usage Protocol" section at top of this file
- Violation = Task failure and respawn

**UnityMCP** (for Unity Editor operations - reduces token usage vs Bash):
- `read_console` - Check compilation errors/warnings (prefer over `tail Editor.log`)
- `refresh_unity` - Trigger recompile + wait for ready state
- `find_gameobjects` / `manage_gameobject` - Scene object CRUD
- `manage_components` - Add/remove/set component properties on GameObjects
- `manage_scene` - Scene hierarchy, load/save, screenshot
- `manage_asset` - Asset search, create, modify, delete, move
- `manage_prefabs` - Prefab info, hierarchy, create, modify contents
- `manage_material` - Material creation and property editing
- `run_tests` / `get_test_job` - Unity test runner (async polling)
- `batch_execute` - Batch multiple UnityMCP operations (10-100x token savings)
- `manage_editor` - Play/pause/stop, add tags/layers

**When to use UnityMCP vs Serena:**
| Operation | Use UnityMCP | Use Serena |
|-----------|-------------|------------|
| Check compilation | `read_console` | - |
| Edit C# code | - | `replace_symbol_body` |
| Create new C# file | `create_script` or Serena | `create_text_file` |
| Find scene objects | `find_gameobjects` | - |
| Search C# patterns | - | `search_for_pattern` |
| Modify prefab contents | `manage_prefabs` | - |
| Add component to GO | `manage_components` | - |

**Context7 MCP**: Auto-use for library docs, code generation (Unity, LitMotion, UniTask, etc.)

## Common Workflows

**Modify Cell**: Find in `Behaviors/`, read partials, understand interfaces, minimal changes, verify compilation

**Add Feature**: Check existing, use managers, ScriptableObjects for config, event-driven, UniTask for async, pooling

**Debug Race Conditions**: Check `_isRotating`, `_hasDropZoneAnimations` flags in GridManager

**Artwork Management**: Use Scene View for transform editing, GridJsonExporter reads live transforms, X rotation validation at 65°

## File Organization

- Code: `Assets/_Echo/Scripts/`
- Artwork: `Assets/_Echo/Artworks/`
- Prefabs: `Assets/_Echo/Prefabs/`
- Data: `Assets/_Echo/Data/`

## Editor Button Colors

Cyan (40px): Mode transitions | Bright Green (35px): Save
Bright Blue (35px): Load | Green (30px): Create
Yellow (30px): Validate | Red (30px): Destruct
Blue (30px): Update | Purple (30px): Quick Play
Cyan (30px): Regenerate/Refresh operations

## Unity JSON Gotchas

No parameterized constructors, read-only fields, properties without `[field: SerializeField]`

## Artwork System

**GridTab Artwork Management**: Simplified to focus button only - users edit transforms in Scene View
**Save Validation**: GridJsonExporter checks X rotation = 65° with auto-fix dialog
**Transform Export**: Reads current GameObject transform values, not cached LevelArtworkData values

## Notes

- 90+ Serena memories for detailed patterns
- All SerializedFields in main file (partial classes)
- PlayerDataManager + LoadSaveData (no PlayerPrefs for progression)
- Prefer SerializeField refs over singletons (except VFXManager, GameplayManager)
- Always verify compilation, code quality > speed

## Daily Rewards System

**Architecture**: Turn-based reward system with cooldown between turns, configurable daily reset time.

**Components**:
- `DailyRewardsManager` - Inherits BaseConfigManager, singleton, remote config support
- `DailyRewardsConfigSO` - ScriptableObject config with JSON import/export
- `PlayerDailyRewards` - Player data class (part of PlayerDataManager)
- `DailyRewardContainer` - UI component for reward containers (renamed from DailyRewardButton)
- `ShopView` - Integrates daily rewards with timer loop

**Data Flow**:
- Config: `DailyRewardsConfig.json` → `DailyRewardsConfigSO` → `DailyRewardsManager`
- Player Data: `PlayerDataManager.DailyRewards` → Unix timestamps for persistence
- UI: `ShopView.StartTimerLoop()` → Updates timers every 1s via CancellationToken
- Remote Config: Follows same pattern as IAPManager/BoosterManager with local/remote paths

**Turn-Based Logic**:
- User claims views one at a time (not all at once)
- After consuming `ViewsPerTurn` views, cooldown triggers
- Cooldown duration: `TurnCooldownHours` (e.g., 6 hours)
- Daily reset: Configurable hour (0-23, default 0 for midnight) using `DailyResetHour` in config

**Config Fields** (DailyRewardItem):
- `Type` - FreeAdsCoin or DailyFreeCoin
- `CoinAmount` - Coins awarded per view
- `MaxViewsPerDay` - Total views available per day
- `ViewsPerTurn` - Views before cooldown triggers
- `TurnCooldownHours` - Hours to wait after completing a turn
- `DailyResetHour` - Hour (0-23) when daily reset occurs

**Key Methods**:
- `CanClaimAdsReward()` / `CanClaimDailyCoinReward()` - Check availability (handles cooldown and daily reset)
- `GetAdsRewardCooldown()` / `GetDailyCoinRewardCooldown()` - Get remaining time (returns shorter of cooldown or time to reset)
- `ClaimAdsRewardView()` / `ClaimDailyCoinRewardView()` - Consume view, grant coins
- `CheckAndResetAdsReward()` / `CheckAndResetDailyCoinReward()` - Daily reset logic with configurable hour

**Reward Types**:
- `FreeAdsCoin` - Watch ad, get coins (e.g., 4 views/day, 2 per turn, 6h cooldown)
- `DailyFreeCoin` - Free coins (e.g., 3 views/day, 1 per turn, 6h cooldown)

**UI Pattern**:
- `DailyRewardContainer` - Uses VisualState2 for state transitions ("Available"/"Cooldown")
- Button text shows "GET"/"CLAIM" when available, countdown timer when on cooldown
- Coin amount displayed from config
- `ShopView.ShowRewardAnimation()` - Static helper for reward popup
- Timer updates via async loop with CancellationTokenSource cleanup

**Timer Display Logic**:
- When daily limit reached: Shows time until daily reset
- When in cooldown: Shows shorter of (cooldown remaining, time until reset)
- Prevents showing cooldown that extends past daily reset

**Loading Pipeline**:
- DailyRewardsManager initialized in parallel with LiveManager, TreasureHuntManager, BoosterManager, AdsManager, IAPManager
- Position 5 in managers array (before GridConfigManager)

**SRCheat Tools**:
- Reset All Daily Rewards - Clear all progress
- Trigger Daily Reset - Force daily reset
- Skip Cooldown - Clear turn cooldown instantly
- Info tab - Real-time views remaining and cooldown seconds

**Critical Bug Fixes**:
- Fixed `CanClaimAdsReward()` logic: Now checks cooldown before allowing claims (was checking reset counter which gets set to 0 after turn completion)
- Fixed `GetAdsRewardCooldown()`: Removed early return that prevented cooldown display after turn completion
- Simplified logic: Check views remaining → Check cooldown → Return availability

**Meta Pattern**: Use `Meta.PlayerDataManager`, `Meta.LoadSaveData.SavePlayerData()`, `Meta.PlayerDataManager.Currency.Earn()`

## Zoom & Drag Tutorial System

**Architecture**: One-time tutorial guide for large grids, teaches camera zoom/drag controls.

**Components**:
- `NewFeatureGuideManager` - Manages all tutorial guides including zoom/drag
- `GridCameraController` - Tracks camera movement, fires gesture events
- `PlayerDataManager.Tutorial.HasSeenZoomDragGuide` - Persistence flag
- `Configuration.ZOOM_GUIDE_MIN_CELLS` - Remote config threshold (default: 20)

**Trigger Logic**:
- Checks grid cell count >= `ZOOM_GUIDE_MIN_CELLS` (configurable via RemoteConfig)
- Only shows once per player (persisted to disk)
- Triggers in StartState after difficulty warning and feature popups
- Skipped if FTUE tutorial is active

**Camera Behavior**:
- Zooms in 1.3x before showing guide (creates room for dragging)
- Tracks cumulative drag distance and zoom changes
- Dismisses after meaningful interaction:
  - Drag threshold: 2 world units
  - Zoom threshold: 0.15 (15% change)

**UI Pattern**:
- Capsule bubble message (no pointer, no highlight)
- Message: "Zoom & Drag to easily tap\nthe remaining tiles!"
- Non-blocking (SetBlocksRaycasts false)
- Stays visible until threshold reached (no timeout)
- Hides back/settings buttons and booster UI during guide
- Restores all UI elements on completion

**Event Flow**:
1. `StartState.Enter()` → Camera intro + grid show
2. Difficulty warning popup (if hard/super hard)
3. New feature popup (if booster/mechanic unlock)
4. `TryShowZoomDragGuide()` → Check conditions
5. `ZoomInForTutorial()` → Zoom camera 1.3x (divide orthographicSize)
6. Dispatch `GameplayViewButtonVisibilityEvent` + `BoosterUIVisibilityChangedEvent` to hide UI
7. Show capsule message
8. `StartTrackingCameraMovement()` → Begin tracking
9. User drags/zooms → `OnCameraGesturePerformed` fires on `TouchPhase.Moved`
10. Check `HasSignificantCameraMovement()` → Dismiss if threshold met
11. Restore UI visibility via event dispatch
12. Mark complete + save player data

**Key Methods**:
- `GridCameraController.IsGridLargerThanViewport()` - Cell count check
- `GridCameraController.ZoomInForTutorial()` - Pre-guide zoom animation
- `GridCameraController.StartTrackingCameraMovement()` - Reset tracking counters
- `GridCameraController.HasSignificantCameraMovement()` - Threshold detection
- `NewFeatureGuideManager.TryShowZoomDragGuide()` - Entry point with guards
- `NewFeatureGuideManager.ShowZoomDragGuide()` - Async display logic
- `NewFeatureGuideManager.CleanupZoomDragGuide()` - Dismissal + persistence

**Remote Config**:
- Key: `ZOOM_GUIDE_MIN_CELLS`
- Default: 20 cells
- Fetched in `RemoteConfig.Initialize()` alongside other config values

**Critical Details**:
- Orthographic camera: Smaller size = zoomed in, larger size = zoomed out (divide to zoom in)
- Movement tracking fires on `TouchPhase.Moved` / mouse drag, not on touch begin
- Guide uses `_isZoomDragGuideActive` flag to distinguish from other guides
- State change cleanup handled in `OnGameStateChanged()`
- CancellationToken cleanup in `OnDestroy()`
- UI hiding/restoration uses same event pattern as other guides (GameplayViewButtonVisibilityEvent, BoosterUIVisibilityChangedEvent)
- Pre-guide zoom ensures users have room to drag (prevents showing drag tutorial when fully zoomed out)

**Integration Points**:
- StartState: Triggers after all popups complete
- GridCameraController: Gesture events + movement tracking
- TutorialUIManager: Message bubble display
- PlayerDataManager: Persistence via HasSeenZoomDragGuide

## Level Variant A/B Test System

**Architecture**: Turn-based reward system with cooldown between turns, configurable daily reset time.

**Components**:
- `FirebaseRemoteConfigHelper` - Fetches and persists variant assignment via `LEVEL_VARIANT` parameter
- `Configuration.LEVEL_VARIANT` - Stores assigned variant (default: "A")
- `LevelsManager.ApplyConfig()` - Selects folder version based on variant from `folderVersionByVariant` dictionary
- `LevelsConfigGenerator` - Automatically generates variant config with A/B mapping

**Variant Assignment**:
- Firebase fetches `LEVEL_VARIANT` on first launch, stores in PlayerPrefs forever
- Variant A uses current `folderVersion` (e.g., 2 → LevelsV2/)
- Variant B uses `folderVersion + 1` (e.g., 3 → LevelsV3/)
- Falls back to `folderVersion` field if variant not found (backward compatible)

**Config Structure**:
```json
{
  "folderVersion": 2,
  "folderVersionByVariant": { "A": 2, "B": 3 },
  "csvFileNames": ["levels", "levels_secret", "levels_daily"]
}
```

**Usage**:
- Level Creator → Remote Tab → "Generate Levels Config" (auto-generates variant mapping)
- Create LevelsV3 folder with variant B CSV files (same filenames, different GridId mappings)
- Set Firebase `LEVEL_VARIANT` parameter with A/B test (50/50 split)
- Environment overrides: `dev_LEVEL_VARIANT = "B"` for testing

**Backward Compatible**:
- If Firebase parameter missing → Everyone gets "A"
- If `folderVersionByVariant` missing → Falls back to `folderVersion`
- Set both variants to same version to disable A/B test

**See:** `level_variant_ab_test_system` memory for full details

## Leaderboard System

**Location:** `Assets/_Echo/Scripts/Leaderboard/`
**Docs:** `Assets/_Echo/Scripts/Leaderboard/Leaderboard.md` (438 lines - full API reference)
**Memory:** `leaderboard_feature_overview` - Comprehensive architecture and patterns

**Status:** Production-ready, integrated in ProjectScope.prefab, UI complete, needs LobbyView button

**Key Components:**
- **LeaderboardManager** - Singleton with public API for score submission, rewards, rankings
- **CompetitionBehaviorTree** - Dynamic bot AI that adapts to player rank (rank 6+: normal, 4-5: podium slows, 1-3: aggressive + close competitor)
- **Time-based contests** (Daily/Weekly/Monthly) with snapshot-based cheat detection
- **4-tab UI**: TimeBased (contest + podium), AllPlayers (global/local), Friends, Teams

**Core Flow:**
```csharp
// Submit scores (WinState integration)
await LeaderboardManager.Instance.SubmitScoreAsync(levelId, score, multiplier);

// Claim rewards
ContestEndResult result = await LeaderboardManager.Instance.ClaimContestReward();

// Show leaderboard
KView.ShowView(nameof(LeaderboardView));
```

**Events:** LeaderboardReadyEvent, RankChangedEvent, PodiumAchievedEvent, LeaderboardContestEndedEvent, TimeCheatChangedEvent

**Time Cheat Protection:**
- Snapshots save after each score (max 50, auto-pruned)
- App resume: Server time validation, restore to last valid snapshot if >5min difference
- GameMasterTime integration for `Time.realtimeSinceStartup` protection

**Competition Dynamics:**
- Rank 6+: Normal bot progression (10-50% of scorePerLevel)
- Rank 4-5: Podium bots slow down (70% skip), creating catch-up opportunity
- Rank 1-3: Aggressive progression (30-80%) + 1 close competitor (±5-15% gap)

**Config:** LeaderboardConfig.asset (bot count, score scaling, rewards, reset period, unlock level)

**Data Persistence:** PlayerLeaderboardData.json, LeaderboardSync.json, LeaderboardSnapshots.json

**Editor Tools:** Echo > Leaderboard > (Clear Data, Force Online/Offline, Sync, Clear Snapshots)

**See:** `leaderboard_feature_overview` memory + Leaderboard.md for full details

## Repo

GitLab: `gitlab.amanotes.net/echo/hexa-music`
Branches: `main` (prod), `dev` (development)

## PopupSequence Module

**Location:** `Assets/_Echo/Scripts/Modules/PopupSequence/`

**Status:** Production-ready, integrated in HomeView (StarterPackPopup)

**Purpose:** Manages sequential popup displays with priority-based queuing, automatic timeouts, and event-driven lifecycle.

**Namespace:** `Amanotes.Echo` (shared across projects - do NOT change to HexaMusic)

**Key Features:**
- Priority-based queuing (higher priority shows first)
- Automatic 30-second timeout protection
- One-time display support with auto-unregister
- Dynamic queue manipulation (`RemoveFromQueue()`)
- KEventBus integration for lifecycle events
- Comprehensive debug logging

**Strategy Implementation Pattern:**
```csharp
public class MyPopupStrategy : BaseShowPopupStrategy
{
    private static bool _shownThisSession;

    public void InitStrategy()
    {
        Init(priority: 100);
        IsOneTimeOnly = true;
    }

    public override bool CanShow()
    {
        if (_shownThisSession) return false;
        return true;
    }

    protected override void ShowImplementation(Action onClose)
    {
        _shownThisSession = true;
        KEventBus.AddListener<MyPopupClosedEvent>(HandleClosed);
        KView.ShowPopup(nameof(MyPopup));
    }

    private void HandleClosed(KEventArgs args)
    {
        KEventBus.RemoveListener<MyPopupClosedEvent>(HandleClosed);
        _onCloseCallback?.Invoke(); // CRITICAL - prevents timeout
    }
}
```

**Registration Pattern:**
```csharp
private void Start()
{
    _strategy = new MyPopupStrategy();
    _strategy.InitStrategy();
    PopupSequenceManager.Instance.RegisterPopup(_strategy);
}

public override void Show(KViewChangeContext context)
{
    PopupSequenceManager.Instance.TriggerSequence();
}
```

**Critical Requirements:**
1. Always call `_onCloseCallback?.Invoke()` in close handler (or popup will timeout after 30s)
2. Remove KEventBus listeners to prevent leaks
3. Use static fields for per-session tracking
4. Use PlayerDataManager for cross-session persistence
5. Priority spacing: multiples of 10 (100, 90, 80) to allow insertions

**API Reference:**
- `RegisterPopup(IShowPopupStrategy)` / `UnregisterPopup(IShowPopupStrategy)`
- `TriggerSequence()` / `ForceCloseCurrent()` / `ClearQueue()`
- `RemoveFromQueue(IShowPopupStrategy)` - Cancel specific queued popup
- `HasPendingPopups()` / `HasQueuedPopups()` / `IsShowingPopup()`
- `SetDebugMode(bool)` - Enable comprehensive logging

**Events Dispatched:**
- `PopupSequenceStartedEvent` / `PopupSequenceCompletedEvent`
- `PopupShownEvent` / `PopupClosedEvent` (includes strategy reference)

**See:** `popup_sequence_module` memory for full documentation

## Shop System Architecture

**Overview:** Shared shop content component used in both lobby (ShopView) and gameplay (ShopPopup) contexts.

**Components:**
- **ShopContentView** - MonoBehaviour with all shop logic (IAP, daily rewards, timers, analytics)
- **ShopView** - LobbySubView thin wrapper for lobby/home context
- **ShopPopup** - KViewBaseView thin wrapper for gameplay context

**Pattern:** Composition over inheritance - both wrappers delegate to shared ShopContentView

**ShopContentView Lifecycle:**
```csharp
public void Initialize();  // Subscribe events, hook IAP callbacks
public void Show();        // Load IAPs, update UI, start timers, log analytics
public void Hide();        // Cancel timers, cleanup
public void Cleanup();     // Unsubscribe events, dispose resources
```

**Features:**
- IAP loading and purchase flow (all products)
- Daily rewards system (Free Ads Coin, Daily Free Coin)
- Starter Pack display/hiding based on purchase state
- Remove Ads state management
- Timer loop for cooldown updates (1s interval)
- Analytics tracking (screen open, impressions, clicks, purchases)

**ShopView (Lobby Context):**
```csharp
[SerializeField] private ShopContentView _shopContentView;

void Awake() { _shopContentView.Initialize(); }
void OnShow() { _shopContentView.Show(); }
void OnHide() { _shopContentView.Hide(); }
void OnDestroy() { _shopContentView.Cleanup(); }
```

**ShopPopup (Gameplay Context):**
```csharp
[SerializeField] private ShopContentView _shopContentView;
[SerializeField] private Button _backButton;  // Parent owns navigation

void Awake() {
    _backButton.onClick.AddListener(() => {
        AnalyticsManager.LogScreenOpen(EScreenName.action_phase);
        KView.HidePopupById(nameof(ShopPopup));
    });
    _shopContentView.Initialize();
}
void Show() { _shopContentView.Show(); }
void OnDestroy() { _shopContentView.Cleanup(); }
```

**Analytics:**
- Screen open: `shop` (both contexts)
- Back button: `action_phase` (ShopPopup only, returns to gameplay)
- IAP events: `shop` source (impressions, clicks, purchases)

**Prefab Structure:**
- `Scroll View.prefab` - Contains ShopContentView component + all UI
- `ShopView.prefab` - Hosts Scroll View instance
- `ShopPopup.prefab` - Hosts Scroll View instance + back button

**Key Benefits:**
- Single source of truth for all shop logic
- Consistent UX across lobby and gameplay contexts
- Daily rewards and starter pack available in both contexts
- Update once, applies everywhere

**Files:**
- `Assets/_Echo/Scripts/Views/Lobby/ShopView/ShopContentView.cs` (210 lines, all logic)
- `Assets/_Echo/Scripts/Views/Lobby/ShopView/ShopView.cs` (34 lines, thin wrapper)
- `Assets/_Echo/Scripts/Popups/ShopPopup.cs` (36 lines, thin wrapper)
- `Assets/_Echo/Prefabs/UI/Shop/Scroll View.prefab`

## StarterPackPopup System

**Location:** `Assets/_Echo/Scripts/Popups/StarterPackPopup.cs`, `StarterPackPopupStrategy.cs`

**Purpose:** IAP popup for starter pack with automatic level-based and daily display triggering.

**Architecture:**
- **StarterPackPopup** - KViewBaseView, fully data-driven from IAPConfig
- **StarterPackPopupStrategy** - BaseShowPopupStrategy, handles trigger logic
- **StarterPackPopupContext** - Data class (Product, SaleOffPercent, callbacks)

**Trigger Conditions:**
1. Player level >= `IAPManager.Instance.IAPConfig.starterPackLevel` (configurable)
2. First time shown today (daily limit via `PlayerDataManager.Profile.LastStarterPackPopupShownDate`)
3. StarterPack not purchased (`IAPManager.IsNonConsumablePurchased()`)

**Data Flow:**
- Context only needs `IAPProduct.StarterPack` enum
- Popup fetches all data from IAPConfig: price, coin amount, booster rewards
- Uses `BoosterConfig.GetUIConfigByType()` for booster icons
- Shows `RewardAnimationPopup` on purchase success

**Integration (HomeView):**
```csharp
private StarterPackPopupStrategy _starterPackPopupStrategy;

void Awake() {
    _starterPackPopupStrategy = new StarterPackPopupStrategy();
    _starterPackPopupStrategy.InitStrategy();
    PopupSequenceManager.Instance.RegisterPopup(_starterPackPopupStrategy);
}

public override void OnShow() {
    PopupSequenceManager.Instance.TriggerSequence();
}

void OnDestroy() {
    PopupSequenceManager.Instance.UnregisterPopup(_starterPackPopupStrategy);
}
```

**Configuration:**
- `IAPConfigSO.starterPackLevel` - Global field (not per-product)
- `PlayerProfile.lastStarterPackPopupShownDate` - Date in `DateTime.Ticks`
- `IAPManager.IAPConfig` - Public property for config access

**Key Patterns:**
- Daily limit: `DateTime.Ticks` comparison (ignores time-of-day)
- Dual callback: purchase success OR popup closed
- Event cleanup in both code paths
- Priority: 95 (after high-priority popups)
- IsOneTimeOnly: false (can show daily until purchased)

**See:** `starter_pack_popup_implementation` memory for full details

## FTUE Hint System

**Location:** `Assets/_Echo/Scripts/Gameplay/HintHelper.cs`, `Assets/_Echo/Scripts/Behaviors/GameStates/PlayState.cs`

**Purpose:** Contextual hint system that detects stuck players during FTUE and provides immediate guidance.

**Architecture:**
- **HintHelper** - Core hint logic (idle detection, repeated click tracking, popup-aware blocking)
- **PlayState** - Integration with async UniTask update loop (FTUE only)
- **TutorialUIManager** - Shared UI layer for display
- **GameplayManager** - Public API for dismissing hints

**Trigger Conditions:**
1. **Idle Detection**: 10 seconds without tile interaction
2. **Repeated Click Detection**: 3+ clicks on same unresolvable tile within 5 seconds

**Display Behavior:**
- Shows BOTH text hint AND hand pointer immediately (no escalation)
- Hints stay visible until user resolves any tile (no auto-hide)
- Works during FTUE tutorial steps (no blocking)
- Only active when `TutorialManager.IsActive` is true
- **Automatically dismissed when PopupBuyMove appears** (no overlap)

**Popup Overlap Prevention (Multi-Layer):**
```csharp
// 1. Block new hints when popup is showing
private bool ShouldBlockHint()
{
    if (KView.IsPopupShowing(nameof(PopupBuyMove)))
        return true;
    // ... other checks
}

// 2. Force dismiss all active hints
public void DismissAllHints()
{
    TutorialUIManager.Instance.message.SetVisible(false);
    TutorialUIManager.Instance.pointer.SetVisible(false);
    TutorialUIManager.Instance.SetCanvasVisible(false);
    _isTextHintActive = false;
    _currentPointedCell = null;
    _timeSinceLastInteraction = 0f;
}

// 3. PlayState exposes dismissal
public void DismissActiveHints() => _hintHelper?.DismissAllHints();

// 4. GameplayManager public API
public void DismissActiveHints()
{
    if (_currentState is PlayState playState)
        playState.DismissActiveHints();
}

// 5. PopupBuyMove auto-dismisses on show
public override UniTask Setup(KViewDetail detail)
{
    // ...
    GameplayManager.Instance?.DismissActiveHints();
    // ...
}
```

**PlayState Integration Pattern:**
```csharp
public override void Enter()
{
    if (TutorialManager.IsActive)
    {
        _hintHelper = new HintHelper(Manager.GridManager);
        Manager.GridManager.OnCellInteracted += OnCellInteracted;
        StartHintUpdateLoop();  // Async UniTask loop
    }
}

private async UniTaskVoid UpdateHintHelperLoop(CancellationToken ct)
{
    while (!ct.IsCancellationRequested)
    {
        _hintHelper?.Update(Time.deltaTime);
        await UniTask.Yield(PlayerLoopTiming.Update, ct);
    }
}

public override void Exit()
{
    if (_hintHelper != null)
    {
        _hintUpdateCts?.Cancel();
        _hintUpdateCts?.Dispose();
        Manager.GridManager.OnCellInteracted -= OnCellInteracted;
        _hintHelper.Dispose();
        _hintHelper = null;
    }
}
```

**TutorialUIManager Usage (follows NewFeatureGuideManager pattern):**
```csharp
// Text hint
TutorialUIManager.Instance.message.SetBubbleType(BubbleType.Capsule);
TutorialUIManager.Instance.message.SetMessage(hintText);
TutorialUIManager.Instance.message.SetDefaultTarget();
TutorialUIManager.Instance.SetBlocksRaycasts(false);
TutorialUIManager.Instance.SetCanvasVisible(true);
TutorialUIManager.Instance.message.SetVisible(true);

// Hand pointer
TutorialUIManager.Instance.pointer.SetTarget(
    cellTransform, PointerPosition.PointUp, new Vector3(30, -30), isWorldObject: true
);
TutorialUIManager.Instance.SetCanvasVisible(true);
TutorialUIManager.Instance.pointer.SetVisible(true);
```

**Key Methods:**
- `HintHelper.Update(float deltaTime)` - Increments idle timer
- `HintHelper.NotifyTileInteraction(Vector2Int, bool wasResolved)` - Tracks clicks, dismisses hints
- `HintHelper.FindMostAccessibleCell()` - Finds first movable StackedCell or PauseCell
- `HintHelper.TriggerHint()` - Shows both text hint and hand pointer immediately
- `HintHelper.ShouldBlockHint()` - Checks for active popups/guides to prevent overlap
- `HintHelper.DismissAllHints()` - Force dismiss all hints (used when PopupBuyMove appears)
- `PlayState.DismissActiveHints()` - Public method to dismiss hints
- `GameplayManager.DismissActiveHints()` - Public API for external dismissal

**Critical Design Decisions:**
1. No tutorial step blocking - hints work throughout FTUE
2. Immediate display - both hints show at once (no escalation)
3. No auto-hide - hints only dismiss on tile resolution or popup appearance
4. Pointer uses `PointerPosition.PointUp` with offset `(30, -30)`
5. FTUE-only activation via `TutorialManager.IsActive` check
6. Multi-layer popup overlap prevention: blocking + force dismissal

**Edge Cases Handled:**
- ✅ Hints showing → run out of moves → PopupBuyMove triggers → hints immediately dismissed
- ✅ Out of moves + popup showing → idle 10s → new hints blocked
- ✅ Timing edge cases → popup Setup() force-dismisses lingering hints

**See:** `ftue_hint_system_implementation` memory for full details

## Memory Sync Protocol

When user says "update memories":
1. Check this file for gaps
2. Extract new patterns/fixes from conversation
3. Update AGENTS.md with concise additions
