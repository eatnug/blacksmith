---
id: "{task-id}"
steps: [design, implement, verify]
parent: "prd/{task-id}"
children: ["implement/{task-id}"]
---

# Design: {태스크 제목}

task: "{태스크 요약}"
version: 1
status: "draft | review | approved"

context:
  related_files:
    - path: "{파일 경로}"
      relevance: "{관련성 설명}"
  patterns_used:
    - name: "{패턴명}"
      description: "{설명}"
  constraints:
    - "{제약사항}"

architecture:
  overview: "{아키텍처 개요}"
  components:
    - name: "{컴포넌트명}"
      type: "component | hook | util | api"
      responsibility: "{역할}"
      location: "{파일 경로}"
      dependencies: ["{의존성}"]

interfaces:
  functions:
    - name: "{함수명}"
      signature: "{시그니처}"
      description: "{설명}"
      params:
        - name: "{파라미터명}"
          type: "{타입}"
          description: "{설명}"
      returns:
        type: "{반환 타입}"
        description: "{설명}"
      errors:
        - type: "{에러 타입}"
          condition: "{발생 조건}"

  components:
    - name: "{컴포넌트명}"
      props:
        - name: "{prop명}"
          type: "{타입}"
          required: true | false
          description: "{설명}"

data:
  state:
    - name: "{상태명}"
      scope: "local | global"
      type: "{타입}"
      initial: "{초기값}"

  flow: |
    {데이터 흐름 다이어그램 또는 설명}

implementation_notes:
  - "{구현 시 주의사항}"

requirements_mapping:
  - requirement_id: "REQ-001"
    covered_by: ["{컴포넌트/함수명}"]
