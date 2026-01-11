# Siat v2 Constitution

이 문서는 Siat 워크플로우의 핵심 원칙과 구조를 정의합니다.

---

## 핵심 철학

### 1. 명확화 우선 (Clarify First)
- 모든 워크플로우는 `clarify` 단계에서 시작
- 가정하지 않고 질문한다
- 불명확한 채로 다음 단계로 넘어가지 않는다

### 2. 문서 기반 (Document-Driven)
- 각 단계는 structured output을 생성
- 문서가 다음 단계의 input이 됨
- 사람이 읽을 수 있고, 기계도 파싱 가능

### 3. 점진적 구체화 (Progressive Refinement)
- 추상적 → 구체적으로 단계별 진행
- 각 단계는 이전 단계의 output을 기반으로 확장
- 뒤로 돌아가는 것은 허용하되, 명시적으로

### 4. 학습과 개선 (Learn & Improve)
- 모든 워크플로우는 기록됨
- 반복되는 문제는 시스템적으로 개선
- 프로젝트 지식은 축적됨

---

## 워크플로우 구조

```
[사용자 입력]
      ↓
[clarify] ← 공통 진입점 (Interactive)
      ↓
[템플릿 선택] → feature / bugfix / ui / refactor
      ↓
[템플릿별 단계들] (Document-based)
      ↓
[evaluate] ← 공통 종료점 (Learning)
      ↓
[지식 축적 & 개선 제안]
```

---

## 템플릿 정의

### Feature (새 기능)
```
clarify → spec → design → implement → evaluate
```
- 새로운 기능을 추가할 때
- 요구사항 정의 → 기술 설계 → 구현

### Bugfix (버그 수정)
```
clarify → reproduce → root-cause → fix → verify → evaluate
```
- 버그를 수정할 때
- 재현 → 원인 분석 → 수정 → 검증

### UI (화면 작업)
```
clarify → spec → visual-design → implement → evaluate
```
- UI/화면 작업을 할 때
- design 대신 visual-design (시각적 요소 중심)

### Refactor (리팩토링)
```
clarify → scope → design → implement → verify → evaluate
```
- 코드를 개선/정리할 때
- 범위 정의가 중요

---

## 단계별 원칙

### 공통 원칙
1. **역할 명시**: 각 단계는 특정 역할(role)을 수행
2. **Input/Output 명확**: 무엇을 받고 무엇을 생성하는지
3. **완료 조건**: 언제 완료인지 명확히 정의
4. **금지 사항**: 하지 말아야 할 것 명시

### 단계 간 전이
```yaml
transition:
  from: "{현재 단계}"
  to: "{다음 단계}"
  requires:
    - "{완료 조건 1}"
    - "{완료 조건 2}"
  passes:
    - "{전달할 데이터}"
```

---

## 서브태스크 실행 전략

각 단계 내에서 복잡한 작업은 서브태스크로 분해:

```yaml
sub-tasks:
  - id: "{서브태스크 ID}"
    instruction: "{지시사항}"
    execution:
      strategy: "sequential | parallel | chunked | sub-agent"
      validate: true | false
```

### 실행 전략

| 전략 | 설명 | 사용 시점 |
|------|------|----------|
| sequential | 순차 실행 | 의존성 있는 작업 |
| parallel | 병렬 실행 | 독립적인 작업 |
| chunked | 작은 단위로 나눠서 | 큰 구현 작업 |
| sub-agent | 별도 에이전트로 | 컨텍스트 분리 필요 |

### Tool-Agnostic 설계
- instruction은 특정 도구에 종속되지 않음
- 실행 전략만 환경에 맞게 해석
- Claude Code, OpenAI, 다른 환경 모두 지원 가능

---

## Learning 시스템

### 데이터 흐름
```
[워크플로우 완료]
        ↓
   [evaluate]
        ↓
   ┌────┴────┐────────┐
   ↓         ↓        ↓
[log]   [knowledge]  [suggest]
   ↓         ↓        ↓
.claude/    .claude/   .claude/
siat/logs/  knowledge/ siat/suggestions/
```

### Log (기록)
- 각 워크플로우의 진행 기록
- 단계별 iteration, 소요 시간, 막힌 부분
- 사용자 피드백

### Knowledge (지식)
- 프로젝트에 대한 축적된 이해
- 도메인별 구조, 결정사항, 주의사항
- 자동 업데이트 + 수동 보강

### Improve (개선)
- 반복되는 문제 패턴 감지
- 개선 제안 생성
- 사용자 승인 후 적용

---

## Output 형식

### YAML 우선
- 구조화된 데이터는 YAML 형식
- 사람이 읽기 쉽고, 파싱도 용이

### Markdown 보조
- 설명적 내용은 Markdown
- YAML 내 multi-line string으로 포함 가능

### 예시
```yaml
task: "장바구니 수량 변경"
status: "completed"

summary: |
  장바구니에서 상품 수량을 변경하는 기능을 구현했습니다.
  Optimistic update 패턴을 적용하여 빠른 UX를 제공합니다.

details:
  components_created:
    - name: "QuantityControl"
      path: "src/components/cart/QuantityControl.tsx"
```

---

## 버전 관리

### 템플릿 버전
- 각 템플릿의 instruction은 버전 관리
- 개선 적용 시 버전 증가

### 호환성
- 새 버전은 기존 로그와 호환
- Breaking change 시 마이그레이션 가이드 제공

---

## 확장 포인트

### 커스텀 템플릿
```yaml
# config.yml
templates:
  my-custom:
    description: "커스텀 워크플로우"
    steps: [step1, step2, step3]
```

### 커스텀 단계
```
steps/
└── my-custom-step/
    └── instruction.md
```

### Hooks
```yaml
hooks:
  pre-step:
    - agent:custom-agent
  post-step:
    - agent:reporter
  post-workflow:
    - evaluate
    - agent:github-issue-creator
```
