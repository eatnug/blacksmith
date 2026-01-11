---
id: "{task-id}"
steps: [root-cause, fix, verify]
parent: "reproduce/{task-id}"
children: ["fix/{task-id}"]
---

# Root Cause: {버그 제목}

bug_id: "{reproduce에서 연결}"

trace:
  entry_point: "{증상 발생 위치}"
  path:
    - location: "{파일:라인}"
      observation: "{관찰 내용}"
  root_location: "{근본 원인 위치}"

analysis:
  five_whys:
    - why: "왜 {증상}인가?"
      answer: "{답변}"
    - why: "왜 {이전 답변}인가?"
      answer: "{근본 원인}"

  root_cause:
    summary: "{한 줄 요약}"
    category: "code_bug | data_issue | environment | external | race_condition | edge_case"
    detail: |
      {상세 설명}

  contributing_factors:
    - "{기여 요인 1}"
    - "{기여 요인 2}"

impact:
  affected_features:
    - feature: "{기능명}"
      severity: "critical | high | medium | low"
  affected_users: "{영향받는 사용자 범위}"
  data_impact: "{데이터 영향}"
  secondary_issues:
    - "{2차 문제 가능성}"

fix_plan:
  options:
    - id: "A"
      description: "{설명}"
      pros: ["{장점}"]
      cons: ["{단점}"]
      risk: "low | medium | high"
      effort: "low | medium | high"
    - id: "B"
      description: "{설명}"

  recommendation:
    option: "A"
    reason: "{추천 이유}"

  files_to_modify:
    - path: "{파일 경로}"
      change: "{변경 내용 요약}"
