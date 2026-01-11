# Knowledge Template

이 파일은 `.claude/knowledge/` 디렉토리에 생성되는 지식 문서의 템플릿입니다.

---

## 디렉토리 구조

```
.claude/knowledge/
├── architecture.md      # 전체 아키텍처
├── conventions.md       # 코딩 컨벤션
├── domains/             # 도메인별 지식
│   ├── {domain}.md
│   └── ...
├── decisions.md         # 주요 결정사항 (ADR)
└── patterns.md          # 자주 사용하는 패턴
```

---

## 도메인 문서 템플릿

```markdown
# {도메인명} 시스템

> 마지막 업데이트: {날짜}

## 개요

{한 줄 설명}

## 구조

| 구성요소 | 위치 | 역할 |
|---------|------|------|
| {컴포넌트/모듈} | {파일 경로} | {역할 설명} |

## 데이터 흐름

```
{데이터 흐름 다이어그램 또는 설명}
```

## 주요 결정사항

| 날짜 | 결정 | 이유 | 관련 워크플로우 |
|------|------|------|----------------|
| {날짜} | {결정 내용} | {이유} | {워크플로우 ID} |

## 주의사항

- {주의할 점 1}
- {주의할 점 2}

## 관련 워크플로우

- {날짜}: {워크플로우 요약} ({워크플로우 ID})
```

---

## 예시: cart.md

```markdown
# 장바구니 시스템

> 마지막 업데이트: 2024-01-10

## 개요

사용자의 장바구니를 관리하는 시스템. 상품 추가/삭제/수량 변경 기능 제공.

## 구조

| 구성요소 | 위치 | 역할 |
|---------|------|------|
| CartStore | src/stores/cart.ts | 장바구니 상태 관리 (Zustand) |
| CartItem | src/components/cart/CartItem.tsx | 개별 상품 표시 |
| QuantityControl | src/components/cart/QuantityControl.tsx | 수량 조절 UI |
| useQuantityUpdate | src/hooks/useQuantityUpdate.ts | 수량 변경 로직 |
| cartApi | src/api/cart.ts | 장바구니 API 호출 |

## 데이터 흐름

```
User Action → QuantityControl → useQuantityUpdate
                                      ↓
                            Optimistic Update (CartStore)
                                      ↓
                            Debounced API Call (500ms)
                                      ↓
                            Server Sync / Rollback on Error
```

## 주요 결정사항

| 날짜 | 결정 | 이유 | 관련 워크플로우 |
|------|------|------|----------------|
| 2024-01-10 | Optimistic Update 적용 | 빠른 UX 제공 | 2024-01-10-cart-quantity |
| 2024-01-10 | 디바운스 500ms | API 호출 최적화 | 2024-01-10-cart-quantity |
| 2024-01-05 | Zustand 사용 | 간단한 상태 관리 | 2024-01-05-cart-page |

## 주의사항

- 재고 검증은 서버에서도 수행 (프론트엔드 검증만 믿지 않기)
- 비로그인 사용자는 localStorage 사용
- 로그인 시 localStorage → 서버 동기화 필요

## 관련 워크플로우

- 2024-01-10: 수량 변경 기능 (2024-01-10-cart-quantity)
- 2024-01-05: 장바구니 페이지 UI (2024-01-05-cart-page)
- 2024-01-03: 장바구니 API 연동 (2024-01-03-cart-api)
```

---

## 아키텍처 문서 템플릿

```markdown
# 프로젝트 아키텍처

> 마지막 업데이트: {날짜}

## 기술 스택

| 영역 | 기술 | 버전 |
|------|------|------|
| Frontend | React | 18.x |
| State | Zustand | 4.x |
| Styling | Tailwind CSS | 3.x |
| API | REST / tRPC | - |
| Backend | Node.js / Next.js | - |
| Database | PostgreSQL | - |

## 디렉토리 구조

```
src/
├── components/     # UI 컴포넌트
├── pages/          # 페이지 컴포넌트
├── hooks/          # 커스텀 훅
├── stores/         # 상태 관리 (Zustand)
├── api/            # API 호출
├── types/          # TypeScript 타입
└── utils/          # 유틸리티
```

## 핵심 패턴

### 상태 관리
- 전역 상태: Zustand
- 서버 상태: React Query (또는 SWR)
- 로컬 상태: useState

### API 호출
- Optimistic Update 패턴
- Error Boundary로 에러 처리

### 컴포넌트 구조
- Compound Component 패턴
- Render Props (필요시)
```

---

## 컨벤션 문서 템플릿

```markdown
# 코딩 컨벤션

## 네이밍

| 대상 | 규칙 | 예시 |
|------|------|------|
| 컴포넌트 | PascalCase | `CartItem.tsx` |
| 훅 | camelCase, use 접두사 | `useQuantityUpdate.ts` |
| 유틸 | camelCase | `formatPrice.ts` |
| 상수 | SCREAMING_SNAKE_CASE | `MAX_QUANTITY` |
| 타입 | PascalCase | `CartItemType` |

## 파일 구조

```typescript
// 1. imports (external → internal → types)
import { useState } from 'react';
import { useCartStore } from '@/stores/cart';
import type { CartItem } from '@/types';

// 2. types/interfaces
interface Props {
  // ...
}

// 3. component
export function ComponentName({ ...props }: Props) {
  // hooks
  // derived state
  // handlers
  // render
}
```

## Git 커밋 메시지

```
{type}: {subject}

{body}
```

Types: feat, fix, refactor, style, docs, test, chore
```
