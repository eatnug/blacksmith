# Spec Document Frontmatter 스펙

## 구조

```yaml
---
id: string          # 태스크 식별자 (slug)
steps: string[]     # 남은 스텝들 (현재 포함)
parent: string|null # 이전 단계 문서 경로 (step/id 형식)
children: string[]  # 다음 단계 문서 경로들 (step/id 형식)
---
```

## 필드 설명

### id
- 태스크를 식별하는 고유 slug
- 예: `login-page`, `cart-api`, `auth-bugfix`
- fork 시 자식은 새로운 id를 가짐

### steps
- 이 태스크가 거쳐야 할 **남은 스텝들**
- 첫 번째 요소 = 현재 스텝
- 시스템 steps의 서브셋
- 예: `[spec, design, implement, verify]`

### parent
- 이전 단계의 문서 경로
- 형식: `{step}/{id}`
- 루트 문서는 `null`
- 예: `clarify/login-page`, `spec/login-ui`

### children
- 다음 단계의 문서 경로들
- 형식: `{step}/{id}`
- 빈 배열 = 마지막 스텝
- 1개 = 일반 진행
- 2개 이상 = fork

## 예시

### 일반 진행 (fork 없음)

```yaml
# specs/clarify/login-page.md
---
id: login-page
steps: [clarify, spec, design, implement, verify]
parent: null
children: [spec/login-page]
---
```

```yaml
# specs/spec/login-page.md
---
id: login-page
steps: [spec, design, implement, verify]
parent: clarify/login-page
children: [design/login-page]
---
```

```yaml
# specs/design/login-page.md
---
id: login-page
steps: [design, implement, verify]
parent: spec/login-page
children: [implement/login-page]
---
```

### 스텝 스킵

```yaml
# specs/clarify/login-ui.md
---
id: login-ui
steps: [clarify, spec, visual-design, implement, verify]  # design 스킵
parent: null
children: [spec/login-ui]
---
```

```yaml
# specs/spec/login-ui.md
---
id: login-ui
steps: [spec, visual-design, implement, verify]
parent: clarify/login-ui
children: [visual-design/login-ui]  # design 건너뛰고 visual-design
---
```

### Fork

```yaml
# specs/clarify/login-system.md
---
id: login-system
steps: [clarify, spec, design, implement, verify]
parent: null
children: [spec/login-ui, spec/login-api]  # 두 개로 분기
---
```

```yaml
# specs/spec/login-ui.md
---
id: login-ui
steps: [spec, visual-design, implement, verify]
parent: clarify/login-system
children: [visual-design/login-ui]
---
```

```yaml
# specs/spec/login-api.md
---
id: login-api
steps: [spec, design, implement, verify]
parent: clarify/login-system
children: [design/login-api]
---
```

### 마지막 스텝

```yaml
# specs/verify/login-page.md
---
id: login-page
steps: [verify]
parent: implement/login-page
children: []  # 끝
---
```

## Orchestrator 동작

1. **새 태스크**: clarify부터 시작, `parent: null`
2. **이어서 진행**: 마지막 문서의 `children` 따라감
3. **다음 스텝 결정**: `children[0]`의 step 부분
4. **fork 감지**: `children.length > 1`
5. **완료 감지**: `children: []`

## 규칙

- `steps[0]`은 항상 현재 문서가 속한 스텝과 일치
- `children`의 step은 항상 `steps[1]`과 일치 (있다면)
- fork 시 각 child는 독립적인 `steps`를 가짐
- `parent` 체인을 따라가면 루트(clarify)에 도달
