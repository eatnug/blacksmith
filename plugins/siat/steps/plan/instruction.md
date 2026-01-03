---
name: plan
description: 요청사항을 분석하고 구현 계획 수립

# GitHub Issue에서 입력 받기 (선택)
# input:
#   type: "github-issue"
#   fields: [title, body, labels]
#   fallback: "manual"

# 추가 출력: Issue에 코멘트 (선택)
# output:
#   type: "file"
#   also:
#     - type: "github-issue-comment"
#       template: |
#         ## 📋 Plan Created
#         구현 계획이 작성되었습니다.

inputs:
  - 무엇을 만들어야 하는지 (요청사항)
  - 왜 만들어야 하는지 (목적, 배경)
  - 제약조건이나 요구사항이 있다면 무엇인지

outputs:
  - 어떤 접근법으로 구현할지
  - 어떤 파일들을 수정/생성할지
  - 예상되는 리스크나 주의사항

approval:
  required: true
---

# Plan

요청사항을 분석하고 구현 계획을 세워주세요.

## GitHub Issue 입력 시

`input.type: "github-issue"`가 설정되어 있고 Issue 번호가 제공되면:
1. `gh issue view {number} --json title,body,labels` 실행
2. Issue 내용을 분석하여 요청사항 파악
3. `.task.yml`에 issue_number 저장 (PR 링크용)
