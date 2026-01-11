---
description: Apply best-practice templates to your siat setup
argument-hint: "[--force]"
---

# Siat Blueprint

Best practice 템플릿을 프로젝트에 **강제 적용**합니다.

## Arguments

`$ARGUMENTS` parsing:
- `--force`: 기존 커스터마이징 무시하고 완전히 덮어쓰기

---

## Pre-check

`.claude/siat/config.yml` 파일이 없으면:
```
❌ siat이 설정되지 않았습니다.
/siat init을 먼저 실행해주세요.
```
→ 여기서 중단.

---

## Step 1: 템플릿 경로 찾기

Glob으로 `**/siat/templates/config.yml` 검색.

찾은 경로에서 템플릿 루트 추출:
- `/path/to/plugins/siat/templates/config.yml`
- → 템플릿 루트: `/path/to/plugins/siat/templates/`

**못 찾으면:**
```
❌ 템플릿을 찾을 수 없습니다.
siat 플러그인이 설치되어 있는지 확인해주세요.
```
→ 여기서 중단.

---

## Step 2: 템플릿 스텝 전체 복사

**무조건 템플릿 기준으로 동기화합니다.**

### 2-1. 기존 steps 백업

```bash
if [ -d ".claude/siat/steps" ]; then
  mv ".claude/siat/steps" ".claude/siat/steps.backup.$(date +%Y%m%d%H%M%S)"
fi
```

### 2-2. 템플릿 steps 복사

```bash
cp -r "{템플릿루트}/steps" ".claude/siat/steps"
```

---

## Step 3: config.yml 동기화

### 3-1. 현재 config 읽기

Read로 `.claude/siat/config.yml` 읽어서 현재 설정 파악:
- `output.path` (보존)
- `hooks` (보존)

### 3-2. workflow.steps 강제 업데이트

템플릿의 config.yml에서 `workflow.steps` 배열을 가져와서 **현재 config에 덮어쓰기**.

```yaml
workflow:
  steps:
    - clarify
    - reproduce
    - root-cause
    - spec
    - design
    - visual-design
    - implement
    - fix
    - verify
```

Edit 도구로 config.yml 수정. `output`, `hooks` 등 다른 설정은 보존.

---

## Step 4: 완료 메시지

```
✅ Blueprint 적용 완료!

📦 백업됨: steps.backup.{timestamp}
📥 적용됨: 9개 스텝 (clarify, reproduce, root-cause, spec, design, visual-design, implement, fix, verify)
⚙️ config.yml 업데이트됨

Best practice가 적용되었습니다.
```

---

## --force 플래그

`--force` 사용 시:
- 백업 생성 안 함
- 기존 steps 폴더 그냥 삭제 후 복사

```bash
rm -rf ".claude/siat/steps"
cp -r "{템플릿루트}/steps" ".claude/siat/steps"
```

---

## 핵심 원칙

1. **템플릿이 진리** - 커스터마이징보다 best practice 우선
2. **항상 백업** - `--force` 아니면 기존 설정 백업
3. **전체 동기화** - 부분 업데이트 없음, 항상 전체 적용
4. **설정 보존** - `output.path`, `hooks`는 유지
