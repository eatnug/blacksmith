#!/bin/bash
# Notification hook: Glass sound + red blink until pane is focused

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

[ ! -f "$HOME/.claude/hooks-enabled" ] && exit 0

# Find pane's TTY
PID=$PPID
TTY=""
while [ "$PID" -gt 1 ] 2>/dev/null; do
  T=$(ps -p "$PID" -o tty= 2>/dev/null | tr -d ' ')
  if [ -n "$T" ] && [ "$T" != "??" ]; then
    TTY="/dev/$T"
    break
  fi
  PID=$(ps -p "$PID" -o ppid= 2>/dev/null | tr -d ' ')
done
[ -z "$TTY" ] && exit 0

# Kill any previous blink loop
STATE_DIR="/tmp/claude-tts"
mkdir -p "$STATE_DIR"
BLINK_PIDFILE="$STATE_DIR/blink-pid"
if [ -f "$BLINK_PIDFILE" ]; then
  OLD_PID=$(cat "$BLINK_PIDFILE" 2>/dev/null)
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID" 2>/dev/null
  fi
  rm -f "$BLINK_PIDFILE"
fi
printf '\e]111\a' > "$TTY" 2>/dev/null

# Glass sound
afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &

# Red blink until pane is focused
(
  while true; do
    printf '\e]11;#3a1a1a\a' > "$TTY"
    sleep 0.25
    printf '\e]111\a' > "$TTY"
    sleep 0.25
    "$SCRIPT_DIR/is-focused.sh" "$TTY" && break
  done
  printf '\e]111\a' > "$TTY" 2>/dev/null
  rm -f "$BLINK_PIDFILE"
) &
echo $! > "$BLINK_PIDFILE"

exit 0
