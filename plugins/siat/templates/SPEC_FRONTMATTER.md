# Spec Document Frontmatter 스펙

## 구조

```yaml
---
id: string          # 태스크 식별자 (slug)
steps: string[]     # 남은 스텝들 (현재 포함)
parent: string|null # 이전 단계 문서 경로 (id/step 형식)
children: string[]  # 다음 단계 문서 경로들 (id/step 형식)

# Learning (post-step에서 추가됨)
learn: string[]     # 코드베이스에서 배운 것들
feedback: string[]  # 스텝 프로세스에 대한 피드백
reflected: boolean  # 시스템에 반영됐는지
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
- 형식: `{id}/{step}`
- 루트 문서는 `null`
- 예: `login-page/clarify`, `login-ui/prd`

### children
- 다음 단계의 문서 경로들
- 형식: `{id}/{step}`
- 빈 배열 = 마지막 스텝
- 1개 = 일반 진행
- 2개 이상 = fork

### learn
- 해당 스텝에서 코드베이스/프로젝트에 대해 배운 것들
- 객관적 사실 위주 (패턴, 구조, 컨벤션, 도메인 지식)
- post-step hook(learner agent)이 추가
- 예: `["zustand로 상태관리", "인증은 src/auth/"]`

### feedback
- 해당 스텝의 프로세스/instruction에 대한 피드백
- 유저 의견 (개선점, 좋았던 점)
- 없으면 빈 배열
- 예: `["기술 스택 파악이 더 일찍 됐으면"]`

### reflected
- learn/feedback이 시스템에 반영됐는지
- `false`: 아직 미반영 (review 대기)
- `true`: knowledge/instruction에 반영 완료

## 예시

### 일반 진행 (fork 없음)

```yaml
# specs/login-page/clarify.md
---
id: login-page
steps: [clarify, prd, design, implement, verify]
parent: null
children: [login-page/prd]

learn:
  - "기존 인증은 NextAuth 사용"
  - "src/app/auth/ 구조"
feedback:
  - "요구사항 정리가 명확했음"
reflected: false
---
```

```yaml
# specs/login-page/prd.md
---
id: login-page
steps: [prd, design, implement, verify]
parent: login-page/clarify
children: [login-page/design]

learn:
  - "세션 기반 인증 사용 중"
feedback: []
reflected: false
---
```

```yaml
# specs/login-page/design.md
---
id: login-page
steps: [design, implement, verify]
parent: login-page/prd
children: [login-page/implement]
---
```

### 스텝 스킵

```yaml
# specs/login-ui/clarify.md
---
id: login-ui
steps: [clarify, prd, visual-design, implement, verify]  # design 스킵
parent: null
children: [login-ui/prd]
---
```

```yaml
# specs/login-ui/prd.md
---
id: login-ui
steps: [prd, visual-design, implement, verify]
parent: login-ui/clarify
children: [login-ui/visual-design]  # design 건너뛰고 visual-design
---
```

### Fork

```yaml
# specs/login-system/clarify.md
---
id: login-system
steps: [clarify, prd, design, implement, verify]
parent: null
children: [login-ui/prd, login-api/prd]  # 두 개로 분기
---
```

```yaml
# specs/login-ui/prd.md
---
id: login-ui
steps: [prd, visual-design, implement, verify]
parent: login-system/clarify
children: [login-ui/visual-design]
---
```

```yaml
# specs/login-api/prd.md
---
id: login-api
steps: [prd, design, implement, verify]
parent: login-system/clarify
children: [login-api/design]
---
```

### 마지막 스텝

```yaml
# specs/login-page/verify.md
---
id: login-page
steps: [verify]
parent: login-page/implement
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
