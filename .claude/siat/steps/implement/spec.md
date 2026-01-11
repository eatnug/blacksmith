---
id: "{task-id}"
steps: [implement, verify]
parent: "design/{task-id}"
children: ["verify/{task-id}"]
---

# Implement: {태스크 제목}

## 진행 상황

current_subtask: "scaffold | implement-core | integrate | test | verify"
progress:
  scaffold: "pending | in_progress | completed"
  implement-core: "pending | in_progress | completed"
  integrate: "pending | in_progress | completed"
  test: "pending | in_progress | completed"
  verify: "pending | in_progress | completed"

## 파일 변경

files_created:
  - "{파일 경로}"

files_modified:
  - path: "{파일 경로}"
    status: "pending | in_progress | completed"
    lines: 0

## 검증

validation:
  syntax: "pending | passed | failed"
  types: "pending | passed | failed"
  lint: "pending | passed | failed"

## 테스트

tests:
  written: 0
  passed: 0
  failed: 0

## 요구사항 검증

requirements_verified:
  - id: "REQ-001"
    status: "pending | passed | failed"
  - id: "REQ-002"
    status: "pending | passed | failed"

## 메모

notes:
  - "{구현 중 발견한 사항}"
