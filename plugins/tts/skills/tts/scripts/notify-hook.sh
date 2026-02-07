#!/bin/bash
# Notification hook: Glass sound + red blink x3 on permission prompts / questions

INPUT=$(cat)

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

# Glass sound
afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &

# Red blink x3
for i in 1 2 3; do
  printf '\e]11;#3a1a1a\a' > "$TTY"
  sleep 0.25
  printf '\e]111\a' > "$TTY"
  sleep 0.25
done

exit 0
