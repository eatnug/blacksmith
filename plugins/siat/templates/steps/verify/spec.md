---
id: "{task-id}"
steps: [verify]
parent: "implement/{task-id}"
children: []
---

# Verify: {태스크 제목}

---

## 버그 검증 (버그픽스인 경우)

- [x] 수정 전 재현 확인
- [x] 수정 후 해결 확인

**검증 단계**
1. {행동} → pass / fail

---

## 회귀 테스트

### 자동화

| 종류 | Total | Passed | Failed |
|------|-------|--------|--------|
| Unit | 0 | 0 | 0 |
| Integration | 0 | 0 | 0 |
| E2E | 0 | 0 | 0 |

### 수동

- {기능} - {테스트 항목} → pass / fail

---

## 문서화

- [ ] Changelog
- [ ] 내부 문서
- [ ] 사용자 문서

---

## 릴리즈 준비

- [ ] 코드 리뷰 (approved / pending / not_required)
- [ ] 테스트 통과
- [ ] 문서화 완료
- [ ] 롤백 플랜

---

## 결론

**상태**: verified / failed / needs_attention

{추가 메모}
