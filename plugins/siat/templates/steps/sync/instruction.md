---
name: sync
description: 체크섬 기반 스텝 동기화
role: "Configuration manager"

triggers:
  - "/siat sync"
  - "/sync"
---

# Sync (동기화)

체크섬을 비교하여 스텝을 동기화합니다.

---

## manifest.yml 구조

```yaml
# .claude/siat/manifest.yml

installed_at: "2024-01-10"
source: "siat-plugin"
version: "1.0.0"

steps:
  clarify:
    original_hash: "abc123"  # 설치 시점 해시
  spec:
    original_hash: "def456"
  design:
    original_hash: "ghi789"
  implement:
    original_hash: "jkl012"
```

---

## 동기화 로직

### 1. 해시 계산

각 스텝의 `instruction.md` 파일 해시 계산:

```
현재 해시     = hash(.claude/siat/steps/{step}/instruction.md)
원본 해시     = manifest.yml의 original_hash
템플릿 해시   = hash(templates/steps/{step}/instruction.md)
```

### 2. 비교 및 판단

| 현재 vs 원본 | 원본 vs 템플릿 | 상황 | 액션 |
|-------------|---------------|------|------|
| 같음 | 같음 | 변경 없음 | ✅ 스킵 |
| 같음 | 다름 | 템플릿 업데이트됨 | 📥 업데이트 가능 |
| 다름 | 같음 | 사용자가 수정함 | 🔒 유지 (커스텀) |
| 다름 | 다름 | 충돌 | ⚠️ 선택 필요 |

### 3. 새 스텝 / 삭제된 스텝

```
템플릿에 있음 + manifest에 없음  → ➕ 새 스텝
manifest에 있음 + 템플릿에 없음 → 📦 deprecated
```

---

## 실행 흐름

```
/siat sync

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 스텝 비교 중...

manifest: .claude/siat/manifest.yml
템플릿:   plugins/siat/templates/steps/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 비교 결과

➕ 새 스텝 (2개)
   - evaluate     (템플릿에 추가됨)
   - reproduce    (템플릿에 추가됨)

📥 업데이트 가능 (1개)
   - spec         (템플릿 변경됨, 커스텀 없음)

🔒 커스텀 유지 (2개)
   - design       (사용자 수정 감지)
   - implement    (사용자 수정 감지)

⚠️ 충돌 (1개)
   - clarify      (템플릿도 변경, 사용자도 수정)

✅ 동일 (0개)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

어떻게 처리할까요?
```

### 사용자 선택

```
1. 새 스텝
   [전체 추가] [선택] [스킵]

2. 업데이트 가능
   [업데이트] [스킵]

3. 충돌 (clarify)
   [템플릿으로 덮어쓰기] [현재 유지] [diff 보기]
```

---

## 실행

### 새 스텝 추가

```bash
# 1. 템플릿에서 복사
cp -r templates/steps/evaluate/ .claude/siat/steps/evaluate/

# 2. manifest 업데이트
steps:
  evaluate:
    original_hash: "{새 해시}"
```

### 업데이트

```bash
# 1. 백업
mv steps/spec/instruction.md steps/spec/instruction.md.backup

# 2. 템플릿 복사
cp templates/steps/spec/instruction.md steps/spec/

# 3. manifest 업데이트
steps:
  spec:
    original_hash: "{새 해시}"
```

### deprecated 마킹

```bash
# 폴더 이름 변경
mv steps/ideation/ steps/ideation.deprecated/

# manifest에서 제거 (또는 deprecated 마킹)
steps:
  ideation:
    deprecated: true
    original_hash: "..."
```

---

## 완료 메시지

```
✅ 동기화 완료!

➕ 추가됨
   - evaluate, reproduce

📥 업데이트됨
   - spec (백업: instruction.md.backup)

🔒 유지됨
   - design, implement (커스텀 보존)

⚠️ 스킵됨
   - clarify (수동 확인 필요)

manifest.yml 업데이트됨
```

---

## init에서 manifest 생성

`/siat init` 실행 시 manifest.yml 자동 생성:

```yaml
# 초기 설치 시 생성되는 manifest.yml

installed_at: "2024-01-10T10:30:00"
source: "siat-plugin"
version: "1.0.0"

steps:
  clarify:
    original_hash: "a1b2c3d4"
  spec:
    original_hash: "e5f6g7h8"
  design:
    original_hash: "i9j0k1l2"
  implement:
    original_hash: "m3n4o5p6"
  evaluate:
    original_hash: "q7r8s9t0"
  reproduce:
    original_hash: "u1v2w3x4"
  root-cause:
    original_hash: "y5z6a7b8"
  fix:
    original_hash: "c9d0e1f2"
  verify:
    original_hash: "g3h4i5j6"
```

---

## 금지 사항

- 사용자 확인 없이 커스텀 파일 덮어쓰기
- manifest.yml 없이 sync 실행 (init 먼저 안내)
- 백업 없이 업데이트
