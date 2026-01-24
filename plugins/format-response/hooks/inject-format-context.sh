#!/bin/bash
# inject-format-context.sh
# UserPromptSubmit hook: Inject terminal width and formatting rules

# Get terminal width
COLS=$(tput cols 2>/dev/null || echo "80")

# Determine format mode based on width
if [ "$COLS" -ge 120 ]; then
    FORMAT_MODE="wide"
    TABLE_MODE="full tables"
    CODE_WRAP="no wrap needed"
elif [ "$COLS" -ge 80 ]; then
    FORMAT_MODE="standard"
    TABLE_MODE="condensed tables"
    CODE_WRAP="wrap at $COLS chars"
else
    FORMAT_MODE="narrow"
    TABLE_MODE="use lists instead of tables"
    CODE_WRAP="wrap at $COLS chars, minimal indent"
fi

# Output context for Claude (will be injected into conversation)
cat << EOF
<terminal-format-context>
Terminal width: ${COLS} columns (${FORMAT_MODE} mode)
Formatting rules:
- Tables: ${TABLE_MODE}
- Code blocks: ${CODE_WRAP}
- Long paths: truncate middle with ... if > $((COLS - 20)) chars
- Lists: inline if <=5 items, vertical if >5
</terminal-format-context>
EOF
