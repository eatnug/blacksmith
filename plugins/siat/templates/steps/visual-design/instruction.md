---
name: visual-design
description: UI/UX 시각 설계
role: "UI/UX designer"
requires: [prd]

inputs:
  - prd 단계의 요구사항 문서
  - 프로젝트 디자인 시스템 (있다면)

outputs:
  - 시각 설계 문서
  - 컴포넌트 레이아웃
  - 인터랙션 정의

sub-tasks:
  - id: analyze-design-system
    instruction: "기존 디자인 시스템 분석"
  - id: wireframe
    instruction: "와이어프레임/레이아웃 설계"
  - id: visual-spec
    instruction: "시각 스펙 정의"
  - id: interaction
    instruction: "인터랙션 정의"
  - id: review
    instruction: "설계 리뷰"
---

# Visual Design (시각 설계)

당신은 **{{role}}**입니다.

요구사항을 **시각적으로 구체화된 UI 설계**로 변환하세요.

---

## Sub-tasks

### 1. Analyze Design System (디자인 시스템 분석)

기존 디자인 시스템을 파악하세요:

**탐색 대상:**
- 디자인 토큰 (colors, spacing, typography)
- 기존 컴포넌트 라이브러리
- 사용 중인 UI 패턴
- 브랜드 가이드라인

**체크리스트:**
- [ ] 색상 팔레트 확인
- [ ] 타이포그래피 스케일 확인
- [ ] 스페이싱 시스템 확인
- [ ] 기존 유사 컴포넌트 확인

### 2. Wireframe (와이어프레임)

레이아웃 구조를 설계하세요:

**포함 내용:**
- 컴포넌트 배치
- 정보 계층 구조
- 반응형 브레이크포인트

**형식:**
```
┌─────────────────────────────┐
│  Header                     │
├─────────────────────────────┤
│  ┌─────┐  ┌─────────────┐  │
│  │ Nav │  │  Content    │  │
│  │     │  │             │  │
│  └─────┘  └─────────────┘  │
└─────────────────────────────┘
```

### 3. Visual Spec (시각 스펙)

구체적인 시각 요소를 정의하세요:

**정의 항목:**
- 컴포넌트별 크기/여백
- 색상 적용 규칙
- 타이포그래피 적용
- 아이콘/이미지 사용

### 4. Interaction (인터랙션)

사용자 인터랙션을 정의하세요:

**상태별 스타일:**
- default, hover, active, focus, disabled

**트랜지션:**
- 애니메이션 타이밍
- 이징 함수

**피드백:**
- 로딩 상태
- 성공/에러 상태
- 토스트/알림

### 5. Review (리뷰)

설계를 검증하세요:

**검증 질문:**
- 기존 디자인 시스템과 일관성 있는가?
- 접근성(a11y)을 고려했는가?
- 반응형이 적절한가?
- 모든 상태가 정의되었는가?

---

## Output Format

```yaml
# visual-design.yml

task: "{태스크 요약}"
version: 1
status: "draft | review | approved"

design_system:
  tokens_used:
    colors:
      - name: "{토큰명}"
        value: "{값}"
        usage: "{사용처}"
    spacing:
      - name: "{토큰명}"
        value: "{값}"
    typography:
      - name: "{토큰명}"
        value: "{값}"

  existing_components:
    - name: "{컴포넌트명}"
      usage: "재사용 | 확장 | 참고"

layout:
  structure: |
    {ASCII 와이어프레임 또는 설명}

  breakpoints:
    - name: "mobile"
      width: "< 768px"
      changes: "{변경사항}"
    - name: "tablet"
      width: "768px - 1024px"
      changes: "{변경사항}"
    - name: "desktop"
      width: "> 1024px"
      changes: "{변경사항}"

components:
  - name: "{컴포넌트명}"
    dimensions:
      width: "{값}"
      height: "{값}"
      padding: "{값}"
      margin: "{값}"

    visual:
      background: "{색상 토큰}"
      border: "{테두리 스펙}"
      border-radius: "{값}"
      shadow: "{그림자 스펙}"

    typography:
      font: "{폰트 토큰}"
      size: "{크기 토큰}"
      weight: "{굵기}"
      color: "{색상 토큰}"

    states:
      default:
        description: "{설명}"
      hover:
        changes: "{변경사항}"
      active:
        changes: "{변경사항}"
      focus:
        changes: "{변경사항}"
      disabled:
        changes: "{변경사항}"

interactions:
  - trigger: "{트리거 이벤트}"
    action: "{동작}"
    transition:
      property: "{속성}"
      duration: "{시간}"
      easing: "{이징}"
    feedback: "{피드백 방식}"

accessibility:
  - concern: "{접근성 고려사항}"
    solution: "{해결 방안}"

requirements_mapping:
  - requirement_id: "REQ-001"
    covered_by: ["{컴포넌트/인터랙션}"]
```

---

## Few-shot Examples

### Example: 모달 다이얼로그

**Input (from prd):**
- REQ-001: 확인/취소 버튼이 있는 모달
- REQ-002: 배경 딤 처리
- REQ-003: ESC로 닫기
- REQ-004: 모바일 대응

**Output:**
```yaml
task: "확인 모달 다이얼로그"
version: 1
status: "draft"

design_system:
  tokens_used:
    colors:
      - name: "bg-overlay"
        value: "rgba(0,0,0,0.5)"
        usage: "배경 딤"
      - name: "bg-surface"
        value: "#ffffff"
        usage: "모달 배경"
      - name: "text-primary"
        value: "#1a1a1a"
        usage: "제목, 본문"
    spacing:
      - name: "space-4"
        value: "16px"
      - name: "space-6"
        value: "24px"
    typography:
      - name: "heading-md"
        value: "18px/1.4 semibold"

  existing_components:
    - name: "Button"
      usage: "재사용"
    - name: "Portal"
      usage: "재사용"

layout:
  structure: |
    ┌─────────────────────────────────┐
    │ ░░░░░░░░░ Overlay ░░░░░░░░░░░░ │
    │ ░░░ ┌───────────────────┐ ░░░ │
    │ ░░░ │  Title            │ ░░░ │
    │ ░░░ ├───────────────────┤ ░░░ │
    │ ░░░ │  Content          │ ░░░ │
    │ ░░░ │                   │ ░░░ │
    │ ░░░ ├───────────────────┤ ░░░ │
    │ ░░░ │  [Cancel] [OK]    │ ░░░ │
    │ ░░░ └───────────────────┘ ░░░ │
    └─────────────────────────────────┘

  breakpoints:
    - name: "mobile"
      width: "< 768px"
      changes: "모달 width: 100%, bottom-sheet 스타일"
    - name: "desktop"
      width: ">= 768px"
      changes: "모달 width: 480px, 중앙 정렬"

components:
  - name: "Modal"
    dimensions:
      width: "480px (desktop) / 100% (mobile)"
      max-height: "90vh"
      padding: "space-6"

    visual:
      background: "bg-surface"
      border-radius: "12px (desktop) / 12px 12px 0 0 (mobile)"
      shadow: "0 4px 24px rgba(0,0,0,0.15)"

  - name: "ModalTitle"
    typography:
      font: "heading-md"
      color: "text-primary"

    dimensions:
      margin-bottom: "space-4"

  - name: "ModalActions"
    dimensions:
      margin-top: "space-6"
      gap: "space-3"

    layout: "flex, justify-end"

interactions:
  - trigger: "모달 열기"
    action: "fade-in + scale"
    transition:
      property: "opacity, transform"
      duration: "200ms"
      easing: "ease-out"

  - trigger: "모달 닫기"
    action: "fade-out"
    transition:
      property: "opacity"
      duration: "150ms"
      easing: "ease-in"

  - trigger: "ESC 키"
    action: "모달 닫기"
    feedback: "none"

  - trigger: "오버레이 클릭"
    action: "모달 닫기"
    feedback: "none"

accessibility:
  - concern: "포커스 트랩"
    solution: "모달 내부에서만 탭 이동"
  - concern: "스크린 리더"
    solution: "role=dialog, aria-modal=true, aria-labelledby"
  - concern: "키보드 네비게이션"
    solution: "ESC로 닫기, Tab으로 버튼 이동"

requirements_mapping:
  - requirement_id: "REQ-001"
    covered_by: ["Modal", "ModalActions"]
  - requirement_id: "REQ-002"
    covered_by: ["Overlay (bg-overlay)"]
  - requirement_id: "REQ-003"
    covered_by: ["ESC 키 인터랙션"]
  - requirement_id: "REQ-004"
    covered_by: ["breakpoints.mobile"]
```

---

## 완료 조건

- [ ] 기존 디자인 시스템이 분석됨
- [ ] 레이아웃이 정의됨
- [ ] 모든 컴포넌트의 시각 스펙이 정의됨
- [ ] 모든 상태와 인터랙션이 정의됨
- [ ] 접근성이 고려됨
- [ ] 반응형이 고려됨

---

## 금지 사항

- 기존 디자인 시스템 무시
- 접근성(a11y) 생략
- 상태 정의 생략 (hover, focus 등)
- 실제 코드 작성 (implement 단계에서)
