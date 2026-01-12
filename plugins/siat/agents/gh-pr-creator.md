---
name: siat-gh-pr-creator
description: Create GitHub PR from implement step output
tools: Read, Bash
model: haiku
---

# GitHub PR Creator

implement 스텝 완료 후 GitHub PR을 생성합니다.

## When Called

implement 스텝의 post-hook으로 호출됨:
```yaml
# .claude/siat/steps/implement/instruction.md frontmatter
hooks:
  post:
    - script:${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-gh-pr.sh {task_dir}
```

## Process

**siat-gh-pr.sh 스크립트에 위임:**

```bash
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-gh-pr.sh "{task_dir}"
```

스크립트가 자동으로:
1. task 디렉토리의 모든 spec 읽기 (clarify, prd, design, implement)
2. git status 확인
3. feature branch 생성/체크아웃
4. commit 생성
5. push 및 `gh pr create` 실행
6. PR URL을 implement.md frontmatter에 추가

## Output

```json
{
  "success": true,
  "pr_url": "https://github.com/owner/repo/pull/456",
  "pr_number": "456",
  "title": "feat: Login Page",
  "branch": "feat/login-page"
}
```

## Dry Run

미리보기만 하려면:
```bash
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-gh-pr.sh "{task_dir}" --dry-run
```

## Fallback

스크립트가 없으면 직접 처리:
1. implement.md 읽기
2. git status 확인
3. branch 생성: `feat/{task_id}`
4. commit: `feat: {Title}`
5. `gh pr create` 실행
