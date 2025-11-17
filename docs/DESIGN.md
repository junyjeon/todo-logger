# Todo-Logger 시스템 설계

최종 수정: 2025-10-28

## 목적

TodoWrite 작업을 자동으로 파일에 기록함. Git commit 메시지 작성 시 해당 날짜 파일을 열어서 작업 내용을 참고할 수 있음.

## 구조

```
/home/jun/.claude/
├── agents/todo-logger.md        # 처리 로직, 파일 포맷, 언어 감지
├── MODES.md                      # TodoWrite 후 즉시 호출 (MANDATORY)
├── RULES.md                      # 재시도 로직, 에러 처리
└── todo-history/
    ├── sessions/                 # 시간순 상세 기록
    ├── by-date/                  # 날짜별 최신 상태
    └── archive/                  # 레거시 보관
```

## 실행 흐름

```
TodoWrite 작업 완료
  ↓
Task tool로 todo-logger sub-agent 즉시 호출 (MANDATORY)
  ↓
sessions 파일에 append
  ↓
by-date 파일에서 현재 세션 섹션만 덮어쓰기
  ↓
"✅ Recorded: N tasks" 출력
```

## 파일 포맷

### sessions/{session_id}.md

```markdown
# Session: 20251028-143045

Started: 2025-10-28 14:30:45
Last Activity: 2025-10-28 14:30:45

---

## TodoWrite 14:30:45

### English
- 🔄 Implement authentication

### Korean (한국어)
- 🔄 인증 구현
```

한 세션의 모든 TodoWrite를 시간순으로 누적 기록함. Last Activity는 매 TodoWrite마다 현재 시간으로 업데이트됨.

### by-date/{date}.md

```markdown
# 2025-10-28

## [251028-143045](../sessions/20251028-143045.md)  (14:30:45)

### English
- 🔄 Implement authentication

### Korean (한국어)
- 🔄 인증 구현

---
```

해당 날짜의 모든 세션을 집계함. 매 TodoWrite마다 현재 세션 섹션만 최신 상태로 덮어씀. 다른 세션들은 그대로 유지됨. 링크를 클릭하면 sessions 파일로 이동하여 전체 이력을 볼 수 있음.

## 핵심 규칙

### 세션 ID

형식은 `YYYYMMDD-HHMMSS`임. Sub-agent가 현재 타임스탬프로 직접 생성함.

### 언어 처리

- 순수 한국어: Korean 섹션만 기록
- 순수 영어: English 섹션 + Korean 섹션에 번역 기록
- 혼합 (한글+영어): Korean 섹션에 원문 그대로 기록
  - 예: "Implement 인증 기능" → "Implement 인증 기능"

### Emoji 상태

✅ completed | 🔄 in_progress | 🕐 pending | 🚧 blocked

### 중복 감지

같은 세션 내에서만 중복을 감지함. 같은 작업이 이미 기록되어 있으면 건너뜀. 단, 상태 변경(pending → in_progress → completed)은 허용됨.

### 에러 처리

모든 실패 상황에서 메인 워크플로우를 차단하지 않고 계속 진행함. Sub-agent 실패 시 1회 재시도하고, 재시도도 실패하면 에러만 로그하고 넘어감.

## 구현 정보

### 권한

`/home/jun/.claude/todo-history/**` 경로의 모든 파일 작업이 자동 승인됨. 사용자 확인을 요청하지 않음.

### Sub-agent 도구

Read, Write, Edit, Bash

### 번역 가이드

- review → 리뷰
- test → 테스트
- integration → 통합

자연스러운 한국어 표현을 우선함.

## 제한사항

중복 감지는 같은 세션 내에서만 작동함. 동시 쓰기 시 충돌이 발생할 수 있으나 Edit 도구 사용으로 완화됨.

## 예시

**입력**:
```json
[
  {"content": "Implement auth", "status": "in_progress"},
  {"content": "테스트 작성", "status": "pending"}
]
```

**결과 sessions/20251028-143045.md**:
```markdown
## TodoWrite 14:30:45

### English
- 🔄 Implement auth

### Korean (한국어)
- 🔄 인증 구현
- 🕐 테스트 작성
```

**결과 by-date/2025-10-28.md**:
```markdown
## [251028-143045](../sessions/20251028-143045.md)  (14:30:45)

### English
- 🔄 Implement auth

### Korean (한국어)
- 🔄 인증 구현
- 🕐 테스트 작성
```

---

설계 철학: 간결함 | 실용성
