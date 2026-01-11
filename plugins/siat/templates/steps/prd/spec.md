---
id: "{task-id}"
steps: [prd, design, implement, verify]
parent: "clarify/{task-id}"
children: ["design/{task-id}"]
---

# PRD: {태스크 제목}

## 요약

task: "{태스크 요약}"
version: 1
status: "draft | review | approved"

## 요구사항

requirements:
  - id: "REQ-001"
    title: "{요구사항 제목}"
    description: "{상세 설명}"
    priority: "must | should | could"
    acceptance_criteria:
      - given: "{사전 조건}"
        when: "{사용자 행동}"
        then: "{기대 결과}"
    dependencies: []

  - id: "REQ-002"
    # ...

scope:
  in:
    - "{포함 사항}"
  out:
    - "{제외 사항}"

assumptions:
  - "{가정 사항}"

open_questions: []
