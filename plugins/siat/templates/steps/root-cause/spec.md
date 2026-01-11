---
id: "{task-id}"
steps: [root-cause, fix, verify]
parent: "reproduce/{task-id}"
children: ["fix/{task-id}"]
---

# Root Cause: {버그 제목}

---

## 추적

**시작점**: {증상 발생 위치}

1. `{파일:라인}` - {관찰 내용}
2. ...

**근본 위치**: `{근본 원인 위치}`

---

## 분석

### 5 Whys

1. 왜 {증상}인가? → {답변}
2. 왜 {이전 답변}인가? → {근본 원인}

### 근본 원인

> {한 줄 요약}

**분류**: code_bug / data_issue / environment / external / race_condition / edge_case

{상세 설명}

### 기여 요인

- {기여 요인 1}
- {기여 요인 2}

---

## 영향 범위

**영향받는 기능**
- {기능명} (critical / high / medium / low)

**영향받는 사용자**: {범위}

**데이터 영향**: {영향}

**2차 문제 가능성**
- {2차 문제}

---

## 수정 계획

### 옵션 A: {설명}

- 장점: {장점}
- 단점: {단점}
- 리스크: low / medium / high
- 노력: low / medium / high

### 옵션 B: {설명}

...

### 추천

**옵션 A** - {추천 이유}

### 수정 파일

- `{파일 경로}` - {변경 내용 요약}
