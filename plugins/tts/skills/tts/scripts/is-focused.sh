#!/bin/bash
# Check if the pane for the given TTY is focused.
# Layered detection: tmux pane → tmux window → iTerm2 osascript
# Exit 0 = focused, Exit 1 = not focused

TTY="$1"
[ -z "$TTY" ] && exit 1

# Level 1 & 2: tmux-based detection
if [ -n "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
  PANE_ID=$(tmux list-panes -a -F '#{pane_tty} #{pane_id}' 2>/dev/null | awk -v tty="$TTY" '$1 == tty { print $2; exit }')
  if [ -n "$PANE_ID" ]; then
    # Level 1: Is this exact pane the active one?
    PANE_ACTIVE=$(tmux display-message -p -t "$PANE_ID" '#{pane_active}' 2>/dev/null)
    [ "$PANE_ACTIVE" = "1" ] && exit 0

    # Level 2: Is the window containing this pane the active window?
    WINDOW_ACTIVE=$(tmux display-message -p -t "$PANE_ID" '#{window_active}' 2>/dev/null)
    [ "$WINDOW_ACTIVE" = "1" ] && exit 0

    exit 1
  fi
fi

# Level 3: iTerm2 osascript fallback
ACTIVE_TTY=$(osascript -e 'tell application "iTerm2" to tell current window to tell current tab to get tty of current session' 2>/dev/null)
[ "$ACTIVE_TTY" = "$TTY" ] && exit 0

exit 1
