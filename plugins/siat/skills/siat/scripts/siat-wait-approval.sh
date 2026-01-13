#!/bin/bash
# siat-wait-approval.sh - Wait for approval via GitHub Issue comment
# Posts result to GitHub Issue and polls for /approve or /feedback response
#
# Usage: siat-wait-approval.sh <spec_path> [--poll-interval=10] [--timeout=3600]
# Output: JSON with approval result
#
# Expected GitHub Issue comment commands:
#   /approve              - Proceed to next step
#   /approve with comment - Proceed with note
#   /feedback: message    - Retry with feedback
#   /reject               - Stop workflow

set -e

# Parse arguments
SPEC_PATH=""
POLL_INTERVAL=10
TIMEOUT=3600  # 1 hour default

for arg in "$@"; do
    case $arg in
        --poll-interval=*) POLL_INTERVAL="${arg#*=}" ;;
        --timeout=*) TIMEOUT="${arg#*=}" ;;
        *) [[ -z "$SPEC_PATH" ]] && SPEC_PATH="$arg" ;;
    esac
done

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

# Get issue or PR URL from spec frontmatter (PR also uses issue comments API)
ISSUE_URL=$(get_frontmatter_field "$SPEC_PATH" "github_issue")
PR_URL=$(get_frontmatter_field "$SPEC_PATH" "github_pr")

if [[ -n "$PR_URL" ]]; then
    TARGET_URL="$PR_URL"
    TARGET_TYPE="pr"
elif [[ -n "$ISSUE_URL" ]]; then
    TARGET_URL="$ISSUE_URL"
    TARGET_TYPE="issue"
else
    echo '{"error": "no github_issue or github_pr found in spec frontmatter", "path": "'"$SPEC_PATH"'"}' | jq .
    exit 1
fi

ISSUE_NUMBER=$(extract_issue_number "$TARGET_URL")
TASK_ID=$(get_frontmatter_field "$SPEC_PATH" "id")
STEP=$(basename "$SPEC_PATH" .md)

# Post approval request comment
APPROVAL_MSG="## ⏳ Awaiting Approval

**Step**: \`${STEP}\`
**Task**: \`${TASK_ID}\`

Please review and respond with one of:

| Command | Action |
|---------|--------|
| \`/approve\` | Proceed to next step |
| \`/feedback: your message\` | Retry with feedback |
| \`/reject\` | Stop workflow |

---
*Waiting for response...*"

# Post comment and get the URL
if ! COMMENT_RESULT=$(gh issue comment "$ISSUE_NUMBER" --body "$APPROVAL_MSG" 2>&1); then
    echo '{"error": "failed to post comment", "details": "'"$COMMENT_RESULT"'"}' | jq .
    exit 1
fi

# Extract comment ID from URL (format: https://github.com/owner/repo/issues/N#issuecomment-ID)
OUR_COMMENT_ID=$(echo "$COMMENT_RESULT" | grep -oE 'issuecomment-[0-9]+' | grep -oE '[0-9]+')

if [[ -z "$OUR_COMMENT_ID" ]]; then
    echo '{"error": "failed to get comment ID", "result": "'"$COMMENT_RESULT"'"}' | jq .
    exit 1
fi

echo "Posted awaiting approval comment (ID: $OUR_COMMENT_ID)" >&2
echo "Waiting for approval on issue #${ISSUE_NUMBER}..." >&2

ELAPSED=0

while [[ $ELAPSED -lt $TIMEOUT ]]; do
    sleep "$POLL_INTERVAL"
    ELAPSED=$((ELAPSED + POLL_INTERVAL))

    # Get all comments and find ones after ours
    LATEST=$(gh api "repos/{owner}/{repo}/issues/${ISSUE_NUMBER}/comments" \
        --jq "[.[] | select(.id > $OUR_COMMENT_ID)] | .[-1] // empty | {id: .id, body: .body, user: .user.login}" \
        2>/dev/null)

    # No new comments
    if [[ -z "$LATEST" || "$LATEST" == "null" ]]; then
        echo "Still waiting... (${ELAPSED}s / ${TIMEOUT}s)" >&2
        continue
    fi

    BODY=$(echo "$LATEST" | jq -r '.body' 2>/dev/null)
    USER=$(echo "$LATEST" | jq -r '.user' 2>/dev/null)

    echo "New comment detected from $USER: ${BODY:0:50}..." >&2

    # Check for approval
    if echo "$BODY" | grep -qi "^/approve"; then
        NOTE=$(echo "$BODY" | sed 's|^/approve[[:space:]]*||i')

        # Post acknowledgment and close issue
        gh issue comment "$ISSUE_NUMBER" --body "✅ **Approved** by @${USER}. Proceeding to next step." >/dev/null 2>&1
        gh issue close "$ISSUE_NUMBER" >/dev/null 2>&1

        jq -n \
            --arg action "approve" \
            --arg user "$USER" \
            --arg note "$NOTE" \
            --arg spec_path "$SPEC_PATH" \
            --arg issue_number "$ISSUE_NUMBER" \
            '{
                success: true,
                action: $action,
                user: $user,
                note: $note,
                spec_path: $spec_path,
                issue_number: $issue_number
            }'
        exit 0
    fi

    # Check for feedback
    if echo "$BODY" | grep -qi "^/feedback:"; then
        FEEDBACK=$(echo "$BODY" | sed 's|^/feedback:[[:space:]]*||i')

        # Post acknowledgment
        gh issue comment "$ISSUE_NUMBER" --body "🔄 **Feedback received** from @${USER}. Retrying step with feedback." >/dev/null 2>&1

        jq -n \
            --arg action "feedback" \
            --arg user "$USER" \
            --arg feedback "$FEEDBACK" \
            --arg spec_path "$SPEC_PATH" \
            --arg issue_number "$ISSUE_NUMBER" \
            '{
                success: true,
                action: $action,
                user: $user,
                feedback: $feedback,
                spec_path: $spec_path,
                issue_number: $issue_number
            }'
        exit 0
    fi

    # Check for reject
    if echo "$BODY" | grep -qi "^/reject"; then
        REASON=$(echo "$BODY" | sed 's|^/reject[[:space:]]*||i')

        # Post acknowledgment
        gh issue comment "$ISSUE_NUMBER" --body "❌ **Rejected** by @${USER}. Workflow stopped." >/dev/null 2>&1

        jq -n \
            --arg action "reject" \
            --arg user "$USER" \
            --arg reason "$REASON" \
            --arg spec_path "$SPEC_PATH" \
            --arg issue_number "$ISSUE_NUMBER" \
            '{
                success: true,
                action: $action,
                user: $user,
                reason: $reason,
                spec_path: $spec_path,
                issue_number: $issue_number
            }'
        exit 0
    fi

    # Unknown command, keep waiting
    echo "Unknown command, still waiting... (${ELAPSED}s / ${TIMEOUT}s)" >&2
done

# Timeout
gh issue comment "$ISSUE_NUMBER" --body "⏰ **Timeout** - No response received within ${TIMEOUT}s. Workflow paused." >/dev/null 2>&1

jq -n \
    --arg spec_path "$SPEC_PATH" \
    --arg issue_number "$ISSUE_NUMBER" \
    --argjson timeout "$TIMEOUT" \
    '{
        success: false,
        action: "timeout",
        timeout_seconds: $timeout,
        spec_path: $spec_path,
        issue_number: $issue_number
    }'
exit 1
