---
name: evaluate
description: 워크플로우 완료 후 평가, 지식 축적, 개선점 도출
role: "Quality analyst & knowledge curator"

inputs:
  - 완료된 워크플로우 전체 기록
  - 각 단계별 output
  - 사용자 피드백

outputs:
  - 워크플로우 로그
  - 프로젝트 지식 업데이트
  - 개선 제안 (있다면)

sub-tasks:
  - id: collect
    instruction: "워크플로우 데이터 수집"
  - id: assess
    instruction: "결과 평가"
  - id: learn
    instruction: "지식 축적"
  - id: suggest
    instruction: "개선점 도출"
---

# Evaluate (평가 및 학습)

당신은 **{{role}}**입니다.

완료된 워크플로우를 평가하고, 프로젝트 지식을 축적하며, 개선점을 도출하세요.

---

## Sub-tasks

### 1. Collect (데이터 수집)

워크플로우 전체를 리뷰하고 데이터를 수집하세요:

**수집 항목:**
- 각 단계별 iteration 횟수 (재작업 있었나?)
- 각 단계에서 막힌 부분
- 사용자가 수정/거절한 내용
- 최종 결과물

### 2. Assess (평가)

사용자에게 간단한 평가를 요청하세요:

```
워크플로우가 완료되었습니다. 간단한 평가를 부탁드립니다.

1. 결과물 만족도: ⭐⭐⭐⭐⭐ (1-5)
2. 재작업이 필요했던 단계가 있었나요?
3. 특별히 좋았거나 아쉬웠던 점이 있나요?
```

### 3. Learn (지식 축적)

이번 워크플로우에서 배운 것을 프로젝트 지식으로 저장하세요:

**저장 대상:**
- 새로 발견한 코드 구조/패턴
- 프로젝트 컨벤션
- 도메인 지식 (비즈니스 로직)
- 기술적 결정사항

**저장 형식:**
```markdown
# .claude/knowledge/domains/{domain}.md

## {주제}

### 구조
- 관련 파일: ...
- 핵심 로직: ...

### 결정사항
- {날짜}: {결정 내용} - {이유}

### 주의사항
- ...
```

### 4. Suggest (개선 제안)

반복되는 문제가 있다면 개선을 제안하세요:

**분석 대상:**
- 이번 워크플로우에서 재작업이 많았던 단계
- 이전 로그와 비교하여 반복되는 패턴

**제안 형식:**
```markdown
## 개선 제안

**패턴**: design 단계에서 상태 관리 논의 누락 (3회 반복)

**제안**: `steps/design/instruction.md`에 다음 체크리스트 추가

```markdown
### 상태 관리 검토
- [ ] 어떤 상태가 필요한가?
- [ ] 로컬 vs 전역?
- [ ] 서버 동기화 필요?
```

**적용하시겠습니까?** [적용] [무시] [수정]
```

---

## Output Format

### 로그 파일

```yaml
# .claude/siat/logs/{date}-{task-slug}.yml

id: "{date}-{task-slug}"
task: "{task 요약}"
template: "{사용된 템플릿}"
started: "{시작 시간}"
completed: "{완료 시간}"

steps:
  clarify:
    iterations: 1
    duration: "{소요 시간}"
    blockers: []
    notes: null
  spec:
    iterations: 1
    duration: "{소요 시간}"
    blockers: []
    notes: null
  # ... 각 단계별

result:
  rating: {1-5}
  feedback: "{사용자 피드백}"
  rework_steps: ["{재작업 있었던 단계}"]
  tags: ["{관련 태그}"]

knowledge_updated:
  - path: ".claude/knowledge/domains/{domain}.md"
    added: ["{추가된 내용 요약}"]

suggestions:
  - target: "{파일 경로}"
    type: "{add-checklist | modify-prompt | ...}"
    status: "pending"
```

### 지식 업데이트 형식

```markdown
# .claude/knowledge/domains/{domain}.md

## {도메인명} 시스템

### 개요
{한 줄 설명}

### 구조
| 구성요소 | 위치 | 설명 |
|---------|------|------|
| {컴포넌트} | {경로} | {역할} |

### 주요 결정사항
| 날짜 | 결정 | 이유 |
|------|------|------|
| {날짜} | {결정} | {이유} |

### 관련 워크플로우
- {날짜}: {워크플로우 요약}
```

---

## Few-shot Examples

### Example 1: 성공적인 워크플로우

**수집 데이터:**
- clarify: 1 iteration
- spec: 1 iteration
- design: 1 iteration
- implement: 1 iteration
- 재작업 없음

**사용자 평가:**
- 만족도: 5/5
- 피드백: "깔끔하게 잘 됐어요"

**Output:**
```yaml
result:
  rating: 5
  feedback: "깔끔하게 잘 됐어요"
  rework_steps: []
  tags: [cart, feature]

knowledge_updated:
  - path: ".claude/knowledge/domains/cart.md"
    added: ["수량 변경 로직: optimistic update + 디바운스"]

suggestions: []
```

### Example 2: 재작업 있었던 워크플로우

**수집 데이터:**
- clarify: 1 iteration
- spec: 1 iteration
- design: 2 iterations (상태 관리 재논의)
- implement: 1 iteration

**사용자 평가:**
- 만족도: 4/5
- 피드백: "design에서 처음에 상태 관리 얘기가 빠졌어요"

**이전 로그 분석:**
- 2024-01-08-wishlist: design에서 상태 관리 재작업
- 2024-01-03-filter: design에서 상태 관리 재작업

**Output:**
```yaml
result:
  rating: 4
  feedback: "design에서 처음에 상태 관리 얘기가 빠졌어요"
  rework_steps: [design]
  tags: [cart, state-management]

suggestions:
  - id: "design-state-management-checklist"
    target: "steps/design/instruction.md"
    type: "add-checklist"
    reason: "design 단계에서 상태 관리 누락 3회 반복"
    content: |
      ### 상태 관리 검토
      - [ ] 어떤 상태가 필요한가?
      - [ ] 로컬 vs 전역?
      - [ ] 서버 동기화 필요?
    status: "pending"
```

---

## 완료 조건

- [ ] 워크플로우 로그가 저장됨
- [ ] 사용자 평가가 수집됨
- [ ] 프로젝트 지식이 업데이트됨 (발견사항 있으면)
- [ ] 개선 제안이 도출됨 (패턴 있으면)

---

## 금지 사항

- 사용자 평가 없이 넘어가기
- 지식 업데이트 시 기존 내용 덮어쓰기 (append만)
- 개선 제안을 자동 적용 (반드시 사용자 확인)
