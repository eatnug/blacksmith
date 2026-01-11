---
name: schema-validator
description: 스텝 instruction 스키마 검증 (pre-hook)
execution:
  context: isolated
  fail_behavior: block  # 실패 시 워크플로우 중단
---

# Schema Validator

스텝 실행 전 instruction.md 구조를 검증합니다.

---

## 검증 대상

실행하려는 스텝의 `instruction.md` 파일

---

## 필수 스키마

### Frontmatter (YAML)

```yaml
---
name: string        # 필수
description: string # 필수
---
```

### 필수 섹션

```
# {스텝명}           # H1 제목 필수

## Sub-tasks         # 권장 (없어도 통과)

## Output Format     # 필수

## 완료 조건         # 필수
```

---

## 검증 로직

```python
def validate(instruction_path):
    content = read(instruction_path)
    errors = []

    # 1. Frontmatter 검증
    frontmatter = parse_frontmatter(content)
    if not frontmatter.get('name'):
        errors.append("frontmatter.name 누락")
    if not frontmatter.get('description'):
        errors.append("frontmatter.description 누락")

    # 2. 필수 섹션 검증
    if "## Output Format" not in content:
        errors.append("## Output Format 섹션 누락")
    if "## 완료 조건" not in content:
        errors.append("## 완료 조건 섹션 누락")

    return errors
```

---

## 출력

### 성공 시

```yaml
validation:
  status: pass
  step: spec
  file: .claude/siat/steps/spec/instruction.md
```

→ 워크플로우 계속 진행

### 실패 시

```yaml
validation:
  status: fail
  step: spec
  file: .claude/siat/steps/spec/instruction.md
  errors:
    - "frontmatter.name 누락"
    - "## Output Format 섹션 누락"
```

→ 워크플로우 중단, 에러 메시지 표시:

```
❌ 스키마 검증 실패: spec/instruction.md

누락된 항목:
- frontmatter.name
- ## Output Format 섹션

수정 후 다시 실행해주세요.
```

---

## 금지 사항

- 검증 외 다른 작업 수행
- 파일 수정
- 경고만 하고 진행 (실패 시 반드시 중단)
