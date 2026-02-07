#!/bin/bash
# 3-state toggle: OFF → NOTIFY → NOTIFY+TTS → OFF
HOOKS_TOGGLE="$HOME/.claude/hooks-enabled"
TTS_TOGGLE="$HOME/.claude/tts-enabled"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATUSLINE_SRC="$SCRIPT_DIR/statusline.sh"
STATUSLINE_DEST="$HOME/.claude/statusline-command.sh"

# Ensure statusline is always installed
ensure_statusline() {
  cp "$STATUSLINE_SRC" "$STATUSLINE_DEST"
  chmod +x "$STATUSLINE_DEST"
  if [ -f "$SETTINGS" ]; then
    current=$(jq -r '.statusLine.command // empty' "$SETTINGS")
    if [ "$current" != "$STATUSLINE_DEST" ]; then
      jq --arg cmd "$STATUSLINE_DEST" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    fi
  fi
}

ensure_statusline

if [ -f "$TTS_TOGGLE" ]; then
  # NOTIFY+TTS → OFF
  rm -f "$TTS_TOGGLE" "$HOOKS_TOGGLE"
  echo "Notifications off."
elif [ -f "$HOOKS_TOGGLE" ]; then
  # NOTIFY → NOTIFY+TTS
  touch "$TTS_TOGGLE"
  echo "Notify + TTS on."
else
  # OFF → NOTIFY
  touch "$HOOKS_TOGGLE"
  echo "Notify on."
fi
