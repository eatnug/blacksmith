---
id: "{task-id}"
steps: [fix, verify]
parent: "root-cause/{task-id}"
children: ["verify/{task-id}"]
---

# Fix: {버그 제목}

bug_id: "{연결된 버그 ID}"
fix_option: "{선택한 옵션 (A/B/...)}"

changes:
  - file: "{파일 경로}"
    type: "modify | create | delete"
    before: |
      {수정 전 코드 (발췌)}
    after: |
      {수정 후 코드}
    reason: "{수정 이유}"

tests_added:
  - file: "{테스트 파일 경로}"
    description: "{테스트 설명}"
    type: "regression | edge_case | integration"

validation:
  existing_tests:
    total: 0
    passed: 0
    failed: 0
  new_tests:
    total: 0
    passed: 0

side_effects:
  checked: true
  issues_found: []
