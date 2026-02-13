# AI Workflow Configuration

Centralized repository for Claude Code configuration files, synced across devices.

## Structure

```
ai-workflow/
├── claude/
│   ├── CLAUDE.md          # Global oh-my-claudecode config
│   ├── settings.json      # Claude settings (model, plugins, statusLine)
│   └── keybindings.json   # (optional) Custom keybindings
├── projects/
│   └── hexa-music/
│       └── CLAUDE.md      # Project-specific config (AGENTS.md)
├── .gitignore             # Ignore backups and cache files
├── setup.sh               # Setup script for new devices
├── SETUP.md               # Quick setup guide
└── README.md              # This file
```

## Setup on New Device

1. **Clone this repo:**
   ```bash
   cd ~ && git clone <your-repo-url> ai-workflow
   ```

2. **Run setup script:**
   ```bash
   cd ai-workflow
   ./setup.sh
   ```

3. **Verify symlinks:**
   ```bash
   ls -la ~/.claude/CLAUDE.md
   ls -la ~/hexa-music/AGENTS.md
   ```

## Daily Workflow

### Making Changes

Edit configs in **either location** (changes sync automatically via symlinks):
- `~/.claude/CLAUDE.md` ↔️ `~/ai-workflow/claude/CLAUDE.md`
- `~/.claude/settings.json` ↔️ `~/ai-workflow/claude/settings.json`
- `~/hexa-music/AGENTS.md` ↔️ `~/ai-workflow/projects/hexa-music/CLAUDE.md`

### Committing Changes

```bash
cd ~/ai-workflow
git status                          # See what changed
git add .
git commit -m "Update configs"
git push
```

### Syncing to Other Devices

```bash
cd ~/ai-workflow
git pull                            # Pull latest changes
# Symlinks auto-update!
```

## Adding New Projects

1. **Copy project config to repo:**
   ```bash
   cp ~/my-project/CLAUDE.md ~/ai-workflow/projects/my-project/CLAUDE.md
   ```

2. **Update setup.sh:**
   ```bash
   # Add this to setup.sh
   PROJECT_PATH="$HOME/my-project"
   if [[ -d "$PROJECT_PATH" ]]; then
       backup_if_exists "$PROJECT_PATH/CLAUDE.md"
       create_symlink "$REPO_DIR/projects/my-project/CLAUDE.md" "$PROJECT_PATH/CLAUDE.md"
   fi
   ```

3. **Re-run setup:**
   ```bash
   ./setup.sh
   ```

## Troubleshooting

### Symlinks not working?
```bash
# Check if symlink exists
ls -la ~/.claude/CLAUDE.md

# Re-run setup
cd ~/ai-workflow && ./setup.sh
```

### Conflicts after git pull?
```bash
# Your changes will be in the repo (symlink target)
# Resolve conflicts in the repo directory
cd ~/ai-workflow
git status
# Fix conflicts, then commit
```

### Backup existing configs
Backups are created automatically by `setup.sh` as `*.backup` files.

## Benefits

✅ **Version Control:** Track config changes over time
✅ **Easy Sync:** One `git pull` syncs all devices
✅ **Automatic:** Symlinks keep everything in sync
✅ **Safe:** Automatic backups before linking
✅ **Flexible:** Edit in either location
