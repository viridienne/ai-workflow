# Hexa Music - Agent Guide

Unity hexagonal puzzle game (Amanotes NGD)
- Unity 2022.3.62f2 LTS, URP, iOS/Android, C# (.NET Standard 2.1)
- Namespace: `Amanotes.Echo.HexaMusic` (default), check folder for variations
- Repo: `gitlab.amanotes.net/echo/hexa-music` (main: prod, dev: development)

## RTK Tool Preferences

The RTK hook only rewrites `Bash` tool calls. Built-in `Read`, `Grep`, and `Glob` tools bypass it.
For token-saving compact output on heavy operations, use Bash with `rtk` instead:

```bash
rtk read <file>          # instead of Read tool (large files)
rtk grep <pattern> <dir> # instead of Grep tool (multi-file search)
rtk find <pattern>       # instead of Glob tool (file discovery)
```

Use built-in tools for small, focused reads where token savings are minimal.

## CRITICAL: Tool Usage for Spawned Agents

**Serena MCP - MEMORY ONLY:**
✅ USE Serena ONLY for memory: `read_memory`, `write_memory`, `list_memories`, `edit_memory`, `delete_memory`, `rename_memory`
❌ NO Serena for code: NO `find_symbol`, `get_symbols_overview`, `replace_symbol_body`, `insert_after_symbol`, `search_for_pattern`
✅ Use Read, Edit, Write, Grep, Glob for ALL code/file operations

**Workflow:** Grep/Glob → Read → Edit/Write → verify

**UnityMCP:** `read_console`, `refresh_unity`, `manage_scene`, `manage_gameobject`, `manage_components`, `manage_prefabs`, `batch_execute`
**Other:** Bash (git, build), Read/Write/Edit (non-C#), Context7 MCP (docs)

## Memory Access (Serena)

**✅ Use Serena memory tools for persistent knowledge:**
- `read_memory(memory_name)`: Read specific memory by name
- `write_memory(memory_name, content)`: Write/update memory (max chars configurable)
- `list_memories(topic)`: List available memories, optionally filtered by topic
- `edit_memory(memory_name, needle, repl, mode)`: Edit existing memory content
- `delete_memory(memory_name)`: Delete a memory (requires user permission)
- `rename_memory(old_name, new_name)`: Rename or move memory using "/" for topics

**Workflow:** `list_memories()` → `read_memory(name)` OR `write_memory(name, content)`

**When to use:**
- Store architectural decisions, patterns, and learnings
- Access cross-session knowledge about the project
- Document bug fixes and solutions for future reference
- Organize by topic using "/" in names (e.g., "auth/login/logic")

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

**Data:** ScriptableObjects (LevelData, LevelDatabase, Configuration, DirectionConfig, *ConfigSO)
- DirectionConfig: centralized hexagon visual properties (scale, heights, animation durations, easing, angles)
**Player Data:** Partial classes (Level, Currency, Booster, Life, DailyQuest, Tutorial, Profile)

### Tech Stack

**Animation:** LitMotion (preferred), DOTween Pro, VisualState2
- **CRITICAL LitMotion Rule:** Every `MotionHandle` MUST be cancelled in `OnDisable()`. Infinite loops (`WithLoops(-1)`) are especially dangerous — they keep running after the GameObject is destroyed, causing `MissingReferenceException`. Pattern:
```csharp
MotionHandle _handle;
void OnDisable() { if (_handle.IsActive()) _handle.Cancel(); }
```
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

**Hard Rules (no exceptions):**
❌ MonoBehaviour constructors — use `Awake()` or `Start()` based on execution order
❌ `try/catch` — use early returns; `try/finally` is OK
❌ `PlayerPrefs` for play progression — use `PlayerDataManager`; OK for simple mechanics
❌ Bare `+=` on C# events without preceding `-=` when subscription can repeat (views surviving retry)

**Soft Rules (avoid unless clearly justified):**
⚠️ XML docs — OK for explaining critical/non-obvious methods
⚠️ `#region` — OK for grouping related methods, improves readability in large files
⚠️ Comments — only for non-obvious logic, never for obvious code
⚠️ Tiny methods under 5 lines — inline unless reused or named for clarity
⚠️ Over-engineering: helpers/abstractions used once, feature flags for trivial cases, backwards-compat shims

**Naming:**
- Fields: `_camelCase` — omit `private` (it's the default)
- Methods/Classes: `PascalCase`; Locals/Params: `camelCase`

**Preferences:**
✅ File-scoped namespaces: `namespace Foo;` not `namespace Foo { }`
✅ `is`/`is not` over `== null`/`!= null`
✅ Switch expressions (`=>`) over switch statements
✅ `var` for locals when type is obvious from context
✅ Early returns over nested conditions
✅ Fields over properties; `Array.Empty<T>()` over `new T[0]`
✅ Extension methods in `Utils/Extensions/`; one file per class

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

**Event Subscription Safety:**
```csharp
// ❌ WRONG — double-subscribe if called again without unsubscribe
gridManager.OnContainerUnregistered += OnContainerUnregistered;

// ✅ CORRECT — always unsubscribe first
gridManager.OnContainerUnregistered -= OnContainerUnregistered;
gridManager.OnContainerUnregistered += OnContainerUnregistered;
```
Views like GameplayView survive level retries without OnDisable/OnEnable cycle. Any event subscription triggered by visibility events or repeated initialization must guard against double-subscribe.

**Odin Inspector:** Always wrap with `#if ODIN_INSPECTOR`

**Performance:**
- ZLinq: `dict.Values.AsValueEnumerable().OfType<T>()` — prefer over LINQ
- Avoid `.ToArray()`/`.ToList()` in hot paths; cache components, use object pooling

## File Organization

- Code: `Assets/_Echo/Scripts/`
- Artwork: `Assets/_Echo/Artworks/`
- Prefabs: `Assets/_Echo/Prefabs/`
- Data: `Assets/_Echo/Data/`

## Common Workflows

**Modify Cell:** Find in `Behaviors/`, read partials, understand interfaces, minimal changes, verify compilation
**Add Feature:** Use managers, ScriptableObjects for config, event-driven, UniTask for async, pooling
**Debug Race Conditions:** Check `_isRotating`, `_hasDropZoneAnimations` flags
**Booster UI Visibility:** StartState owns startup, PauseState owns pause, BoosterUI owns mode changes. BoosterManager does NOT dispatch visibility events. Buttons default hidden, shown by owner.
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

## Notes

- Check Serena memories for detailed patterns
- All SerializedFields in main file (partial classes)
- Always verify compilation, code quality > speed
- Unity JSON: no parameterized constructors, read-only fields, properties without `[field: SerializeField]`

## Memory Sync Protocol

When user says "update memories":
1. Extract new patterns/fixes from conversation
2. Write/update relevant Serena memories
3. Check CLAUDE.md for gaps and update if needed

# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
