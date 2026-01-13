#!/bin/bash
# siat-gh-issue-close.sh - Close GitHub issue after approval
#
# Usage: siat-gh-issue-close.sh <spec_path>
# Output: JSON with close result

set -e

SPEC_PATH="$1"

# ============================================================================
# Helper Functions
# ============================================================================

get_frontmatter_field() {
    local file="$1"
    local field="$2"

    awk -v field="$field" '
        /^---$/ { if (in_fm) exit; in_fm=1; next }
        in_fm && $0 ~ "^"field":" {
            gsub(/^[^:]+:[[:space:]]*/, "")
            gsub(/^"/, ""); gsub(/"$/, "")
            print
            exit
        }
    ' "$file"
}

extract_issue_number() {
    echo "$1" | grep -oE '[0-9]+$'
}

# ============================================================================
# Main Logic
# ============================================================================

if [[ ! -f "$SPEC_PATH" ]]; then
    echo '{"error": "spec file not found", "path": "'"$SPEC_PATH"'"}' | jq .
    exit 1
fi

ISSUE_URL=$(get_frontmatter_field "$SPEC_PATH" "github_issue")

if [[ -z "$ISSUE_URL" ]]; then
    echo '{"skipped": true, "reason": "no github_issue found in frontmatter", "path": "'"$SPEC_PATH"'"}' | jq .
    exit 0
fi

ISSUE_NUMBER=$(extract_issue_number "$ISSUE_URL")
TASK_ID=$(get_frontmatter_field "$SPEC_PATH" "id")
STEP=$(basename "$SPEC_PATH" .md)

# Close the issue with a comment
CLOSE_MSG="✅ **Approved**

Step \`${STEP}\` has been approved and completed.

---
*Closed by siat workflow*"

gh issue comment "$ISSUE_NUMBER" --body "$CLOSE_MSG" >/dev/null 2>&1 || true
gh issue close "$ISSUE_NUMBER" >/dev/null 2>&1 || {
    echo '{"error": "failed to close issue", "issue_number": "'"$ISSUE_NUMBER"'"}' | jq .
    exit 1
}

jq -n \
    --arg issue_url "$ISSUE_URL" \
    --arg issue_number "$ISSUE_NUMBER" \
    --arg task_id "$TASK_ID" \
    --arg step "$STEP" \
    --arg spec_path "$SPEC_PATH" \
    '{
        success: true,
        message: "Issue closed",
        issue_url: $issue_url,
        issue_number: $issue_number,
        task_id: $task_id,
        step: $step,
        spec_path: $spec_path
    }'
