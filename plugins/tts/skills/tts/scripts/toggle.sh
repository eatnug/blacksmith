#!/bin/bash
TOGGLE="$HOME/.claude/hooks-enabled"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATUSLINE="$SCRIPT_DIR/statusline.sh"

if [ -f "$TOGGLE" ]; then
  rm "$TOGGLE"
  # Remove statusline command from settings
  if [ -f "$SETTINGS" ]; then
    jq 'del(.statusLine)' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  fi
  echo "TTS off. Statusline removed."
else
  touch "$TOGGLE"
  # Configure statusline command in settings
  if [ -f "$SETTINGS" ]; then
    jq --arg cmd "$STATUSLINE" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  fi
  echo "TTS on. Statusline set to: $STATUSLINE"
fi
