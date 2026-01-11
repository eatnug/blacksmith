---
description: Apply best-practice templates to your siat setup
argument-hint: "[--force]"
---

# Siat Blueprint

Best practice 템플릿을 GitHub에서 다운로드하여 프로젝트에 **강제 적용**합니다.

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

## Step 1: GitHub에서 템플릿 config.yml fetch

GitHub raw URL base:
```
https://raw.githubusercontent.com/eatnug/blacksmith/main/plugins/siat/templates
```

WebFetch로 `{base}/config.yml` 다운로드.
- prompt: "Return the entire YAML content exactly as-is, no modifications"

**실패 시:**
```
❌ 템플릿을 다운로드할 수 없습니다.
네트워크 연결을 확인해주세요.
```
→ 여기서 중단.

---

## Step 2: 기존 steps 백업 (--force가 아닐 때)

`--force`가 **아닐 때만** 백업:

```bash
if [ -d ".claude/siat/steps" ]; then
  mv ".claude/siat/steps" ".claude/siat/steps.backup.$(date +%Y%m%d%H%M%S)"
fi
```

`--force` 시:
```bash
rm -rf ".claude/siat/steps"
```

---

## Step 3: 스텝 디렉토리 생성 및 instruction.md 다운로드

스텝 목록 (config.yml에서 파싱):
- clarify
- reproduce
- root-cause
- spec
- design
- visual-design
- implement
- fix
- verify

각 스텝에 대해:

1. 디렉토리 생성:
```bash
mkdir -p ".claude/siat/steps/{step_name}"
```

2. WebFetch로 instruction.md 다운로드:
   - URL: `{base}/steps/{step_name}/instruction.md`
   - prompt: "Return the entire markdown content exactly as-is, no modifications"

3. Write 도구로 저장:
   - path: `.claude/siat/steps/{step_name}/instruction.md`

**병렬 처리 권장**: 여러 WebFetch를 동시에 실행하여 속도 향상.

---

## Step 4: config.yml 동기화

### 4-1. 현재 config 읽기

Read로 `.claude/siat/config.yml` 읽어서 현재 설정 파악:
- `output.path` (보존)
- `hooks` (보존)
- `workflow.name` (보존)
- `workflow.description` (보존)

### 4-2. steps 배열만 업데이트

템플릿의 config.yml에서 `steps` 배열을 가져와서 **현재 config의 steps에 덮어쓰기**.

```yaml
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

Edit 도구로 config.yml 수정. `workflow`, `output`, `hooks`, `execution` 등 다른 설정은 보존.

---

## Step 5: 완료 메시지

`--force` 사용 시:
```
✅ Blueprint 적용 완료!

📥 적용됨: 9개 스텝 (clarify, reproduce, root-cause, spec, design, visual-design, implement, fix, verify)
⚙️ config.yml 업데이트됨

Best practice가 적용되었습니다.
```

`--force` 미사용 시:
```
✅ Blueprint 적용 완료!

📦 백업됨: steps.backup.{timestamp}
📥 적용됨: 9개 스텝 (clarify, reproduce, root-cause, spec, design, visual-design, implement, fix, verify)
⚙️ config.yml 업데이트됨

Best practice가 적용되었습니다.
```

---

## 핵심 원칙

1. **원격 템플릿** - GitHub에서 최신 best practice 다운로드
2. **항상 백업** - `--force` 아니면 기존 설정 백업
3. **전체 동기화** - 부분 업데이트 없음, 항상 전체 적용
4. **설정 보존** - `workflow`, `output`, `hooks`, `execution` 유지
