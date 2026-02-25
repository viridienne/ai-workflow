# AI Workflow - Project Configuration Management

Centralized repository for managing Claude Code configurations across multiple projects.

## Directory Structure

```
ai-workflow/
├── projects/
│   ├── hexa-music/
│   │   ├── CLAUDE.md
│   │   └── AGENTS.md
│   └── [other-projects]/
│       ├── CLAUDE.md
│       └── AGENTS.md
└── global/
    ├── claude-config/    # Global Claude Code settings
    └── mcp-servers/      # MCP server configurations
```

## Quick Commands

### Copy Project Files TO ai-workflow

Run from your **project directory** (e.g., `~/projects/hexa-music`):

```bash
PROJECT=$(basename "$PWD") && AI_WORKFLOW=$(find ~ -maxdepth 3 -type d -name "ai-workflow" -print -quit 2>/dev/null) && mkdir -p "$AI_WORKFLOW/projects/$PROJECT" && cp CLAUDE.md AGENTS.md "$AI_WORKFLOW/projects/$PROJECT/" && echo "Copied $PROJECT files to $AI_WORKFLOW/projects/$PROJECT"
```

### Copy Project Files FROM ai-workflow

Run from your **project directory** to restore files:

```bash
PROJECT=$(basename "$PWD") && AI_WORKFLOW=$(find ~ -maxdepth 3 -type d -name "ai-workflow" -print -quit 2>/dev/null) && cp "$AI_WORKFLOW/projects/$PROJECT/CLAUDE.md" "$AI_WORKFLOW/projects/$PROJECT/AGENTS.md" . && echo "Copied $PROJECT files from $AI_WORKFLOW/projects/$PROJECT"
```

### Copy Global Claude Settings TO ai-workflow

```bash
AI_WORKFLOW=$(find ~ -maxdepth 3 -type d -name "ai-workflow" -print -quit 2>/dev/null) && \
mkdir -p "$AI_WORKFLOW/global/claude-config" && \
cp -r ~/.config/claude/* "$AI_WORKFLOW/global/claude-config/" 2>/dev/null || true && \
cp ~/Library/Application\ Support/Claude/* "$AI_WORKFLOW/global/claude-config/" 2>/dev/null || true && \
[ -f ~/.claude/config.json ] && cp ~/.claude/config.json "$AI_WORKFLOW/global/claude-config/" 2>/dev/null || true && \
echo "Copied Claude Code global settings to $AI_WORKFLOW/global/claude-config"
```

### Restore Global Claude Settings FROM ai-workflow

```bash
AI_WORKFLOW=$(find ~ -maxdepth 3 -type d -name "ai-workflow" -print -quit 2>/dev/null) && \
mkdir -p ~/.config/claude ~/Library/Application\ Support/Claude && \
cp -r "$AI_WORKFLOW/global/claude-config/"* ~/.config/claude/ 2>/dev/null || true && \
cp -r "$AI_WORKFLOW/global/claude-config/"* ~/Library/Application\ Support/Claude/ 2>/dev/null || true && \
echo "Restored global Claude configs from $AI_WORKFLOW/global/claude-config"
```

### Combined: Copy Everything TO ai-workflow

Run from your **project directory**:

```bash
PROJECT=$(basename "$PWD") && \
AI_WORKFLOW=$(find ~ -maxdepth 3 -type d -name "ai-workflow" -print -quit 2>/dev/null) && \
mkdir -p "$AI_WORKFLOW/projects/$PROJECT" "$AI_WORKFLOW/global/claude-config" && \
cp CLAUDE.md AGENTS.md "$AI_WORKFLOW/projects/$PROJECT/" 2>/dev/null && \
cp -r ~/.config/claude/* "$AI_WORKFLOW/global/claude-config/" 2>/dev/null || true && \
echo "Copied $PROJECT files and global Claude configs to $AI_WORKFLOW"
```

### Combined: Restore Everything FROM ai-workflow

Run from your **project directory**:

```bash
PROJECT=$(basename "$PWD") && \
AI_WORKFLOW=$(find ~ -maxdepth 3 -type d -name "ai-workflow" -print -quit 2>/dev/null) && \
cp "$AI_WORKFLOW/projects/$PROJECT/CLAUDE.md" "$AI_WORKFLOW/projects/$PROJECT/AGENTS.md" . 2>/dev/null && \
mkdir -p ~/.config/claude && \
cp -r "$AI_WORKFLOW/global/claude-config/"* ~/.config/claude/ 2>/dev/null || true && \
echo "Restored $PROJECT files and global configs from $AI_WORKFLOW"
```

## How It Works

1. **Auto-detection**: Commands automatically detect:
   - Current project name from directory (`hexa-music`, etc.)
   - Location of `ai-workflow` repo (searches common locations)

2. **Smart Structure**: Each project gets its own folder under `projects/`

3. **Global Configs**: Shared Claude Code settings stored once in `global/`

## Usage Examples

### Setting up a new project
```bash
cd ~/projects/new-game
# Create CLAUDE.md and AGENTS.md
# Then run the copy TO command
```

### Syncing changes back to ai-workflow
```bash
cd ~/projects/hexa-music
# Edit CLAUDE.md or AGENTS.md
# Run copy TO command to sync
```

### Restoring to a fresh machine
```bash
cd ~/projects/hexa-music
# Run copy FROM command to restore project files and global settings
```

### Daily workflow with version control
```bash
# After making changes
cd ~/ai-workflow
git add .
git commit -m "Update hexa-music configs"
git push

# On another device
cd ~/ai-workflow
git pull
# Then navigate to project and run copy FROM command
```

## Config Locations

Claude Code checks these locations (platform-dependent):
- `~/.config/claude/` - CLI configs (Linux/macOS)
- `~/Library/Application Support/Claude/` - GUI configs (macOS)
- `~/.claude/config.json` - Alternative location

## Notes

- Commands use `2>/dev/null || true` to gracefully handle missing files
- `mkdir -p` ensures directories exist before copying
- Auto-detects project name using `basename "$PWD"`
- Searches up to 3 levels deep for `ai-workflow` directory
- All commands are idempotent and safe to run multiple times

## Benefits

✅ **Version Control**: Track config changes over time
✅ **Easy Sync**: Simple commands sync configs across devices
✅ **Auto-detection**: No need to remember paths
✅ **Multi-project**: Manage multiple projects in one repo
✅ **Flexible**: Copy individual projects or everything at once
