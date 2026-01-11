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

## Step 3: 스텝 디렉토리 생성 및 템플릿 다운로드

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

3. WebFetch로 spec.md 다운로드:
   - URL: `{base}/steps/{step_name}/spec.md`
   - prompt: "Return the entire markdown content exactly as-is, no modifications"

4. Write 도구로 저장:
   - path: `.claude/siat/steps/{step_name}/instruction.md`
   - path: `.claude/siat/steps/{step_name}/spec.md`

**병렬 처리 권장**: 여러 WebFetch를 동시에 실행하여 속도 향상.

**CRITICAL**: 각 스텝은 반드시 `instruction.md`와 `spec.md` 두 파일을 모두 가져야 합니다.

---

## Step 4: config.yml 완전히 재작성

### 4-1. 현재 config에서 보존할 값만 추출

Read로 `.claude/siat/config.yml` 읽어서 **다음 값들만** 추출:
- `workflow.name` (없으면 "siat")
- `workflow.description` (없으면 "SDD 프레임워크 - 문서 기반 워크플로우")
- `output.path` (없으면 ".claude/siat/specs")
- `hooks` (없으면 템플릿 기본값)

### 4-2. config.yml 완전히 덮어쓰기

Write 도구로 `.claude/siat/config.yml`을 **완전히 새로 작성**:

```yaml
workflow:
  name: "{추출한 name}"
  description: "{추출한 description}"

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

output:
  path: "{추출한 path}"

execution:
  mode: "manual"

hooks:
  pre-step: {추출한 값 또는 []}
  post-step: {추출한 값 또는 [agent:siat-learner]}
  post-workflow: {추출한 값 또는 []}
```

**CRITICAL: 기존 config의 다른 키들(templates, entry, default-template, learning, sub-agent 등)은 모두 제거됨. 위 구조만 남긴다.**

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
