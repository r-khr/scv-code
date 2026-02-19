#!/bin/bash
set -e

# SCV Code Installer
# Installs StarCraft SCV sound effects for Claude Code

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SOUNDS_DIR="$CLAUDE_DIR/sounds"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  SCV Code Installer"
echo "  StarCraft SCV sounds for Claude Code"
echo "=========================================="
echo ""

# Detect OS and set audio player
detect_player() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        PLAYER="afplay"
        echo -e "${GREEN}Detected macOS${NC} - using afplay"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v paplay &> /dev/null; then
            PLAYER="paplay"
            echo -e "${GREEN}Detected Linux${NC} - using paplay (PulseAudio)"
        elif command -v aplay &> /dev/null; then
            PLAYER="aplay"
            echo -e "${GREEN}Detected Linux${NC} - using aplay (ALSA)"
        else
            echo -e "${RED}Error: No audio player found.${NC}"
            echo "Please install pulseaudio-utils (paplay) or alsa-utils (aplay)"
            exit 1
        fi
    else
        echo -e "${RED}Error: Unsupported OS: $OSTYPE${NC}"
        exit 1
    fi
}

# Check for jq
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        echo ""
        echo "Install jq:"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  brew install jq"
        else
            echo "  sudo apt install jq    # Debian/Ubuntu"
            echo "  sudo dnf install jq    # Fedora"
            echo "  sudo pacman -S jq      # Arch"
        fi
        exit 1
    fi
}

# Copy sound files
copy_sounds() {
    echo ""
    echo "Copying sound files..."

    mkdir -p "$SOUNDS_DIR"

    # Copy all sound files and directories
    cp -r "$SCRIPT_DIR/sounds/"* "$SOUNDS_DIR/"

    echo -e "${GREEN}Sound files copied to $SOUNDS_DIR${NC}"
}

# Generate hooks config with correct player
generate_hooks() {
    # Read hooks.json and replace {{PLAYER}} with actual player
    sed "s/{{PLAYER}}/$PLAYER/g" "$SCRIPT_DIR/hooks.json"
}

# Merge hooks into settings.json
merge_settings() {
    echo ""
    echo "Merging hooks into settings..."

    mkdir -p "$CLAUDE_DIR"

    # Generate hooks config with correct player
    HOOKS_CONFIG=$(generate_hooks)

    if [ -f "$SETTINGS_FILE" ]; then
        # Backup existing settings
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
        echo -e "${YELLOW}Backed up existing settings to $SETTINGS_FILE.backup${NC}"

        # Merge hooks into existing settings
        EXISTING=$(cat "$SETTINGS_FILE")

        # Extract hooks from our config
        NEW_HOOKS=$(echo "$HOOKS_CONFIG" | jq '.hooks')

        # Merge: existing settings + new hooks (hooks will be overwritten)
        echo "$EXISTING" | jq --argjson hooks "$NEW_HOOKS" '.hooks = $hooks' > "$SETTINGS_FILE"
    else
        # No existing settings, just use our hooks config
        echo "$HOOKS_CONFIG" > "$SETTINGS_FILE"
    fi

    echo -e "${GREEN}Hooks merged into $SETTINGS_FILE${NC}"
}

# Main installation
main() {
    detect_player
    check_jq
    copy_sounds
    merge_settings

    echo ""
    echo "=========================================="
    echo -e "${GREEN}Installation complete!${NC}"
    echo "=========================================="
    echo ""
    echo "Start a new Claude Code session to hear the SCV sounds."
    echo ""
    echo "Hook events:"
    echo "  - Session start:  'SCV reportin' for duty'"
    echo "  - Prompt submit:  'Affirmative', 'Roger that', etc."
    echo "  - File read:      Mining sound"
    echo "  - File write:     Work sounds"
    echo "  - Bash error:     'Nuclear launch detected'"
    echo "  - Notifications:  'Orders, captain?'"
    echo "  - Session end:    'Job's finished'"
    echo ""
}

main
