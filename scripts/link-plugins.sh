#!/bin/bash
# plugins/ 하위의 skills, commands를 .claude/로 심링크

cd "$(dirname "$0")/.." || exit 1

mkdir -p .claude/skills .claude/commands

for plugin in plugins/*/; do
  [ -d "$plugin" ] || continue
  name=$(basename "$plugin")

  # skills 심링크
  if [ -d "$plugin/skills" ]; then
    for skill in "$plugin/skills"/*/; do
      [ -d "$skill" ] || continue
      skill_name=$(basename "$skill")
      target=".claude/skills/$skill_name"
      if [ ! -L "$target" ]; then
        rm -rf "$target"
        ln -s "../../plugins/$name/skills/$skill_name" "$target"
      fi
    done
  fi

  # commands 심링크
  if [ -d "$plugin/commands" ]; then
    for cmd in "$plugin/commands"/*.md; do
      [ -f "$cmd" ] || continue
      cmd_name=$(basename "$cmd")
      target=".claude/commands/$cmd_name"
      if [ ! -L "$target" ]; then
        rm -f "$target"
        ln -s "../../plugins/$name/commands/$cmd_name" "$target"
      fi
    done
  fi
done
