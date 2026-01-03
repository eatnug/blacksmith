---
description: Initialize Siat workflow in the current project
---

# Initialize Siat

Set up the Siat workflow structure in this project.

## Steps

1. **Check if already initialized**
   - If `.claude/siat/` exists, ask if user wants to reset

2. **Create directory structure**
   ```
   .claude/siat/
   ├── config.yml
   └── steps/
       ├── plan/
       │   ├── instruction.md
       │   └── spec.md
       └── implement/
           ├── instruction.md
           └── spec.md
   ```

3. **Create config.yml**
   ```yaml
   workflow:
     name: "default"
     description: "기본 워크플로우: plan → implement"

   steps:
     - plan
     - implement

   runtime:
     model: "sonnet"
   ```

4. **Create plan step files**

   `steps/plan/instruction.md`:
   ```markdown
   ---
   name: plan
   description: 요청사항을 분석하고 구현 계획 수립

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
   결과는 spec.md 템플릿 형식에 맞춰 작성하세요.
   ```

   `steps/plan/spec.md`:
   ```markdown
   # Plan: {{title}}

   ## 요약

   ## 배경

   ## 목표

   ## 접근 방법

   ## 변경할 파일

   | 파일 | 변경 내용 |
   |------|----------|

   ## 주의사항
   ```

5. **Create implement step files**

   `steps/implement/instruction.md`:
   ```markdown
   ---
   name: implement
   description: 계획에 따라 코드 구현

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
   ```

   `steps/implement/spec.md`:
   ```markdown
   # Implementation: {{title}}

   ## 요약

   ## 변경 내역

   ### 수정된 파일

   | 파일 | 변경 내용 |
   |------|----------|

   ## 테스트 결과
   ```

6. **Confirm completion**
   ```
   Siat이 초기화되었습니다!

   사용법:
   - /siat:do <요청> - 워크플로우 시작
   - /siat:do plan <요청> - plan 단계만 실행
   - /siat:do implement - implement 단계 실행

   커스텀:
   - .claude/siat/config.yml - 워크플로우 설정
   - .claude/siat/steps/ - 스텝 추가/수정
   ```
