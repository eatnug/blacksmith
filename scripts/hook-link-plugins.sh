#!/bin/bash
# PostToolUse hook: plugins/ 에 새 skill/command 생성 시 심링크 동기화

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# plugins/*/skills/* 또는 plugins/*/commands/*.md 패턴만
if [[ ! "$file_path" =~ plugins/[^/]+/skills/ ]] && [[ ! "$file_path" =~ plugins/[^/]+/commands/.*\.md$ ]]; then
  exit 0
fi

# 심링크 동기화 실행
"$(dirname "$0")/link-plugins.sh"
