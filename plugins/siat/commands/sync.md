---
description: Sync steps with template - checksum-based comparison
argument-hint: "[--all]"
---

# Siat Sync

체크섬 기반으로 템플릿과 설치된 스텝을 동기화합니다.

## Arguments

`$ARGUMENTS` parsing:
- `--all`: 모든 업데이트 자동 적용 (확인 없이)

---

## Pre-check

```
manifest.yml 확인 중...
```

If `.claude/siat/manifest.yml` doesn't exist:
```
❌ manifest.yml이 없습니다.

/siat init을 먼저 실행해주세요.
```
→ Stop here.

---

## Sync Flow

### 1. 해시 계산

각 스텝의 instruction.md 해시를 계산:

```python
for step in template_steps:
    template_hash = hash(templates/steps/{step}/instruction.md)

for step in installed_steps:
    current_hash = hash(.claude/siat/steps/{step}/instruction.md)
    original_hash = manifest.yml.steps[step].original_hash
```

### 2. 비교

| 현재 vs 원본 | 원본 vs 템플릿 | 상황 | 액션 |
|-------------|---------------|------|------|
| 같음 | 같음 | 변경 없음 | ✅ 스킵 |
| 같음 | 다름 | 템플릿 업데이트됨 | 📥 업데이트 가능 |
| 다름 | 같음 | 사용자가 수정함 | 🔒 유지 |
| 다름 | 다름 | 충돌 | ⚠️ 선택 필요 |

새 스텝:
- 템플릿에 있고 manifest에 없음 → ➕ 새 스텝

Deprecated:
- manifest에 있고 템플릿에 없음 → 📦 deprecated

### 3. 결과 출력

```
🔄 Siat Sync

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

➕ 새 스텝 (N개)
   - {step}: {description}

📥 업데이트 가능 (N개)
   - {step}: 템플릿 변경됨

🔒 커스텀 유지 (N개)
   - {step}: 사용자 수정 감지

⚠️ 충돌 (N개)
   - {step}: 템플릿도 변경, 사용자도 수정

✅ 동일 (N개)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 4. 사용자 선택

Use AskUserQuestion for each category:

**새 스텝:**
```yaml
question: "새 스텝을 추가할까요?"
options:
  - label: "전체 추가"
    description: "모든 새 스텝 추가"
  - label: "선택"
    description: "추가할 스텝 선택"
  - label: "스킵"
    description: "나중에"
```

**업데이트 가능:**
```yaml
question: "스텝을 업데이트할까요?"
options:
  - label: "업데이트"
    description: "템플릿으로 업데이트 (백업 생성)"
  - label: "스킵"
    description: "현재 상태 유지"
```

**충돌:**
```yaml
question: "{step} 스텝이 충돌합니다. 어떻게 할까요?"
options:
  - label: "템플릿으로"
    description: "템플릿으로 덮어쓰기 (백업 생성)"
  - label: "현재 유지"
    description: "사용자 수정 유지"
  - label: "diff 보기"
    description: "차이점 확인"
```

### 5. 실행

**새 스텝 추가:**
1. `templates/steps/{step}/` → `.claude/siat/steps/{step}/` 복사
2. manifest.yml에 해시 추가

**업데이트:**
1. 기존 파일 백업 (`instruction.md.backup`)
2. 템플릿으로 교체
3. manifest.yml 해시 업데이트

**Deprecated:**
1. 폴더 이름 변경 (`{step}` → `{step}.deprecated`)
2. manifest.yml에 deprecated 마킹

### 6. 완료

```
✅ 동기화 완료!

➕ 추가됨: {steps}
📥 업데이트됨: {steps}
🔒 유지됨: {steps}
📦 deprecated: {steps}

manifest.yml 업데이트됨
```

---

## --all Flag

모든 업데이트를 확인 없이 적용:
- 새 스텝: 전체 추가
- 업데이트 가능: 전체 업데이트
- 충돌: 템플릿으로 덮어쓰기

```
/siat sync --all

🔄 전체 동기화 진행 중...

✅ 완료!
```

---

## Important Notes

- 백업 없이 덮어쓰지 않음
- manifest.yml 필수
- 커스텀 스텝 (템플릿에 없는)은 건드리지 않음
