#!/bin/bash
TOGGLE="$HOME/.claude/hooks-enabled"
if [ -f "$TOGGLE" ]; then
  rm "$TOGGLE"
  echo "Hooks off."
else
  touch "$TOGGLE"
  echo "Hooks on."
fi
