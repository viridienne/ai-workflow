---
name: config-event-unification
description: BaseConfigManager keeps two separate events — onLocalConfigLoadedEvent and onRemoteConfigLoadedEvent — do NOT merge them into one
metadata: 
  node_type: memory
  type: project
  originSessionId: 630645c0-e880-4cd4-8dfe-7a106a7d8e69
---

**Decision:** Keep `onLocalConfigLoadedEvent` and `onRemoteConfigLoadedEvent` as two separate protected fields in `BaseConfigManager`. Do NOT merge into single `onConfigLoadedEvent`.

**Why:** User explicitly reverted a prior merge. The distinction is intentional — local vs remote load paths may diverge in future behavior.

**How to apply:**
- `onLocalConfigLoadedEvent` fires for: Resources fallback load + disk-cache (previously downloaded) load
- `onRemoteConfigLoadedEvent` fires for: fresh CDN/remote download only
- New config managers subscribe to **both** events if handler is the same, e.g.:
  ```csharp
  onLocalConfigLoadedEvent += ParseJson;
  onRemoteConfigLoadedEvent += ParseJson;
  ```

**Current subscribers:** LevelsManager, AdsManager, IAPManager — all subscribe to both.

**Related:** [[level-database-pattern]]
