---
name: format-response
description: Format all responses according to terminal width and template rules. Use automatically on EVERY response before answering the user. Check terminal width first, then apply formatting rules from template.md to ensure consistent, readable output.
---

# Format Response

## 적용 시점

모든 응답에 이 규칙을 적용한다.

## 준비

1. 이 스킬 폴더의 `template.md`를 읽는다
2. 해당 템플릿의 구조와 규칙을 따른다

## 터미널 너비 확인

테이블, 긴 목록, 코드블록 등 구조화된 출력 전에:

```bash
tput cols
```

결과에 따라 template.md의 포맷팅 규칙 적용.

## 사용자 선호

사용자가 형식을 지정하면 그걸 우선:
- "json으로" → JSON 출력
- "간단하게" → 핵심만
- "자세히" → 상세 포함
- "테이블로" → 테이블 형식

## 커스터마이징

사용자가 `template.md`를 수정하면 그 규칙을 따른다.
