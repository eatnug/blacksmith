---
name: format-response
description: Format responses based on terminal width. Hook automatically injects context - no manual invocation needed.
user_invocable: false
---

# Format Response

이 플러그인은 `UserPromptSubmit` 훅을 통해 자동으로 동작합니다.

## 동작 방식

1. 사용자가 프롬프트를 입력하면 `inject-format-context.sh` 훅이 실행됨
2. 훅이 터미널 너비를 확인하고 `<terminal-format-context>` 태그로 컨텍스트 주입
3. Claude가 해당 컨텍스트를 보고 응답을 포맷팅

## 포맷팅 규칙

터미널 너비에 따라 자동 적용:

| 너비 | 모드 | 테이블 | 코드 |
|------|------|--------|------|
| 120+ | wide | 전체 표시 | 줄바꿈 불필요 |
| 80-119 | standard | 축약 | 너비에 맞게 줄바꿈 |
| <80 | narrow | 리스트로 전환 | 최소 들여쓰기 |

## 사용자 선호 (오버라이드)

사용자가 형식을 지정하면 터미널 설정보다 우선:
- "json으로" → JSON 출력
- "간단하게" → 핵심만
- "자세히" → 상세 포함
- "테이블로" → 테이블 형식
