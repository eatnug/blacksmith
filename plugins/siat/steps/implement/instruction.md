---
name: implement
description: 계획에 따라 코드 구현

# 이전 스텝 결과 읽기
input:
  type: "file"
  source: "plan"

# PR 생성 (선택)
# output:
#   type: "github-pr"
#   title: "{{context.github.issue_title}}"
#   draft: true
#   link_issue: true  # Fixes #N 자동 추가

inputs:
  - 승인된 구현 계획 (plan 단계의 결과물)
  - 변경할 파일 목록

outputs:
  - 계획대로 코드 변경 완료
  - 기존 테스트 통과

approval:
  required: false
---

# Implement

승인된 계획에 따라 코드를 구현해주세요.
계획에 없는 변경은 하지 마세요.

## PR 생성 시

`output.type: "github-pr"`가 설정되어 있으면 구현 완료 후:
1. 변경사항 커밋
2. 브랜치 push
3. `gh pr create` 실행
   - `.task.yml`에 issue_number가 있으면 `Fixes #N` 추가
   - `draft: true`면 드래프트 PR로 생성
