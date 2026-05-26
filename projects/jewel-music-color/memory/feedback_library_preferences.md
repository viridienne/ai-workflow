---
name: library-preferences
description: Preferred libraries for animation, LINQ, and dependency injection in this Unity project
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 6851e7cc-34c3-4b76-9e49-0c3c4e80810f
---

Prefer LitMotion over DOTween for animations. Prefer Zlinq for LINQ. Prefer Init Args (Sisus.Init) DI framework over singletons.

**Why:** User's stated preference. Singletons are fully removed from this project.

**How to apply:**
- Animation: use LitMotion API, not DOTween (DOTween exists in project but is legacy)
- LINQ: use Zlinq
- DI: use `[Service(typeof(IFoo), LazyInit = true)]` + `Init()` injection via Init Args. Never use `Manager.Instance` or static singletons. Always depend on interfaces, never concrete classes.
