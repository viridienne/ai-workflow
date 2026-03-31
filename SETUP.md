# AI Workflow Setup - New Computer

Quick setup guide for syncing Claude configs on a new device.

---

## Prerequisites

- Git installed
- ai-workflow repo already cloned (via Fork or `git clone`)

---

## Setup Steps

### 1. Navigate to repo

```bash
cd ~/ai-workflow
```

### 2. Make setup script executable

```bash
chmod +x setup.sh
```

### 3. Run setup script

```bash
./setup.sh
```

**Expected output:**
```
🔗 Setting up Claude config symlinks...
Repository: /Users/yourname/ai-workflow

✅ Linked: ~/.claude/CLAUDE.md -> ~/ai-workflow/claude/CLAUDE.md
✅ Linked: ~/.claude/settings.json -> ~/ai-workflow/claude/settings.json
✅ Linked: ~/hexa-music/AGENTS.md -> ~/ai-workflow/projects/hexa-music/CLAUDE.md
✅ Linked: ~/hexa-music/CLAUDE.md -> AGENTS.md (local)

✨ Setup complete!
```

### 4. Verify symlinks work

```bash
ls -la ~/.claude/CLAUDE.md
```

**Should show:** `... -> /Users/yourname/ai-workflow/claude/CLAUDE.md`

---

## Done! ✅

Your configs are now synced. Edit anywhere:
- `~/.claude/CLAUDE.md` ↔️ `~/ai-workflow/claude/CLAUDE.md`
- `~/.claude/settings.json` ↔️ `~/ai-workflow/claude-code/settings.json`
- `~/.claude.json` ↔️ `~/ai-workflow/claude-code/claude.json` (includes MCP servers)
- `~/hexa-music/AGENTS.md` ↔️ `~/ai-workflow/projects/hexa-music/CLAUDE.md`

Changes sync automatically via symlinks. Use Fork to commit/push/pull.

> ⚠️ `claude.json` contains account identifiers (email, UUID). Keep this repo **private**.

---

## Troubleshooting

**Symlinks not working?**
```bash
cd ~/ai-workflow && ./setup.sh
```

**Project directory doesn't exist yet?**
1. Clone the project first (e.g., `git clone <url> ~/hexa-music`)
2. Re-run: `cd ~/ai-workflow && ./setup.sh`

**Want to add another project?**
1. Add config file: `cp ~/my-project/CLAUDE.md ~/ai-workflow/projects/my-project/CLAUDE.md`
2. Edit `setup.sh` to add your project (copy the hexa-music pattern)
3. Run: `./setup.sh`
