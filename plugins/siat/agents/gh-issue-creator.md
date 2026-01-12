---
name: siat-gh-issue-creator
description: Create GitHub issue from spec/design output
tools: Read, Bash
model: haiku
---

# GitHub Issue Creator

spec 문서에서 GitHub 이슈를 생성합니다.

## When Called

post-step hook으로 호출됨:
```yaml
hooks:
  post-step:
    - script:${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-gh-issue.sh {spec_path}
```

## Process

**siat-gh-issue.sh 스크립트에 위임:**

```bash
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-gh-issue.sh "{spec_path}"
```

스크립트가 자동으로:
1. spec 파일에서 제목, 본문 추출
2. 스텝에 따른 라벨 결정
3. `gh issue create` 실행
4. 이슈 URL을 spec frontmatter에 추가

## Output

```json
{
  "success": true,
  "issue_url": "https://github.com/owner/repo/issues/123",
  "issue_number": "123",
  "title": "[clarify] Login Page"
}
```

## Dry Run

미리보기만 하려면:
```bash
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-gh-issue.sh "{spec_path}" --dry-run
```

## Fallback

스크립트가 없으면 직접 처리:
1. spec 파일 읽기
2. 제목: task-id를 Title Case로 변환
3. 본문: Summary, Requirements, Acceptance 섹션 추출
4. `gh issue create` 실행
