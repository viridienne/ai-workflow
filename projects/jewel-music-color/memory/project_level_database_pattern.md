---
name: level-database-pattern
description: Levels config migrated to JSON with LevelDatabase wrapper; embeds grid CDN metadata
metadata: 
  node_type: memory
  type: project
  originSessionId: 630645c0-e880-4cd4-8dfe-7a106a7d8e69
---

**Pattern:** `LevelDatabase` wrapper class holds `GridVersion` (int), `GridCdnBase` (string), and `Levels` (List<LevelData>).

**Why:** JsonUtility cannot deserialize root JSON arrays, so wrapper is needed. Grid CDN metadata moved from `masterConfig` Grid feature into levels config — one source of truth instead of cross-config dependency.

**Structure:**
```json
{
  "GridVersion": 1,
  "GridCdnBase": "https://...",
  "Levels": [...]
}
```

**How to apply:** When updating levels config format, maintain this wrapper structure. Grid version/CDN changes require new levels config version.

**Related:** [[config-event-unification]]
