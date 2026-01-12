---
id: "{task-id}"
steps: [visual-design, implement, verify]
parent: "{task-id}/prd"
children: ["{task-id}/implement"]
---

# Visual Design: {태스크 제목}

> {태스크 한 줄 요약}

**상태**: draft / review / approved

---

## 디자인 시스템

### 사용 토큰

**Colors**
- `{토큰명}`: {값} - {사용처}

**Spacing**
- `{토큰명}`: {값}

**Typography**
- `{토큰명}`: {값}

### 기존 컴포넌트

- `{컴포넌트명}` - 재사용 / 확장 / 참고

---

## 레이아웃

```
{ASCII 와이어프레임 또는 설명}
```

### 반응형

| 브레이크포인트 | 너비 | 변경사항 |
|---------------|------|----------|
| Mobile | < 768px | {변경사항} |
| Tablet | 768px - 1024px | {변경사항} |
| Desktop | > 1024px | {변경사항} |

---

## 컴포넌트

### {컴포넌트명}

**크기**
- width: {값} / height: {값}
- padding: {값} / margin: {값}

**시각 요소**
- background: `{색상 토큰}`
- border: {테두리 스펙}
- border-radius: {값}
- shadow: {그림자 스펙}

**타이포그래피**
- font: `{폰트 토큰}` / size: `{크기 토큰}`
- weight: {굵기} / color: `{색상 토큰}`

**상태**
- default: {설명}
- hover: {변경사항}
- active: {변경사항}
- focus: {변경사항}
- disabled: {변경사항}

---

## 인터랙션

**{트리거 이벤트}** → {동작}
- transition: {속성} {시간} {이징}
- feedback: {피드백 방식}

---

## 접근성

- {접근성 고려사항} → {해결 방안}

---

## 요구사항 매핑

- REQ-001 → {컴포넌트/인터랙션}
