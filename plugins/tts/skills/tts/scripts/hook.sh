#!/bin/bash
# Stop hook: orange blink (summarizing) → green blink (ready) → TTS on focus

# Recursion guard: walk process tree — if any ancestor is claude -p, exit
P=$PPID
while [ "$P" -gt 1 ] 2>/dev/null; do
  CMD=$(ps -p "$P" -o args= 2>/dev/null)
  case "$CMD" in *claude\ -p*) exit 0 ;; esac
  P=$(ps -p "$P" -o ppid= 2>/dev/null | tr -d ' ')
done

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

# Kill leftover background process from previous run
STATE_DIR="/tmp/claude-tts"
mkdir -p "$STATE_DIR"
PIDFILE="$STATE_DIR/pid"
if [ -f "$PIDFILE" ]; then
  OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    kill -- -"$OLD_PID" 2>/dev/null || kill "$OLD_PID" 2>/dev/null
  fi
  rm -f "$PIDFILE"
fi
printf '\e]111\a' > "$TTY" 2>/dev/null

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
[ -z "$TRANSCRIPT" ] && exit 0

read_response() {
  jq -rs '
    [.[] | select(.type == "assistant") |
      select(.message.content | map(select(.type == "text")) | length > 0) |
      {
        text: ([.message.content[] | select(.type == "text") | .text] | join("\n")),
        has_tool: ([.message.content[] | select(.type == "tool_use")] | length > 0)
      }
    ] as $msgs |
    # Priority 1: last pure-text response (no tool calls) — the actual final answer
    ($msgs | map(select((.has_tool | not) and (.text | length > 20))) | last | .text // null) //
    # Priority 2: last response with substantial text (even if mixed with tool calls)
    ($msgs | map(select(.text | length > 80)) | last | .text // null) //
    # Fallback: last response text
    ($msgs | last | .text // "")
  ' "$TRANSCRIPT" 2>/dev/null
}

(
  SUMMARY_FILE="$STATE_DIR/summary.$$.txt"

  afplay /System/Library/Sounds/Ping.aiff 2>/dev/null &

  (
    # Brief wait for transcript flush, then read
    sleep 1
    RESPONSE=$(read_response)
    if [ -n "$RESPONSE" ]; then
      TRUNCATED=$(echo "$RESPONSE" | head -c 3000)
      SUMMARY=$(printf '<response>\n%s\n</response>' "$TRUNCATED" | claude -p --model claude-haiku-4-5-20251001 \
        --system-prompt "You are a TTS narrator. The user pipes Claude Code's response in <response> tags. Convert it into 1-3 short spoken sentences. Rules: no markdown, no lists, no special characters, no self-introduction. Match the language. Just say what happened." \
        --tools "" \
        "Narrate what was done in 1-3 plain spoken sentences." 2>/dev/null) || true
      [ -z "$SUMMARY" ] && SUMMARY=$(echo "$RESPONSE" | head -c 200)
      echo "$SUMMARY" > "$SUMMARY_FILE"
    fi
  ) &
  SUMMARY_PID=$!

  while kill -0 "$SUMMARY_PID" 2>/dev/null; do
    printf '\e]11;#3a2a15\a' > "$TTY"
    sleep 0.25
    printf '\e]111\a' > "$TTY"
    sleep 0.25
  done
  printf '\e]111\a' > "$TTY" 2>/dev/null
  wait "$SUMMARY_PID"

  [ ! -f "$SUMMARY_FILE" ] && exit 0

  while true; do
    ACTIVE_TTY=$(osascript -e 'tell application "iTerm2" to tell current window to tell current tab to get tty of current session' 2>/dev/null)
    [ "$ACTIVE_TTY" = "$TTY" ] && break
    printf '\e]11;#1a3a1a\a' > "$TTY"
    sleep 0.25
    printf '\e]111\a' > "$TTY"
    sleep 0.25
  done
  printf '\e]111\a' > "$TTY" 2>/dev/null

  SUMMARY=$(cat "$SUMMARY_FILE")
  rm -f "$SUMMARY_FILE" "$PIDFILE"
  if python3 -c "import sys; sys.exit(0 if any('\uAC00' <= c <= '\uD7AF' for c in sys.stdin.read()) else 1)" <<< "$SUMMARY" 2>/dev/null; then
    say -v Yuna "$SUMMARY"
  else
    say "$SUMMARY"
  fi
) &
echo $! > "$PIDFILE"

exit 0
