---
name: project_time_attack
description: "Time attack mode implementation — countdown timer, win/lose views, LevelData.TimeLimit field"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1a5f367a-ae92-46d1-bc28-2a27d0000355
---

Two gameplay modes added: unlimited (existing) and time limit (countdown).

**LevelData.TimeLimit** (int, seconds): 0 = unlimited, >0 = time attack. Field in `Assets/_Echo/Scripts/Gameplay/Data/Serialized/LevelData.cs`.

**Countdown logic**: Lives entirely in `PlayState` (not UI). `Update()` decrements `_timeRemaining` via `Time.deltaTime`. Triggers `RequestStateChange(GameState.Lose)` at zero. Timer display updated each frame via `IGameplayView.SetTimerDisplay()`.

**Display**: `GameplayTimerView` (new, `Assets/_Echo/Scripts/Views/Gameplay/GameplayTimerView.cs`) — display-only MonoBehaviour, `Show/SetDisplay/Hide`. Format: `MM:SS`. Wired into `GameplayView` via `[SerializeField] _timerView`. **Deliberately NOT using `TimerView`** (that component is for server-sync cooldowns via `IGameMasterTime`, not frame-accurate gameplay).

**Why:** Countdown logic belongs to game state (PlayState), not UI. UI is display-only. See [[feedback_library_preferences]] for similar separation-of-concerns decisions.

**WinView / LoseView**: Placeholder stubs in `Assets/_Echo/Scripts/Views/Gameplay/`. `KViewBaseView` subclasses with empty `Setup()`. `WinState.ShowResultView()` and `LoseState.Process()` now call `KView.Goto` to show them. LoseView auto-returns to Lobby after 2s delay.

**How to apply:**
- Set `TimeLimit > 0` in `LevelData` JSON or Inspector to enable time attack for a level
- Inspector wiring still needed: GameplayView prefab needs `GameplayTimerView` child with `_timerText` TMP assigned; WinView + LoseView prefabs need creating and registering in KView routing
- Win fires via `OnWinConditionMet` event before Lose can trigger — no race condition
