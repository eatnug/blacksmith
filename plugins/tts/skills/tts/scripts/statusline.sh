#!/usr/bin/env bash

# Read JSON input from stdin
input=$(cat)

# Extract values
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model_name=$(echo "$input" | jq -r '.model.display_name')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# Extract token information
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

# Simple color codes
CYAN="\e[96m"
BLUE="\e[94m"
GREEN="\e[92m"
YELLOW="\e[93m"
ORANGE="\e[38;5;208m"
DIM="\e[2m"
RESET="\e[0m"

# Helper function to format tokens
format_tokens() {
  local tokens=$1
  if [ "$tokens" -ge 1000 ]; then
    echo "$((tokens / 1000))K"
  else
    echo "$tokens"
  fi
}

# 1. Directory - with folder icon
short_dir=$(basename "$cwd")
if [ ${#short_dir} -gt 18 ]; then
  short_dir="${short_dir:0:15}..."
fi
dir_info="📁 ${CYAN}${short_dir}${RESET}"

# 2. Git branch - with branch icon and Powerlevel10k-style status
git_info=""
if git -C "$cwd" --no-optional-locks rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi

  if [ -n "$branch" ]; then
    # Truncate branch if too long
    if [ ${#branch} -gt 18 ]; then
      branch="${branch:0:15}..."
    fi

    # Get git status information (like Powerlevel10k)
    status_indicators=""

    # Count untracked files - CYAN
    untracked=$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    if [ "$untracked" -gt 0 ]; then
      status_indicators="${status_indicators}${CYAN}?${untracked}${RESET}"
    fi

    # Count unstaged files (modified) - YELLOW
    unstaged=$(git -C "$cwd" --no-optional-locks diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    if [ "$unstaged" -gt 0 ]; then
      [ -n "$status_indicators" ] && status_indicators="${status_indicators} "
      status_indicators="${status_indicators}${YELLOW}!${unstaged}${RESET}"
    fi

    # Count staged files - GREEN
    staged=$(git -C "$cwd" --no-optional-locks diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    if [ "$staged" -gt 0 ]; then
      [ -n "$status_indicators" ] && status_indicators="${status_indicators} "
      status_indicators="${status_indicators}${GREEN}+${staged}${RESET}"
    fi

    # Check ahead/behind
    upstream=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    if [ -n "$upstream" ]; then
      ahead=$(git -C "$cwd" --no-optional-locks rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
      behind=$(git -C "$cwd" --no-optional-locks rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")

      if [ "$ahead" -gt 0 ]; then
        [ -n "$status_indicators" ] && status_indicators="${status_indicators} "
        status_indicators="${status_indicators}${BLUE}↑${ahead}${RESET}"
      fi

      if [ "$behind" -gt 0 ]; then
        [ -n "$status_indicators" ] && status_indicators="${status_indicators} "
        status_indicators="${status_indicators}${ORANGE}↓${behind}${RESET}"
      fi
    fi

    # Color based on status
    if [ -n "$status_indicators" ]; then
      branch_color="${YELLOW}"
    else
      branch_color="${GREEN}"
    fi

    git_info="  ${branch_color}${branch}${RESET}"

    # Add status indicators if any
    if [ -n "$status_indicators" ]; then
      git_info="${git_info} ${DIM}[${status_indicators}]${RESET}"
    fi
  fi
fi

# 3. Model - with sparkles icon
model_info=""
if [ -n "$model_name" ]; then
  case "$model_name" in
    *"Opus"*) short_model="Opus" ;;
    *"Sonnet"*) short_model="Sonnet" ;;
    *"Haiku"*) short_model="Haiku" ;;
    *) short_model="Claude" ;;
  esac
  model_info=" ✨ ${BLUE}${short_model}${RESET}"
fi

# 4. Tokens - with battery icon
token_info=""
if [ "$context_size" -gt 0 ]; then
  total_used=$((total_input + total_output))
  total_remaining=$((context_size - total_used))

  remaining_fmt=$(format_tokens "$total_remaining")

  # Calculate percentage for color
  remaining_pct=$(echo "scale=0; ($total_remaining * 100) / $context_size" | bc)

  if [ "$remaining_pct" -ge 70 ]; then
    color="${GREEN}"
  elif [ "$remaining_pct" -ge 40 ]; then
    color="${YELLOW}"
  else
    color="${ORANGE}"
  fi

  token_info=" 🔋 ${color}${remaining_fmt}${RESET}"
fi

# 5. Session ID - with ID icon (full session ID)
session_info=""
if [ -n "$session_id" ]; then
  session_info=" 🆔 ${DIM}${session_id}${RESET}"
fi

# 6. Hooks status (single toggle)
hooks_info=""
if [ -f "$HOME/.claude/hooks-enabled" ]; then
  hooks_info=" 🔔${GREEN}on${RESET}"
else
  hooks_info=" 🔔${DIM}off${RESET}"
fi

# Combine with icons as visual separators - clean and easy to read
printf "%b%b%b%b%b%b\n" "$dir_info" "$git_info" "$model_info" "$token_info" "$hooks_info" "$session_info"
