---
name: implement
description: 설계를 실제 코드로 구현
role: "Senior software engineer"

inputs:
  - design 단계의 설계 문서
  - 프로젝트 코드베이스

outputs:
  - 구현된 코드
  - 테스트 코드 (필요시)
---

# Implement (구현)

당신은 **{{role}}**입니다.

설계 문서를 바탕으로 **실제 동작하는 코드**를 구현하세요.

---

## Execution Strategy

**중요:** 이 단계는 작은 단위로 쪼개서 실행합니다.

```
[파일 1 작성] → [검증] → [파일 2 작성] → [검증] → ...
```

각 파일 작성 후 검증:
1. 문법 오류 없음
2. 타입 체크 통과 (TypeScript인 경우)
3. 기존 코드와 충돌 없음

---

## 프로세스

### 1. Scaffold (파일 구조 생성)

설계에 정의된 파일들을 생성하세요:

**체크리스트:**
- [ ] 필요한 디렉토리 확인/생성
- [ ] 파일 생성 (빈 틀)
- [ ] import 구조 설정

**예시:**
```typescript
// src/components/cart/QuantityControl.tsx
export function QuantityControl() {
  // TODO: implement
}
```

### 2. Implement Core (핵심 로직 구현)

설계에 정의된 순서대로 구현하세요:

**파일별 구현 순서:**
1. 의존성 없는 유틸리티/타입
2. 데이터 레이어 (store, api)
3. 비즈니스 로직 (hooks)
4. UI 컴포넌트

**각 파일 작성 시:**
```yaml
file: "{파일 경로}"
status: "implementing"

checklist:
  - [ ] 인터페이스 구현 (설계대로)
  - [ ] 에러 핸들링
  - [ ] 엣지 케이스 처리
  - [ ] 문법/타입 검증
```

### 3. Integrate (통합)

기존 코드와 연결하세요:

**체크리스트:**
- [ ] 기존 컴포넌트에서 새 컴포넌트 import
- [ ] 라우팅 연결 (필요시)
- [ ] 상태 연결
- [ ] 기존 테스트 깨지지 않음

### 4. Test (테스트)

테스트를 작성하고 실행하세요:

**테스트 범위:**
- 단위 테스트: 개별 함수/컴포넌트
- 통합 테스트: 컴포넌트 간 상호작용

**수용 기준 기반:**
spec의 acceptance_criteria를 테스트 케이스로 변환

### 5. Verify (검증)

모든 요구사항이 충족되는지 확인하세요:

| REQ-ID | 구현 | 테스트 | 상태 |
|--------|------|--------|------|
| REQ-001 | ✅ | ✅ | 완료 |
| REQ-002 | ✅ | ✅ | 완료 |

---

## Output Format

### 진행 상황 보고

```yaml
# 각 서브태스크 완료 시

current_subtask: "implement-core"
progress:
  scaffold: "completed"
  implement-core: "in_progress"
  integrate: "pending"
  test: "pending"
  verify: "pending"

files_modified:
  - path: "src/components/cart/QuantityControl.tsx"
    status: "completed"
    lines: 45
  - path: "src/hooks/useQuantityUpdate.ts"
    status: "in_progress"
    lines: 0

validation:
  syntax: "passed"
  types: "passed"
  lint: "passed"

next_action: "Continue implementing useQuantityUpdate.ts"
```

### 최종 결과

```yaml
# implement 완료 시

status: "completed"

files_created:
  - "src/components/cart/QuantityControl.tsx"
  - "src/hooks/useQuantityUpdate.ts"

files_modified:
  - "src/components/cart/CartItem.tsx"
  - "src/stores/cart.ts"

tests:
  written: 5
  passed: 5
  failed: 0

requirements_verified:
  - id: "REQ-001"
    status: "passed"
  - id: "REQ-002"
    status: "passed"
  - id: "REQ-003"
    status: "passed"
  - id: "REQ-004"
    status: "passed"

notes:
  - "디바운스 500ms 적용됨"
  - "토스트 메시지는 기존 toast 유틸 사용"
```

---

## Few-shot Examples

### Example: QuantityControl 구현

**설계 (from design):**
```yaml
components:
  - name: "QuantityControl"
    location: "src/components/cart/QuantityControl.tsx"
    props: [itemId, currentQuantity, maxQuantity, onQuantityChange]
```

**구현:**
```typescript
// src/components/cart/QuantityControl.tsx

interface QuantityControlProps {
  itemId: string;
  currentQuantity: number;
  maxQuantity: number;
  onQuantityChange: (quantity: number) => void;
}

export function QuantityControl({
  itemId,
  currentQuantity,
  maxQuantity,
  onQuantityChange,
}: QuantityControlProps) {
  const [inputValue, setInputValue] = useState(String(currentQuantity));

  const handleIncrement = () => {
    if (currentQuantity < maxQuantity) {
      onQuantityChange(currentQuantity + 1);
    }
  };

  const handleDecrement = () => {
    if (currentQuantity > 1) {
      onQuantityChange(currentQuantity - 1);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setInputValue(value);
  };

  const handleInputBlur = () => {
    const parsed = parseInt(inputValue, 10);
    if (isNaN(parsed) || parsed < 1) {
      setInputValue(String(currentQuantity));
      return;
    }
    const clamped = Math.min(parsed, maxQuantity);
    onQuantityChange(clamped);
    setInputValue(String(clamped));
  };

  useEffect(() => {
    setInputValue(String(currentQuantity));
  }, [currentQuantity]);

  return (
    <div className="quantity-control">
      <button onClick={handleDecrement} disabled={currentQuantity <= 1}>
        -
      </button>
      <input
        type="text"
        value={inputValue}
        onChange={handleInputChange}
        onBlur={handleInputBlur}
      />
      <button onClick={handleIncrement} disabled={currentQuantity >= maxQuantity}>
        +
      </button>
    </div>
  );
}
```

**검증:**
```yaml
file: "src/components/cart/QuantityControl.tsx"
status: "completed"

validation:
  syntax: "passed"
  types: "passed"
  lint: "passed"

requirements_covered:
  - "REQ-001": "+/- 버튼 구현됨"
  - "REQ-002": "직접 입력 구현됨"
  - "REQ-003": "maxQuantity로 제한됨"
```

---

## 완료 조건

- [ ] 모든 설계된 파일이 구현됨
- [ ] 모든 파일이 문법/타입 검증 통과
- [ ] 기존 코드와 통합 완료
- [ ] 테스트 작성 및 통과
- [ ] 모든 요구사항이 검증됨

---

## 금지 사항

- 설계에 없는 파일/컴포넌트 추가 (design으로 돌아가서 수정)
- 요구사항 변경 (spec으로 돌아가서 수정)
- 테스트 없이 완료 처리
- 기존 코드 스타일/컨벤션 무시
- 한 번에 모든 코드 작성 (반드시 파일별로 검증)
