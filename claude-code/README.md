# Claude Code Configuration

Personal Claude Code settings synced across devices.

## Setup on New Device

### Global Configs (All Projects)
```bash
# 1. Clone this repo
git clone https://github.com/viridienne/ai-workflow.git ~/ai-workflow

# 2. Create symlinks for global configs
ln -s ~/ai-workflow/claude-code/settings.json ~/.claude/settings.json
ln -s ~/ai-workflow/claude-code/CLAUDE.md ~/.claude/CLAUDE.md

# 3. Verify
ls -la ~/.claude/settings.json ~/.claude/CLAUDE.md
```

### Project Configs (e.g., hexa-music)
```bash
# In your project directory, symlink to shared AGENTS.md
cd ~/hexa-music
ln -s ~/ai-workflow/claude-code/AGENTS.md AGENTS.md
ln -s ~/ai-workflow/claude-code/AGENTS.md CLAUDE.md
```

## Files

- **settings.json** - Model preferences, permissions, hooks
- **CLAUDE.md** - Personal instructions and preferences (global)
- **AGENTS.md** - Project-specific instructions (can be shared across projects)

## What's NOT Synced

- Auto memory (`~/.claude/projects/`) - Device-specific
- Session history (`~/.claude/history.jsonl`) - Local only
- File history, debug logs, cache - Local only
