# Todo-Logger

> **AI 기반 개발을 위한 영속적 작업 히스토리**
> 일시적인 AI 대화와 영속적인 프로젝트 메모리 사이의 간극을 메웁니다.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Compatible-green.svg)](https://github.com/anthropics/claude-code)
[![Status: Production](https://img.shields.io/badge/Status-Production-success.svg)]()

**[English](README.md)** | **한국어**

## 🎯 문제점

Claude Code 같은 AI 어시스턴트와 작업할 때, 작업 목록은 현재 세션에만 존재합니다. 대화가 끝나면:

- ✗ 작업 히스토리가 사라짐
- ✗ 어제 무엇을 했는지 참조 불가
- ✗ Git 커밋 메시지를 수동으로 재구성해야 함
- ✗ 세션 간 검색 가능한 작업 아카이브 없음
- ✗ 팀원들이 AI 기반 작업 진행 상황을 볼 수 없음

## 💡 솔루션

**Todo-Logger**는 AI 세션 중 모든 작업 목록 업데이트를 자동으로 캡처하여 구조화된 마크다운 파일로 영속화합니다. 이를 통해 AI 어시스턴트가 추적한 모든 작업의 영구적이고 검색 가능한 기록을 생성합니다.

### 주요 기능

🔄 **자동 영속화** - TodoWrite 작업의 무노력 로깅
🌐 **이중언어 지원** - 자동 영어 ↔ 한국어 번역
📝 **Git 친화적 포맷** - 커밋 메시지 참조에 완벽한 마크다운 파일
📊 **이중 구조** - 시간순(세션)과 날짜 기반 뷰 모두 제공
🤖 **네이티브 통합** - 원활한 Claude Code 서브에이전트 아키텍처
⚡ **실시간 로깅** - 최소 오버헤드로 2초 미만 실행
🔍 **검색 가능한 히스토리** - 빠른 조회를 위한 grep 친화적 포맷
🎯 **스마트 중복 제거** - 세션 내 중복 항목 방지

## 🏗️ 아키텍처

### 시스템 개요

```
┌─────────────────────────────────────────────────────────────┐
│                     Claude Code 세션                         │
│                                                               │
│  ┌──────────────┐         ┌─────────────────┐              │
│  │  TodoWrite   │────────▶│  Todo-Logger    │              │
│  │  작업        │         │   서브에이전트   │              │
│  └──────────────┘         └────────┬────────┘              │
│                                     │                        │
└─────────────────────────────────────┼────────────────────────┘
                                      ▼
                    ┌─────────────────────────────────┐
                    │    영속 스토리지 레이어          │
                    │                                 │
                    │  ┌──────────────────────────┐  │
                    │  │  sessions/               │  │
                    │  │  - 20251104-013244.md    │  │
                    │  │  - 20251104-020156.md    │  │
                    │  │  (시간순 상세 기록)       │  │
                    │  └──────────────────────────┘  │
                    │                                 │
                    │  ┌──────────────────────────┐  │
                    │  │  by-date/                │  │
                    │  │  - 2025-11-04.md         │  │
                    │  │  - 2025-11-03.md         │  │
                    │  │  (일일 집계)              │  │
                    │  └──────────────────────────┘  │
                    └─────────────────────────────────┘
```

### 핵심 컴포넌트

**1. 에이전트 정의** ([`agent/todo-logger.md`](agent/todo-logger.md))
- 언어 감지 및 번역 로직
- 이중 포맷 파일 작업
- 중복 감지
- 에러 처리 및 복구

**2. 스토리지 구조**
```
todo-history/
├── sessions/           # 시간순 세션 로그
│   ├── 20251104-013244.md
│   └── 20251104-020156.md
├── by-date/           # 일일 집계 뷰
│   ├── 2025-11-04.md
│   └── 2025-11-03.md
└── archive/           # 과거 백업
```

**3. 통합 프로토콜**
- 모든 TodoWrite 후 필수 호출
- `todo-logger` 서브에이전트 타입으로 Task 도구 사용
- 실패 시 자동 재시도 (1회)
- 논블로킹 에러 처리

## 🚀 빠른 시작

### 설치

**1. 에이전트 정의 복사**
```bash
cp agent/todo-logger.md ~/.claude/agents/
```

**2. 스토리지 디렉토리 생성**
```bash
mkdir -p ~/.claude/todo-history/{sessions,by-date,archive}
```

**3. Claude Code 권한 설정**

Claude Code 설정(`~/.claude/settings.json`)에서 todo-history 경로 권한 허용:

```json
{
  "autoApprovedTools": [
    "Read(~/.claude/todo-history/**)",
    "Write(~/.claude/todo-history/**)",
    "Edit(~/.claude/todo-history/**)"
  ]
}
```

**4. Claude Code 설정**

`~/.claude/MODES.md`에 추가:

```markdown
### 필수 todo-logger 통합

**중요**: 모든 TodoWrite 작업 후에는 todo-logger 에이전트 호출이 필수입니다.

**호출 패턴**:
```
<TodoWrite 작업 완료>
→ 즉시 Task 도구로 todo-logger 에이전트 호출
→ 현재 TodoList 상태를 에이전트에 전달
→ 진행하기 전에 로깅 성공 확인
```
```

### 검증

테스트 TodoWrite 작업을 실행하고 파일 생성 확인:

```bash
ls -lh ~/.claude/todo-history/sessions/
ls -lh ~/.claude/todo-history/by-date/
```

## 📖 사용법

### 자동 호출

Todo-Logger는 모든 TodoWrite 작업 후 자동으로 실행됩니다. 수동 개입이 필요하지 않습니다.

**예제 흐름:**
```
사용자: "인증 기능 구현 도와줘"

Claude: <TodoWrite로 작업 목록 생성>
        <자동으로 todo-logger 서브에이전트 호출>
        "✅ 기록됨: 3개 작업"
```

### 파일 포맷

**세션 로그** (`sessions/20251104-013244.md`):
```markdown
# Session: 20251104-013244

Started: 2025-11-04 01:32:44
Last Activity: 2025-11-04 01:35:12

---

## TodoWrite 01:32:44

### English
- 🔄 Implement authentication system
- 🕐 Write unit tests
- 🕐 Update documentation

### Korean (한국어)
- 🔄 인증 시스템 구현
- 🕐 단위 테스트 작성
- 🕐 문서 업데이트

## TodoWrite 01:35:12

### English
- ✅ Implement authentication system
- 🔄 Write unit tests
- 🕐 Update documentation

### Korean (한국어)
- ✅ 인증 시스템 구현
- 🔄 단위 테스트 작성
- 🕐 문서 업데이트
```

**일일 집계** (`by-date/2025-11-04.md`):
```markdown
# 2025-11-04

## Session: [20251104-013244](../sessions/20251104-013244.md) (01:32:44)

### English
- ✅ Implement authentication system
- 🔄 Write unit tests
- 🕐 Update documentation

### Korean (한국어)
- ✅ 인증 시스템 구현
- 🔄 단위 테스트 작성
- 🕐 문서 업데이트

---

## Session: [20251104-020156](../sessions/20251104-020156.md) (02:01:56)

### English
- ✅ Write unit tests
- 🔄 Update documentation

### Korean (한국어)
- ✅ 단위 테스트 작성
- 🔄 문서 업데이트
```

### 상태 이모지 매핑

- ✅ `completed` - 작업 성공적으로 완료
- 🔄 `in_progress` - 현재 작업 중
- 🕐 `pending` - 미래 작업 대기 중
- 🚧 `blocked` - 의존성 또는 외부 요인 대기 중

## 🌐 이중언어 지원

### 언어 감지 규칙

**1. 순수 한국어** → 한국어 섹션만 기록
```
입력: "데이터베이스 설계"
출력: 원문 그대로 한국어 섹션에 기록
```

**2. 순수 영어** → 영어 + 한국어로 자동 번역
```
입력: "Implement database schema"
출력:
- English: "Implement database schema"
- Korean: "데이터베이스 스키마 구현"
```

**3. 혼합 (한국어 + 영어)** → 한국어 섹션에 그대로 기록
```
입력: "Implement 데이터베이스 설계"
출력: 한국어 섹션에 "Implement 데이터베이스 설계"
```

### 번역 가이드라인

일반적인 기술 용어:
- `review` → `리뷰` (검토 아님)
- `test` → `테스트`
- `integration` → `통합`
- `implementation` → `구현`
- `refactoring` → `리팩토링`

## 🔧 통합

### Claude Code 통합

자세한 통합 가이드는 [`docs/INTEGRATION.md`](docs/INTEGRATION.md)를 참조하세요.

**최소 통합:**

Claude Code 시스템 프롬프트 또는 MODES.md에 추가:

```markdown
모든 TodoWrite 작업 후, 즉시:

Task 도구 호출 → subagent_type: "todo-logger" → 현재 TodoList 상태 전달
```

### 수동 호출 (테스트용)

자동 호출이 권장되지만, 수동으로 트리거할 수도 있습니다:

```javascript
// Claude Code 세션에서
{
  "tool": "Task",
  "subagent_type": "todo-logger",
  "description": "현재 작업 로깅",
  "prompt": "현재 TodoList 상태 기록: [작업 내용]"
}
```

## 📊 사용 사례

### 1. Git 커밋 메시지

```bash
# 커밋 전에 오늘의 로그 열기
cat ~/.claude/todo-history/by-date/$(date +%Y-%m-%d).md

# 작업 설명을 커밋 메시지로 사용
git commit -m "feat: 인증 시스템 구현

- 사용자 등록 엔드포인트 완료
- JWT 토큰 생성 추가
- bcrypt로 비밀번호 해싱 구현

작업 추적: todo-history/sessions/20251104-013244.md"
```

### 2. 일일 스탠드업 보고

```bash
# 어제의 성과
cat ~/.claude/todo-history/by-date/2025-11-03.md | grep "✅"

# 오늘의 계획
cat ~/.claude/todo-history/by-date/2025-11-04.md | grep "🔄\|🕐"
```

### 3. 프로젝트 회고

```bash
# 특정 기능 작업 검색
grep -r "인증" ~/.claude/todo-history/sessions/

# 이번 주 완료된 작업 수 세기
grep -r "✅" ~/.claude/todo-history/by-date/ | wc -l
```

### 4. 팀 투명성

```bash
# AI 세션 성과 공유
git add .claude/todo-history/
git commit -m "docs: 인증 작업으로 todo-history 업데이트"
git push

# 팀원들이 AI 기반 개발 진행 상황 검토 가능
```

## 🎨 설정

### 커스텀 스토리지 위치

`~/.claude/agents/todo-logger.md` 편집:

```markdown
3. File Operations - sessions/
   - Primary target: `/custom/path/todo-history/sessions/{session_id}.md`

4. File Operations - by-date/
   - Secondary target: `/custom/path/todo-history/by-date/{YYYY-MM-DD}.md`
```

**스토리지 디렉토리 생성:**
```bash
mkdir -p /custom/path/todo-history/{sessions,by-date,archive}
```

### 커스텀 세션 ID 포맷

**기본값:** `YYYYMMDD-HHMMSS` (예: `20251104-013244`)

**UUID 포맷 사용**하려면, 세션 ID 생성 로직 수정:

```markdown
1. Extract Session Info
   - Generate session ID: 타임스탬프 대신 UUID 사용
   - Example: `uuid.uuid4()` → `a1b2c3d4-e5f6-...`
```

### 언어 설정

**기본값:** 영어 → 한국어 번역 활성화

**번역 비활성화** (영어 전용 모드):

```markdown
2. Language Detection
   - Pure English → 영어 섹션만 기록 (번역 안 함)
   - Pure Korean → 한국어 섹션만 기록
   - Mixed → 적절한 섹션에 그대로 기록
```

## 🧪 테스트

설치 확인을 위한 테스트 스위트 실행:

```bash
# 에이전트 호출 테스트
claude-code --test todo-logger

# 파일 생성 확인
ls -lh ~/.claude/todo-history/sessions/
ls -lh ~/.claude/todo-history/by-date/
```

## 📚 문서

- [**아키텍처 심층 분석**](docs/ARCHITECTURE.md) - 시스템 설계 및 결정 사항
- [**통합 가이드**](docs/INTEGRATION.md) - 상세한 설정 지침
- [**설계 철학**](docs/DESIGN.md) - 한국어 설계 문서
- [**예제**](examples/) - 실제 세션 및 일일 로그

## 🤝 기여하기

기여를 환영합니다! 개선 영역:

- [ ] 추가 언어 지원 (스페인어, 프랑스어, 일본어)
- [ ] 작업 히스토리 시각화를 위한 웹 대시보드
- [ ] 분석 (작업 완료율, 시간 추정)
- [ ] 내보내기 형식 (JSON, CSV, HTML)
- [ ] 프로젝트 관리 도구 통합 (Jira, Linear, Asana)

### 개발 설정

```bash
git clone https://github.com/yourusername/todo-logger.git
cd todo-logger
# agent/todo-logger.md 수정
# Claude Code로 테스트
# PR 제출
```

## 📜 라이선스

MIT 라이선스 - 자세한 내용은 [LICENSE](LICENSE) 참조

## 🙏 감사의 말

- Anthropic의 [Claude Code](https://github.com/anthropics/claude-code)를 위해 제작
- AI 기반 개발에서 영속적인 작업 추적의 필요성에서 영감을 받음
- 커뮤니티 피드백과 기여

## 📬 지원

- **이슈**: [GitHub Issues](https://github.com/yourusername/todo-logger/issues)
- **토론**: [GitHub Discussions](https://github.com/yourusername/todo-logger/discussions)
- **이메일**: your.email@example.com

---

**AI와 함께 개발하는 개발자를 위해 ❤️로 만들어졌습니다**
