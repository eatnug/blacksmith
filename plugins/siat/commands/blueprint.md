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

## GitHub API 설정

```
REPO="eatnug/blacksmith"
BASE_PATH="plugins/siat/templates"
```

파일 다운로드 함수 (gh CLI 사용):
```bash
gh api "repos/${REPO}/contents/${BASE_PATH}/{path}" --jq '.content' | base64 -d
```

---

## Step 0: v6.x → v7.x 마이그레이션 감지

기존 siat 설정이 있으면 마이그레이션 필요 여부 확인:

**마이그레이션 스크립트 실행 (dry-run only):**
```bash
${CLAUDE_PLUGIN_ROOT}/skills/siat/scripts/siat-migrate.sh .claude/siat/config.yml --dry-run
```

**스크립트가 감지하는 항목:**
1. **Old config format**: hooks.pre-step → hooks.pre_step, execution.mode → gateway
2. **Old steps**: clarify, prd, design... → specify, plan, implement, review

**CRITICAL: 기존 specs 문서는 절대 건드리지 않음**
- 기존 문서의 frontmatter (children, parent, steps)는 그대로 유지
- 구조만 맞으면 (`{output.path}/{task-id}/{step}.md`) 호환됨
- 새 워크플로우는 새 문서부터 새 frontmatter 사용

**감지 결과만 출력:**
```
📋 마이그레이션 감지 결과:
- Config 업데이트 필요: {yes/no}
- Old steps 감지: {yes/no}
- 기존 specs 문서: {n}개 (변경 없음)
```

---

## Step 0.5: 체크섬 비교 (--force 아닐 때만)

`--force`가 **아닐 때만** 체크섬 비교 수행:

1. gh CLI로 원격 CHECKSUM 다운로드:
```bash
REMOTE_CHECKSUM=$(gh api "repos/${REPO}/contents/${BASE_PATH}/CHECKSUM" --jq '.content' | base64 -d | tr -d '\n')
```

2. Read로 로컬 CHECKSUM 확인:
   - path: `.claude/siat/CHECKSUM`
   - 파일 없으면 → 업데이트 필요

3. 체크섬 비교:
   - **같으면**:
     ```
     ✅ 이미 최신 상태입니다.

     강제 업데이트: /blueprint --force
     ```
     → 여기서 종료
   - **다르면** → Step 1로 진행

---

## Step 1: 원격 config.yml 다운로드

```bash
REMOTE_CONFIG=$(gh api "repos/${REPO}/contents/${BASE_PATH}/config.yml" --jq '.content' | base64 -d)
```

**실패 시:**
```
❌ 템플릿을 다운로드할 수 없습니다.
gh CLI가 설치되어 있고 인증되었는지 확인해주세요.
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

**4개 Bash 호출을 병렬로 실행** (한 번에 4개 tool call):

각 스텝에 대해 동일한 패턴의 Bash 호출:

| 스텝 | Bash 명령 |
|------|-----------|
| specify | `mkdir -p .claude/siat/steps/specify && gh api repos/eatnug/blacksmith/contents/plugins/siat/templates/steps/specify/instruction.md --jq '.content' \| base64 -d > .claude/siat/steps/specify/instruction.md && gh api repos/eatnug/blacksmith/contents/plugins/siat/templates/steps/specify/spec_template.md --jq '.content' \| base64 -d > .claude/siat/steps/specify/spec_template.md` |
| plan | (같은 패턴, 스텝명만 변경) |
| implement | (같은 패턴) |
| review | (같은 패턴) |

**실행 방법**: 위 4개 Bash 호출을 **하나의 응답에서 병렬로** 실행

**CRITICAL**:
- 4개 스텝 모두 다운로드해야 함
- 각 스텝은 `instruction.md`와 `spec_template.md` 두 파일 필수

---

## Step 4: config.yml 업데이트

### 4-1. 현재 config에서 보존할 값 추출

Read로 `.claude/siat/config.yml` 읽어서 **다음 값들** 추출:
- `output.path` (없으면 ".claude/siat/specs")
- `gateway` (없으면 템플릿 기본값)
- `hooks` (없으면 템플릿 기본값)

### 4-2. 유저 확인 (CRITICAL)

추출한 값들을 보여주고 AskUserQuestion으로 확인:

```
📋 현재 설정을 확인해주세요:

output.path: {추출한 path}
gateway:
  questions: {추출한 값}
  feedback: {추출한 값}
hooks: {커스텀 hooks 있으면 표시}
```

```yaml
question: "이 설정을 유지할까요?"
header: "Config"
options:
  - label: "유지 (Recommended)"
    description: "기존 output.path, gateway, hooks 유지"
  - label: "초기화"
    description: "모든 설정을 기본값으로 리셋"
  - label: "수정"
    description: "설정을 직접 수정"
```

**"수정" 선택 시:**
추가 질문으로 각 값 입력받기:
- output.path 입력
- gateway 선택 (local/remote)

### 4-3. config.yml 덮어쓰기

Write 도구로 `.claude/siat/config.yml`을 **완전히 새로 작성**:

```yaml
# Siat Configuration
# Universal SDD 구현체

# 워크플로우 스텝 정의
steps:
  - specify
  - plan
  - implement
  - review

# 출력 경로
output:
  path: "{추출한 path}"

# Gateway: 사용자 상호작용 채널
gateway:
  questions: {추출한 값 또는 local}
  feedback: {추출한 값 또는 local}

# Hooks: 워크플로우 확장 포인트
hooks:
  pre_step: {추출한 값 또는 []}
  on_processed: {추출한 값 또는 []}
  on_approve: {추출한 값 또는 []}
  on_reject: {추출한 값 또는 []}
  on_revise: {추출한 값 또는 []}
  on_complete: {추출한 값 또는 []}

# Presets: 자주 쓰는 설정 묶음
presets:
  remote:
    gateway:
      questions: script:gh-poll.sh {spec_path} --type=questions
      feedback: script:gh-poll.sh {spec_path} --type=feedback
    hooks:
      on_processed:
        - script:gh-issue.sh {spec_path}
        - script:slack-notify.sh {spec_path}
      on_approve:
        - script:gh-issue-close.sh {spec_path}
```

**CRITICAL: 기존 config의 다른 키들(workflow, templates, entry, default-template, learning, sub-agent, execution 등)은 모두 제거됨. 위 구조만 남긴다.**

---

## Step 5: CHECKSUM 파일 저장

원격에서 받은 CHECKSUM을 로컬에 저장:

```bash
echo "${REMOTE_CHECKSUM}" > .claude/siat/CHECKSUM
```

이후 체크섬 비교에서 사용됨.

---

## Step 6: 완료 메시지

`--force` 사용 시:
```
✅ Blueprint 적용 완료!

📥 적용됨: 4개 스텝 (specify, plan, implement, review)
⚙️ config.yml 업데이트됨

Best practice가 적용되었습니다.
```

`--force` 미사용 시:
```
✅ Blueprint 적용 완료!

📦 백업됨: steps.backup.{timestamp}
📥 적용됨: 4개 스텝 (specify, plan, implement, review)
⚙️ config.yml 업데이트됨

Best practice가 적용되었습니다.
```

---

## 핵심 원칙

1. **gh CLI 사용** - WebFetch 대신 gh CLI로 권한 허용 최소화
2. **항상 백업** - `--force` 아니면 기존 설정 백업
3. **전체 동기화** - 부분 업데이트 없음, 항상 전체 적용
4. **설정 보존** - `output.path`, `gateway`, `hooks` 유지
