---
id: "{task-id}"
steps: [verify]
parent: "implement/{task-id}"
children: []
---

# Verify: {태스크 제목}

bug_id: "{연결된 버그 ID}"

verification:
  original_bug:
    reproduced_before_fix: true
    fixed_after_change: true
    steps_verified:
      - step: 1
        action: "{행동}"
        result: "pass | fail"

regression:
  automated:
    unit_tests:
      total: 0
      passed: 0
      failed: 0
    integration_tests:
      total: 0
      passed: 0
      failed: 0
    e2e_tests:
      total: 0
      passed: 0
      failed: 0

  manual:
    - feature: "{기능}"
      test_case: "{테스트 항목}"
      result: "pass | fail"
      notes: "{메모}"

documentation:
  changelog_updated: true
  internal_docs_updated: true
  user_facing_docs_updated: false

release_readiness:
  code_review: "approved | pending | not_required"
  tests_passing: true
  documentation_complete: true
  rollback_plan: true
  ready_to_release: true

summary:
  status: "verified | failed | needs_attention"
  notes: "{추가 메모}"
