# Constitution

프로젝트 전역에서 적용되는 원칙입니다. 모든 스텝에서 이 문서를 참조합니다.

---

## 불명확 처리 원칙

정보가 부족하거나 여러 해석이 가능한 경우:

1. **추측하지 않는다**
2. **`[NEEDS CLARIFICATION: 구체적 질문]` 마커를 붙인다**
3. **마커가 있는 상태로 다음 단계 진행 불가**

### 예시

```markdown
## 요구사항
- 사용자 인증 기능 구현
- 소셜 로그인 지원 [NEEDS CLARIFICATION: Google만 지원? Apple도 필요?]
- 세션 유지 [NEEDS CLARIFICATION: 유지 시간은 얼마로?]
```

### 마커 해결

사용자가 답변하면 마커를 제거하고 내용을 반영합니다:

```markdown
## 요구사항
- 사용자 인증 기능 구현
- 소셜 로그인 지원 (Google, Apple)
- 세션 유지 (7일)
```

---

## 프로젝트 원칙

- 플러그인 수정 시 `plugins/` 원본만 수정 (`.claude/`는 심볼릭 링크)
- 버전 변경 시 `plugin.json`과 `marketplace.json` 모두 업데이트
- 템플릿 변경은 `.claude/siat/`에 자동 반영되지 않음 (수동 확인 필요)
