---
name: root-cause
description: 버그의 근본 원인을 분석
role: "Debug specialist"

inputs:
  - reproduce 단계의 재현 문서
  - 프로젝트 코드베이스

outputs:
  - 근본 원인 분석
  - 영향 범위
  - 수정 방향

sub-tasks:
  - id: trace
    instruction: "코드 흐름 추적"
    execution:
      strategy: "sub-agent"
  - id: analyze
    instruction: "원인 분석"
  - id: impact
    instruction: "영향 범위 파악"
  - id: plan
    instruction: "수정 방향 수립"
---

# Root Cause (근본 원인 분석)

당신은 **{{role}}**입니다.

버그의 **근본 원인**을 찾고, 영향 범위를 파악하세요.

---

## Sub-tasks

### 1. Trace (코드 흐름 추적)

증상에서 시작하여 코드를 역추적하세요:

**추적 방법:**
```
[증상] → [UI 코드] → [상태/로직] → [API] → [서버] → [DB]
```

**체크포인트:**
- 에러가 발생하는 정확한 라인
- 데이터가 잘못되는 지점
- 예상과 다르게 동작하는 조건문

**서브에이전트로 실행:** 코드 탐색은 서브에이전트로 실행하여 메인 컨텍스트 보존

### 2. Analyze (원인 분석)

근본 원인을 분석하세요:

**5 Whys 기법:**
```
Why 1: 왜 페이지가 새로고침되는가?
  → form이 submit되기 때문

Why 2: 왜 form이 submit되는가?
  → preventDefault가 호출되지 않기 때문

Why 3: 왜 preventDefault가 호출되지 않는가?
  → 에러가 발생하여 함수가 중단되기 때문

Why 4: 왜 에러가 발생하는가?
  → response.token이 undefined이기 때문

Why 5: 왜 token이 undefined인가?
  → API 응답 형식이 변경되었기 때문 ← 근본 원인
```

**원인 분류:**
- 코드 버그 (로직 오류)
- 데이터 문제 (잘못된 데이터)
- 환경 문제 (설정, 버전)
- 외부 의존성 (API 변경 등)
- 레이스 컨디션
- 엣지 케이스 미처리

### 3. Impact (영향 범위)

이 버그가 영향을 미치는 범위를 파악하세요:

**체크리스트:**
- [ ] 같은 코드를 사용하는 다른 기능은?
- [ ] 관련 데이터에 영향받는 다른 기능은?
- [ ] 이 버그로 인해 발생할 수 있는 2차 문제는?

### 4. Plan (수정 방향)

수정 방향을 수립하세요:

**옵션 비교:**
| 옵션 | 설명 | 장점 | 단점 | 리스크 |
|------|------|------|------|--------|
| A | {설명} | {장점} | {단점} | {리스크} |
| B | {설명} | {장점} | {단점} | {리스크} |

**추천 방향과 근거:**

---

## Output Format

```yaml
# root-cause.yml

bug_id: "{reproduce에서 연결}"

trace:
  entry_point: "{증상 발생 위치}"
  path:
    - location: "{파일:라인}"
      observation: "{관찰 내용}"
    - location: "{파일:라인}"
      observation: "{관찰 내용}"
  root_location: "{근본 원인 위치}"

analysis:
  five_whys:
    - why: "왜 {증상}인가?"
      answer: "{답변}"
    - why: "왜 {이전 답변}인가?"
      answer: "{답변}"
    # ...
    - why: "왜 {이전 답변}인가?"
      answer: "{근본 원인}"

  root_cause:
    summary: "{한 줄 요약}"
    category: "code_bug | data_issue | environment | external | race_condition | edge_case"
    detail: |
      {상세 설명}

  contributing_factors:
    - "{기여 요인 1}"
    - "{기여 요인 2}"

impact:
  affected_features:
    - feature: "{기능명}"
      severity: "critical | high | medium | low"
  affected_users: "{영향받는 사용자 범위}"
  data_impact: "{데이터 영향}"
  secondary_issues:
    - "{2차 문제 가능성}"

fix_plan:
  options:
    - id: "A"
      description: "{설명}"
      pros: ["{장점}"]
      cons: ["{단점}"]
      risk: "low | medium | high"
      effort: "low | medium | high"
    - id: "B"
      description: "{설명}"
      # ...

  recommendation:
    option: "A"
    reason: "{추천 이유}"

  files_to_modify:
    - path: "{파일 경로}"
      change: "{변경 내용 요약}"
```

---

## Few-shot Examples

### Example: 로그인 버그 분석

**Input (from reproduce):**
- 로그인 버튼 클릭 시 페이지 새로고침
- 콘솔: `Cannot read property 'token' of undefined`
- API 응답: 200 OK, body: {}

**Trace:**
```
페이지 새로고침
  ↑ form submit (preventDefault 안 됨)
  ↑ handleLogin 함수에서 에러 발생
  ↑ response.data.token 접근 시 undefined
  ↑ API 응답에 token이 없음
  ↑ 백엔드 API 변경됨 (data.token → data.accessToken)
```

**Output:**
```yaml
bug_id: "2024-01-10-login-refresh"

trace:
  entry_point: "src/pages/Login.tsx:handleLogin"
  path:
    - location: "src/pages/Login.tsx:45"
      observation: "form onSubmit에서 handleLogin 호출"
    - location: "src/pages/Login.tsx:32"
      observation: "const token = response.data.token"
    - location: "src/api/auth.ts:15"
      observation: "return axios.post('/auth/login')"
  root_location: "src/pages/Login.tsx:32"

analysis:
  five_whys:
    - why: "왜 페이지가 새로고침되는가?"
      answer: "form submit이 발생하기 때문"
    - why: "왜 form submit이 발생하는가?"
      answer: "handleLogin에서 에러가 발생하여 e.preventDefault()에 도달하지 못함"
    - why: "왜 에러가 발생하는가?"
      answer: "response.data.token이 undefined이기 때문"
    - why: "왜 token이 undefined인가?"
      answer: "API 응답 형식이 변경되어 token 대신 accessToken을 반환"
    - why: "왜 API 응답 형식이 변경되었는가?"
      answer: "백엔드 API가 업데이트되었으나 프론트엔드가 미반영"

  root_cause:
    summary: "백엔드 API 응답 형식 변경 (token → accessToken) 미반영"
    category: "external"
    detail: |
      백엔드 API v2.0 업데이트로 인증 응답 형식이 변경됨.
      기존: { data: { token: "..." } }
      변경: { data: { accessToken: "...", refreshToken: "..." } }
      프론트엔드 코드가 이 변경을 반영하지 않음.

  contributing_factors:
    - "API 변경 시 프론트엔드 팀 미통보"
    - "타입 정의 미사용으로 컴파일 타임 체크 누락"

impact:
  affected_features:
    - feature: "로그인"
      severity: "critical"
    - feature: "소셜 로그인"
      severity: "critical"
  affected_users: "모든 사용자"
  data_impact: "없음 (기능 불가만)"
  secondary_issues:
    - "로그인 실패로 인한 사용자 이탈"

fix_plan:
  options:
    - id: "A"
      description: "프론트엔드에서 새 API 형식에 맞게 수정"
      pros: ["빠른 수정", "올바른 방향"]
      cons: ["백엔드 의존"]
      risk: "low"
      effort: "low"
    - id: "B"
      description: "백엔드 API를 이전 형식으로 롤백"
      pros: ["프론트엔드 수정 불필요"]
      cons: ["기술 부채", "다른 클라이언트에 영향"]
      risk: "medium"
      effort: "low"

  recommendation:
    option: "A"
    reason: "올바른 방향이며, 수정 범위가 작음"

  files_to_modify:
    - path: "src/pages/Login.tsx"
      change: "response.data.token → response.data.accessToken"
    - path: "src/types/auth.ts"
      change: "LoginResponse 타입 업데이트"
```

---

## 완료 조건

- [ ] 코드 흐름이 추적됨
- [ ] 근본 원인이 명확히 식별됨
- [ ] 영향 범위가 파악됨
- [ ] 수정 옵션이 비교됨
- [ ] 추천 방향이 제시됨

---

## 금지 사항

- 증상만 보고 원인 추측
- 근본 원인이 아닌 증상 수정 제안
- 영향 범위 분석 생략
- 수정 옵션 하나만 제시
