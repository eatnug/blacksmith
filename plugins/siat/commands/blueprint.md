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

## Step 0: v5.x → v6.x 마이그레이션

기존 siat 설정이 있으면 마이그레이션 수행:

**마이그레이션 스크립트 실행:**
```bash
./scripts/siat-migrate.sh .claude/siat/config.yml --dry-run
```

**스크립트가 감지하는 항목:**
1. **기존 scripts 폴더**: `.claude/siat/scripts/` (v6.0부터 스킬에 포함)
2. **스텝 단위 문서**: `specs/clarify/task-id.md` → `specs/task-id/clarify.md`

**dry-run 결과 확인 후:**
```bash
./scripts/siat-migrate.sh .claude/siat/config.yml
```

**출력 예시:**
```json
{
  "actions": ["remove_old_scripts", "convert_to_feature_centric"],
  "migrated_files": [
    "clarify/login-page.md -> login-page/clarify.md",
    "design/login-page.md -> login-page/design.md"
  ],
  "summary": { "files_migrated": 2, "dirs_removed": 3 }
}
```

**마이그레이션 완료 후:**
```
✅ v6.0 마이그레이션 완료

📁 문서 구조 변환: {n}개 파일
🗑️ 정리됨: 기존 scripts 폴더, 빈 스텝 폴더
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

**9개 Bash 호출을 병렬로 실행** (한 번에 9개 tool call):

각 스텝에 대해 동일한 패턴의 Bash 호출:

| 스텝 | Bash 명령 |
|------|-----------|
| clarify | `mkdir -p .claude/siat/steps/clarify && gh api repos/eatnug/blacksmith/contents/plugins/siat/templates/steps/clarify/instruction.md --jq '.content' \| base64 -d > .claude/siat/steps/clarify/instruction.md && gh api repos/eatnug/blacksmith/contents/plugins/siat/templates/steps/clarify/spec.md --jq '.content' \| base64 -d > .claude/siat/steps/clarify/spec.md` |
| reproduce | (같은 패턴, 스텝명만 변경) |
| root-cause | (같은 패턴) |
| prd | (같은 패턴) |
| design | (같은 패턴) |
| visual-design | (같은 패턴) |
| implement | (같은 패턴) |
| fix | (같은 패턴) |
| verify | (같은 패턴) |

**실행 방법**: 위 9개 Bash 호출을 **하나의 응답에서 병렬로** 실행

**CRITICAL**:
- 9개 스텝 모두 다운로드해야 함
- 각 스텝은 `instruction.md`와 `spec.md` 두 파일 필수

---

## Step 4: config.yml 완전히 재작성

### 4-1. 현재 config에서 보존할 값만 추출

Read로 `.claude/siat/config.yml` 읽어서 **다음 값들만** 추출:
- `workflow.name` (없으면 "siat")
- `workflow.description` (없으면 "SDD 프레임워크 - 문서 기반 워크플로우")
- `output.path` (없으면 ".claude/siat/specs")
- `execution.mode` (없으면 "manual")
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
  - prd
  - design
  - visual-design
  - implement
  - fix
  - verify

output:
  path: "{추출한 path}"

execution:
  mode: "{추출한 mode}"

hooks:
  pre-step: {추출한 값 또는 []}
  post-step: {추출한 값 또는 []}
  post-workflow: {추출한 값 또는 []}
```

**CRITICAL: 기존 config의 다른 키들(templates, entry, default-template, learning, sub-agent 등)은 모두 제거됨. 위 구조만 남긴다.**

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

📥 적용됨: 9개 스텝 (clarify, reproduce, root-cause, prd, design, visual-design, implement, fix, verify)
⚙️ config.yml 업데이트됨

Best practice가 적용되었습니다.
```

`--force` 미사용 시:
```
✅ Blueprint 적용 완료!

📦 백업됨: steps.backup.{timestamp}
📥 적용됨: 9개 스텝 (clarify, reproduce, root-cause, prd, design, visual-design, implement, fix, verify)
⚙️ config.yml 업데이트됨

Best practice가 적용되었습니다.
```

---

## 핵심 원칙

1. **gh CLI 사용** - WebFetch 대신 gh CLI로 권한 허용 최소화
2. **항상 백업** - `--force` 아니면 기존 설정 백업
3. **전체 동기화** - 부분 업데이트 없음, 항상 전체 적용
4. **설정 보존** - `workflow`, `output.path`, `execution.mode`, `hooks` 유지
