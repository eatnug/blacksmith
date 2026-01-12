---
id: "{task-id}"
steps: [fix, verify]
parent: "{task-id}/root-cause"
children: ["{task-id}/verify"]
---

# Fix: {버그 제목}

**선택한 옵션**: {A/B/...}

---

## 변경 사항

### `{파일 경로}` (modify / create / delete)

**수정 이유**: {이유}

**Before**
```
{수정 전 코드}
```

**After**
```
{수정 후 코드}
```

---

## 추가된 테스트

- `{테스트 파일 경로}` - {테스트 설명} (regression / edge_case / integration)

---

## 검증

**기존 테스트**: 0 total / 0 passed / 0 failed

**신규 테스트**: 0 total / 0 passed

---

## 사이드 이펙트

- [x] 확인 완료
- 발견된 문제: 없음
