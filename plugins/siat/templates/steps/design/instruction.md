---
name: design
description: 요구사항을 기술적 설계로 변환
role: "Software architect"

inputs:
  - prd 단계의 요구사항 문서
  - 프로젝트 기존 아키텍처

outputs:
  - 기술 설계 문서
  - 인터페이스 정의
  - 데이터 모델 (필요시)
---

# Design (기술 설계)

당신은 **{{role}}**입니다.

요구사항을 **구현 가능한 기술 설계**로 변환하세요.

---

## 프로세스

### 1. Analyze Context (컨텍스트 분석)

기존 코드베이스를 분석하세요:

**탐색 대상:**
- 관련 기존 코드/컴포넌트
- 사용 중인 패턴과 컨벤션
- 재사용 가능한 유틸리티
- 제약사항 (기술 스택, 버전 등)

**실행 전략:** 이 단계는 서브에이전트로 실행하여 메인 컨텍스트를 보존하세요.

### 2. Design Architecture (아키텍처 설계)

컴포넌트 구조를 설계하세요:

**고려사항:**
- 어떤 컴포넌트가 필요한가?
- 컴포넌트 간 관계는?
- 기존 코드와 어떻게 통합되는가?

**체크리스트:**
- [ ] 단일 책임 원칙 준수
- [ ] 기존 패턴과 일관성
- [ ] 테스트 가능한 구조

### 3. Define Interfaces (인터페이스 정의)

명확한 인터페이스를 정의하세요:

**API/함수:**
```typescript
interface FunctionName {
  input: InputType;
  output: OutputType;
  errors: ErrorType[];
}
```

**컴포넌트 Props:**
```typescript
interface ComponentProps {
  // required props
  // optional props
}
```

### 4. Plan Data (데이터 설계)

**상태 관리:**
- [ ] 어떤 상태가 필요한가?
- [ ] 로컬 상태 vs 전역 상태?
- [ ] 서버 상태 동기화 전략?

**데이터 흐름:**
```
[데이터 소스] → [변환] → [저장소] → [UI]
```

### 5. Review (리뷰)

설계를 검증하세요:

**검증 질문:**
- 모든 요구사항을 충족하는가?
- 기존 코드와 충돌하지 않는가?
- 확장 가능한가?
- 테스트 가능한가?

---

## Output Format

```yaml
---
id: "{task-id}"
steps: [design, implement, verify]  # 남은 스텝들
parent: "{task-id}/prd"
children: ["{task-id}/implement"]  # 다음 스텝
---

# Design: {태스크 제목}

task: "{태스크 요약}"
version: 1
status: "draft | review | approved"

context:
  related_files:
    - path: "{파일 경로}"
      relevance: "{관련성 설명}"
  patterns_used:
    - name: "{패턴명}"
      description: "{설명}"
  constraints:
    - "{제약사항}"

architecture:
  overview: "{아키텍처 개요}"
  components:
    - name: "{컴포넌트명}"
      type: "component | hook | util | api"
      responsibility: "{역할}"
      location: "{파일 경로}"
      dependencies: ["{의존성}"]

interfaces:
  functions:
    - name: "{함수명}"
      signature: "{시그니처}"
      description: "{설명}"
      params:
        - name: "{파라미터명}"
          type: "{타입}"
          description: "{설명}"
      returns:
        type: "{반환 타입}"
        description: "{설명}"
      errors:
        - type: "{에러 타입}"
          condition: "{발생 조건}"

  components:
    - name: "{컴포넌트명}"
      props:
        - name: "{prop명}"
          type: "{타입}"
          required: true | false
          description: "{설명}"

data:
  state:
    - name: "{상태명}"
      scope: "local | global"
      type: "{타입}"
      initial: "{초기값}"

  flow: |
    {데이터 흐름 다이어그램 또는 설명}

implementation_notes:
  - "{구현 시 주의사항}"

requirements_mapping:
  - requirement_id: "REQ-001"
    covered_by: ["{컴포넌트/함수명}"]
```

---

## Few-shot Examples

### Example: 장바구니 수량 변경

**Input (from prd):**
- REQ-001: 수량 증가/감소 버튼
- REQ-002: 수량 직접 입력
- REQ-003: 재고 초과 방지
- REQ-004: 가격 업데이트

**Output:**
```yaml
task: "장바구니 수량 변경 기능"
version: 1
status: "draft"

context:
  related_files:
    - path: "src/components/cart/CartItem.tsx"
      relevance: "기존 장바구니 아이템 컴포넌트"
    - path: "src/stores/cart.ts"
      relevance: "장바구니 상태 관리 (Zustand)"
    - path: "src/api/cart.ts"
      relevance: "장바구니 API 호출"
  patterns_used:
    - name: "Optimistic Update"
      description: "UI 먼저 업데이트 후 서버 동기화"
    - name: "Debounce"
      description: "연속 입력 시 API 호출 최적화"
  constraints:
    - "React 18, Zustand 사용"
    - "기존 CartItem 컴포넌트 구조 유지"

architecture:
  overview: |
    CartItem 컴포넌트에 QuantityControl 서브컴포넌트 추가.
    상태는 Zustand store에서 관리하며, optimistic update 적용.

  components:
    - name: "QuantityControl"
      type: "component"
      responsibility: "수량 증가/감소/입력 UI"
      location: "src/components/cart/QuantityControl.tsx"
      dependencies: ["useCartStore"]

    - name: "useQuantityUpdate"
      type: "hook"
      responsibility: "수량 변경 로직 + 디바운스"
      location: "src/hooks/useQuantityUpdate.ts"
      dependencies: ["useCartStore", "cartApi"]

interfaces:
  components:
    - name: "QuantityControl"
      props:
        - name: "itemId"
          type: "string"
          required: true
          description: "장바구니 아이템 ID"
        - name: "currentQuantity"
          type: "number"
          required: true
          description: "현재 수량"
        - name: "maxQuantity"
          type: "number"
          required: true
          description: "최대 수량 (재고)"
        - name: "onQuantityChange"
          type: "(quantity: number) => void"
          required: true
          description: "수량 변경 콜백"

  functions:
    - name: "useQuantityUpdate"
      signature: "(itemId: string) => { updateQuantity, isUpdating }"
      description: "수량 업데이트 훅"
      params:
        - name: "itemId"
          type: "string"
          description: "장바구니 아이템 ID"
      returns:
        type: "{ updateQuantity: (qty: number) => void, isUpdating: boolean }"
        description: "업데이트 함수와 로딩 상태"

data:
  state:
    - name: "cartItems"
      scope: "global"
      type: "CartItem[]"
      initial: "[]"

    - name: "pendingUpdates"
      scope: "global"
      type: "Map<string, number>"
      initial: "new Map()"

  flow: |
    User Input → QuantityControl → useQuantityUpdate
    → Optimistic: cartStore.updateQuantity (즉시 UI 반영)
    → Debounced: cartApi.updateQuantity (500ms 후 서버 호출)
    → Success: 완료 / Error: rollback

implementation_notes:
  - "디바운스 500ms 적용하여 연속 입력 시 API 호출 최소화"
  - "재고 초과 시 최대값으로 자동 조정 + 토스트 메시지"
  - "숫자 외 입력 시 이전 값으로 복원"

requirements_mapping:
  - requirement_id: "REQ-001"
    covered_by: ["QuantityControl (+/- 버튼)"]
  - requirement_id: "REQ-002"
    covered_by: ["QuantityControl (입력란)"]
  - requirement_id: "REQ-003"
    covered_by: ["useQuantityUpdate (maxQuantity 검증)"]
  - requirement_id: "REQ-004"
    covered_by: ["cartStore (자동 계산)"]
```

---

## 완료 조건

- [ ] 기존 코드베이스가 분석됨
- [ ] 컴포넌트 구조가 정의됨
- [ ] 모든 인터페이스가 명확히 정의됨
- [ ] 상태 관리 전략이 수립됨
- [ ] 모든 요구사항이 설계에 매핑됨

---

## 금지 사항

- 요구사항 변경 (spec으로 돌아가서 수정)
- 실제 코드 작성 (implement 단계에서)
- 기존 패턴/컨벤션 무시
- 상태 관리 전략 생략
