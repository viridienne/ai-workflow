#!/bin/bash
# Claude Config Sync Script
# Run this on each new device to link configs to your ai-workflow repo

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "🔗 Setting up Claude config symlinks..."
echo "Repository: $REPO_DIR"

# Create .claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Backup existing files
backup_if_exists() {
    local file=$1
    if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
        echo "📦 Backing up existing $(basename "$file") to ${file}.backup"
        mv "$file" "${file}.backup"
    fi
}

# Create symlink
create_symlink() {
    local source=$1
    local target=$2

    # Remove existing symlink/file
    rm -f "$target"

    # Create symlink
    ln -sf "$source" "$target"
    echo "✅ Linked: $target -> $source"
}

# 1. Global CLAUDE.md
backup_if_exists "$CLAUDE_DIR/CLAUDE.md"
create_symlink "$REPO_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# 2. Settings (optional)
if [[ -f "$REPO_DIR/claude/settings.json" ]]; then
    backup_if_exists "$CLAUDE_DIR/settings.json"
    create_symlink "$REPO_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"
fi

# 3. Keybindings (optional)
if [[ -f "$REPO_DIR/claude/keybindings.json" ]]; then
    backup_if_exists "$CLAUDE_DIR/keybindings.json"
    create_symlink "$REPO_DIR/claude/keybindings.json" "$CLAUDE_DIR/keybindings.json"
fi

# 4. Project-specific configs (add your projects here)
# Example: hexa-music (AGENTS.md is the source, CLAUDE.md links to it)
PROJECT_PATH="$HOME/hexa-music"
if [[ -d "$PROJECT_PATH" ]]; then
    # Backup and link AGENTS.md (the actual file)
    backup_if_exists "$PROJECT_PATH/AGENTS.md"
    create_symlink "$REPO_DIR/projects/hexa-music/CLAUDE.md" "$PROJECT_PATH/AGENTS.md"

    # Create CLAUDE.md -> AGENTS.md symlink (local project convention)
    rm -f "$PROJECT_PATH/CLAUDE.md"
    ln -sf "AGENTS.md" "$PROJECT_PATH/CLAUDE.md"
    echo "✅ Linked: $PROJECT_PATH/CLAUDE.md -> AGENTS.md (local)"
fi

echo ""
echo "✨ Setup complete! Your configs are now synced to the ai-workflow repo."
echo ""
echo "📝 Next steps:"
echo "   1. Edit configs in either location (changes sync automatically)"
echo "   2. Commit and push changes: cd $REPO_DIR && git add . && git commit -m 'Update configs'"
echo "   3. On other devices: git pull && ./setup.sh"
