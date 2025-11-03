# Todo-Logger Examples

Real-world examples of todo-logger output showing various use cases and scenarios.

## Directory Structure

```
examples/
├── session-logs/        # Individual session examples
│   └── example-session.md
├── daily-logs/          # Daily aggregation examples
│   └── example-daily.md
└── README.md           # This file
```

## Session Logs

Session logs provide chronological, detailed tracking of all TodoWrite operations within a single work session.

**Features:**
- Append-only format (preserves all state changes)
- Timestamps for each TodoWrite operation
- Bilingual support (English + Korean)
- Shows task status progression (pending → in_progress → completed)

**Use Cases:**
- Debugging: "What happened during this specific work session?"
- Audit trail: Complete history of task state changes
- Time tracking: When did work start/end on specific tasks?
- Session replay: Reconstruct exact sequence of work

**Example:** [session-logs/example-session.md](session-logs/example-session.md)

This example shows a typical Claude Code session implementing authentication:
- Initial task list creation
- Status updates as work progresses
- Final completion state
- English → Korean translation

## Daily Logs

Daily logs aggregate all sessions from a single day, showing the latest state of tasks from each session.

**Features:**
- One file per day
- Links to detailed session files
- Latest task state per session
- Cross-session overview

**Use Cases:**
- Daily standup: "What did I accomplish yesterday?"
- Commit messages: Quick reference for today's work
- Team updates: Share daily progress
- Weekly reviews: Scan multiple days quickly

**Example:** [daily-logs/example-daily.md](daily-logs/example-daily.md)

This example shows aggregated view from multiple sessions on 2025-11-04:
- Morning session: Project analysis work
- Afternoon session: Todo-logger extraction project
- Evening session: Additional analysis work

## Common Patterns

### Pattern 1: Feature Implementation

**Session Log shows:**
```markdown
## TodoWrite 01:32:44
- 🕐 Design authentication system
- 🕐 Implement login endpoint
- 🕐 Write unit tests

## TodoWrite 02:15:30
- ✅ Design authentication system
- 🔄 Implement login endpoint
- 🕐 Write unit tests

## TodoWrite 03:45:12
- ✅ Design authentication system
- ✅ Implement login endpoint
- 🔄 Write unit tests
```

**Daily Log shows:**
```markdown
## Session: [20251104-013244](../sessions/20251104-013244.md) (01:32:44)
- ✅ Design authentication system
- ✅ Implement login endpoint
- 🔄 Write unit tests
```

**Key Insight:** Session log preserves progression, daily log shows final state.

### Pattern 2: Bug Investigation

**Session Log shows:**
```markdown
## TodoWrite 10:15:00
- 🔄 Investigate login failure
- 🕐 Identify root cause
- 🕐 Implement fix
- 🕐 Verify fix works

## TodoWrite 11:30:00
- ✅ Investigate login failure
- ✅ Identify root cause
- 🔄 Implement fix
- 🕐 Verify fix works

## TodoWrite 11:45:00
- ✅ Investigate login failure
- ✅ Identify root cause
- ✅ Implement fix
- ✅ Verify fix works
```

**Use for Git Commit:**
```bash
git commit -m "fix: Resolve login failure issue

Investigation and fix completed:
- Investigated login failure (root cause: token expiration)
- Identified missing token refresh logic
- Implemented automatic token refresh
- Verified fix with manual and automated tests

Reference: todo-history/sessions/20251104-101500.md"
```

### Pattern 3: Bilingual Documentation

**English Task:**
```markdown
### English
- 🔄 Write API documentation
- 🕐 Add usage examples
- 🕐 Review for clarity

### Korean (한국어)
- 🔄 API 문서 작성
- 🕐 사용 예제 추가
- 🕐 명확성 검토
```

**Korean Task:**
```markdown
### Korean (한국어)
- 🔄 데이터베이스 스키마 설계
- 🕐 마이그레이션 스크립트 작성
```

**Mixed Task:**
```markdown
### Korean (한국어)
- 🔄 Implement 데이터베이스 연결
- 🕐 Add 에러 핸들링
```

**Key Insight:** System automatically handles language detection and translation.

### Pattern 4: Long-Running Project

**Multiple Sessions Across Days:**

**Day 1 - Planning:**
```markdown
# 2025-11-01
## Session: [20251101-090000](../sessions/20251101-090000.md) (09:00:00)
- ✅ Review project requirements
- ✅ Create architecture design
- 🔄 Plan implementation phases
```

**Day 2 - Implementation:**
```markdown
# 2025-11-02
## Session: [20251102-100000](../sessions/20251102-100000.md) (10:00:00)
- ✅ Implement phase 1 (authentication)
- 🔄 Implement phase 2 (data layer)
- 🕐 Implement phase 3 (UI)
```

**Day 3 - Testing:**
```markdown
# 2025-11-03
## Session: [20251103-110000](../sessions/20251103-110000.md) (11:00:00)
- ✅ Write unit tests
- ✅ Write integration tests
- ✅ Perform manual testing
```

**Weekly Review:**
```bash
cat ~/.claude/todo-history/by-date/2025-11-0{1,2,3}.md | grep "✅" | wc -l
# Output: 8 completed tasks this week
```

## Using Examples

### For Learning

Study the examples to understand:
- File format and structure
- Language detection and translation behavior
- Status emoji usage
- Session vs. daily organization
- Linking between files

### For Testing

Copy examples to test your setup:

```bash
# Copy example session to your history
cp examples/session-logs/example-session.md \
   ~/.claude/todo-history/sessions/test-session.md

# Copy example daily to your history
TODAY=$(date +%Y-%m-%d)
cp examples/daily-logs/example-daily.md \
   ~/.claude/todo-history/by-date/$TODAY.md
```

### For Customization

Use examples as templates:

```bash
# Create custom template based on example
cp examples/session-logs/example-session.md \
   templates/my-custom-session.md

# Edit to match your workflow
vim templates/my-custom-session.md
```

## Contributing Examples

Have an interesting use case? Contribute your examples:

1. Anonymize sensitive information
2. Add descriptive comments explaining the scenario
3. Show unique patterns or workflows
4. Submit PR with example file

**Example contribution areas:**
- Multi-language support (beyond English/Korean)
- Complex project workflows
- Team collaboration patterns
- Integration with specific tools (Jira, Linear, etc.)
- Custom automation scripts

---

**More Examples:** See [GitHub Discussions](https://github.com/yourusername/todo-logger/discussions) for community-contributed examples.
