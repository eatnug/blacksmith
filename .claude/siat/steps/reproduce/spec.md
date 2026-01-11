---
id: "{task-id}"
steps: [reproduce, root-cause, fix, verify]
parent: "clarify/{task-id}"
children: ["root-cause/{task-id}"]
---

# Reproduce: {버그 제목}

bug_report:
  title: "{버그 제목}"
  reporter: "{보고자}"
  reported_at: "{보고 일시}"

environment:
  browser: "{브라우저 및 버전}"
  os: "{운영체제}"
  app_version: "{앱 버전}"
  other: "{기타 환경 정보}"

reproduction:
  frequency: "always | sometimes | rare"
  steps:
    - step: 1
      action: "{행동}"
      expected: "{기대 결과}"
      actual: "{실제 결과}"
    - step: 2
      action: "{행동}"

symptoms:
  error_message: "{에러 메시지}"
  console_errors:
    - "{콘솔 에러 1}"
  network_issues:
    - request: "{요청}"
      response: "{응답}"
      issue: "{문제}"
  ui_state: "{UI 상태 설명}"

isolation:
  data_specific: true | false
  user_specific: true | false
  environment_specific: true | false
  notes: "{범위 관련 메모}"

screenshots: []

confirmed_reproducible: true | false
