---
id: "{task-id}"
steps: [visual-design, implement, verify]
parent: "spec/{task-id}"
children: ["implement/{task-id}"]
---

# Visual Design: {태스크 제목}

task: "{태스크 요약}"
version: 1
status: "draft | review | approved"

design_system:
  tokens_used:
    colors:
      - name: "{토큰명}"
        value: "{값}"
        usage: "{사용처}"
    spacing:
      - name: "{토큰명}"
        value: "{값}"
    typography:
      - name: "{토큰명}"
        value: "{값}"

  existing_components:
    - name: "{컴포넌트명}"
      usage: "재사용 | 확장 | 참고"

layout:
  structure: |
    {ASCII 와이어프레임 또는 설명}

  breakpoints:
    - name: "mobile"
      width: "< 768px"
      changes: "{변경사항}"
    - name: "tablet"
      width: "768px - 1024px"
      changes: "{변경사항}"
    - name: "desktop"
      width: "> 1024px"
      changes: "{변경사항}"

components:
  - name: "{컴포넌트명}"
    dimensions:
      width: "{값}"
      height: "{값}"
      padding: "{값}"
      margin: "{값}"

    visual:
      background: "{색상 토큰}"
      border: "{테두리 스펙}"
      border-radius: "{값}"
      shadow: "{그림자 스펙}"

    typography:
      font: "{폰트 토큰}"
      size: "{크기 토큰}"
      weight: "{굵기}"
      color: "{색상 토큰}"

    states:
      default:
        description: "{설명}"
      hover:
        changes: "{변경사항}"
      active:
        changes: "{변경사항}"
      focus:
        changes: "{변경사항}"
      disabled:
        changes: "{변경사항}"

interactions:
  - trigger: "{트리거 이벤트}"
    action: "{동작}"
    transition:
      property: "{속성}"
      duration: "{시간}"
      easing: "{이징}"
    feedback: "{피드백 방식}"

accessibility:
  - concern: "{접근성 고려사항}"
    solution: "{해결 방안}"

requirements_mapping:
  - requirement_id: "REQ-001"
    covered_by: ["{컴포넌트/인터랙션}"]
