#!/bin/bash
# 3-state toggle: OFF → NOTIFY → NOTIFY+TTS → OFF
HOOKS_TOGGLE="$HOME/.claude/hooks-enabled"
TTS_TOGGLE="$HOME/.claude/tts-enabled"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATUSLINE="$SCRIPT_DIR/statusline.sh"

if [ -f "$TTS_TOGGLE" ]; then
  # NOTIFY+TTS → OFF: remove both files, remove statusline
  rm -f "$TTS_TOGGLE" "$HOOKS_TOGGLE"
  if [ -f "$SETTINGS" ]; then
    jq 'del(.statusLine)' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  fi
  echo "Notifications off. Statusline removed."
elif [ -f "$HOOKS_TOGGLE" ]; then
  # NOTIFY → NOTIFY+TTS: add tts-enabled
  touch "$TTS_TOGGLE"
  echo "Notify + TTS on."
else
  # OFF → NOTIFY: create hooks-enabled, set statusline
  touch "$HOOKS_TOGGLE"
  if [ -f "$SETTINGS" ]; then
    jq --arg cmd "$STATUSLINE" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  fi
  echo "Notify on. Statusline set."
fi
