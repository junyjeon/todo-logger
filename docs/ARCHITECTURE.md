# Todo-Logger Architecture

**Version:** 1.0
**Last Updated:** 2025-11-04
**Status:** Production

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Core Components](#core-components)
- [Data Flow](#data-flow)
- [File Formats](#file-formats)
- [Design Decisions](#design-decisions)
- [Performance Considerations](#performance-considerations)
- [Error Handling](#error-handling)
- [Future Enhancements](#future-enhancements)

## Overview

Todo-Logger is a persistence layer for Claude Code's ephemeral task management system. It bridges the gap between in-session TodoWrite operations and permanent, searchable task history.

### Design Philosophy

**Core Principles:**
- **Simplicity** (`간결함`): Minimal complexity, maximum utility
- **Practicality** (`실용성`): Solve real problems without over-engineering
- **Transparency**: Clear, human-readable formats
- **Reliability**: Non-blocking operations, graceful degradation

### Problem Statement

Claude Code uses TodoWrite operations to track tasks during a session. These tasks are:
- Ephemeral (lost when session ends)
- Unsearchable across sessions
- Not referenceable for Git commits
- Invisible to team members

Todo-Logger solves this by automatically persisting every task list update to organized markdown files.

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Claude Code Runtime                          │
│                                                                   │
│  ┌────────────┐    ┌─────────────┐    ┌──────────────────┐     │
│  │ User       │───▶│ TodoWrite   │───▶│ Post-Processing  │     │
│  │ Request    │    │ Operation   │    │ Hook             │     │
│  └────────────┘    └─────────────┘    └────────┬─────────┘     │
│                                                  │               │
│                                    ┌─────────────▼─────────┐    │
│                                    │ Task Tool Invocation  │    │
│                                    │ subagent: todo-logger │    │
│                                    └─────────────┬─────────┘    │
└──────────────────────────────────────────────────┼──────────────┘
                                                    │
                                                    ▼
                            ┌───────────────────────────────────┐
                            │    Todo-Logger Sub-Agent          │
                            │                                   │
                            │  ┌─────────────────────────────┐ │
                            │  │ 1. Language Detection       │ │
                            │  │    - Pure Korean            │ │
                            │  │    - Pure English           │ │
                            │  │    - Mixed (Korean+English) │ │
                            │  └─────────────────────────────┘ │
                            │                                   │
                            │  ┌─────────────────────────────┐ │
                            │  │ 2. Translation Engine       │ │
                            │  │    - EN → KR mapping        │ │
                            │  │    - Technical term handling│ │
                            │  └─────────────────────────────┘ │
                            │                                   │
                            │  ┌─────────────────────────────┐ │
                            │  │ 3. Duplicate Detection      │ │
                            │  │    - Session-scoped check   │ │
                            │  │    - Content comparison     │ │
                            │  └─────────────────────────────┘ │
                            │                                   │
                            │  ┌─────────────────────────────┐ │
                            │  │ 4. File Operations          │ │
                            │  │    - Session append         │ │
                            │  │    - Daily overwrite        │ │
                            │  └─────────────────────────────┘ │
                            │                                   │
                            │  ┌─────────────────────────────┐ │
                            │  │ 5. Status Mapping           │ │
                            │  │    - Emoji conversion       │ │
                            │  │    - State tracking         │ │
                            │  └─────────────────────────────┘ │
                            └───────────────┬───────────────────┘
                                            │
                                            ▼
                    ┌───────────────────────────────────────────┐
                    │       Persistent Storage Layer            │
                    │                                           │
                    │  ┌─────────────────────────────────────┐ │
                    │  │  sessions/                          │ │
                    │  │  - Chronological session logs       │ │
                    │  │  - Append-only operations           │ │
                    │  │  - Full task history with timestamps│ │
                    │  └─────────────────────────────────────┘ │
                    │                                           │
                    │  ┌─────────────────────────────────────┐ │
                    │  │  by-date/                           │ │
                    │  │  - Daily aggregated views           │ │
                    │  │  - Latest state per session         │ │
                    │  │  - Cross-session linking            │ │
                    │  └─────────────────────────────────────┘ │
                    │                                           │
                    │  ┌─────────────────────────────────────┐ │
                    │  │  archive/                           │ │
                    │  │  - Historical backups               │ │
                    │  │  - Legacy format migrations         │ │
                    │  └─────────────────────────────────────┘ │
                    └───────────────────────────────────────────┘
```

### Component Interaction Flow

```
TodoWrite Event
      ↓
[MANDATORY] Task Tool Invocation
      ↓
Todo-Logger Sub-Agent Spawned
      ↓
┌─────────────────────┐
│ Language Detection  │
│ - Analyze task text │
│ - Determine language│
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Translation Logic   │
│ - EN → KR if needed │
│ - Handle mixed text │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Duplicate Check     │
│ - Read session file │
│ - Compare content   │
└──────────┬──────────┘
           ↓
┌─────────────────────┐
│ Format Generation   │
│ - Emoji mapping     │
│ - Markdown structure│
└──────────┬──────────┘
           ↓
     ┌─────────┐
     │ Write   │
     │ Files   │
     └────┬────┘
          ↓
    ┌─────────────┐
    │  sessions/  │ ← Append operation
    └─────────────┘
          ↓
    ┌─────────────┐
    │  by-date/   │ ← Overwrite session section
    └─────────────┘
          ↓
   ✅ Recorded: N tasks
```

## Core Components

### 1. Agent Definition (`agent/todo-logger.md`)

The agent definition is a Claude Code sub-agent specification that defines:

**Metadata:**
- `name`: "todo-logger"
- `description`: Purpose and invocation context
- `model`: "sonnet" (for speed and cost efficiency)
- `color`: "green" (visual identifier in logs)

**Processing Logic:**
1. Session info extraction (timestamp, date, session ID)
2. Language detection with three-way classification
3. File operations for dual storage targets
4. Duplicate detection within session scope
5. Output formatting with emoji status mapping

**Tools Available:**
- `Read`: Check existing history files
- `Write`: Create new history files
- `Edit`: Append to existing history files
- `Bash`: Create directories if needed

**Permissions:**
All file operations in `/home/jun/.claude/todo-history/**` are pre-approved.

### 2. Language Detection Engine

**Classification Logic:**

```python
def detect_language(task_text):
    korean_chars = count_korean_characters(task_text)
    english_chars = count_english_characters(task_text)

    if korean_chars > 0 and english_chars == 0:
        return "PURE_KOREAN"  # Korean section only
    elif english_chars > 0 and korean_chars == 0:
        return "PURE_ENGLISH"  # English + KR translation
    else:
        return "MIXED"  # Korean section as-is
```

**Translation Strategy:**

For PURE_ENGLISH tasks:
1. Analyze task description for technical terms
2. Apply translation mapping (review → 리뷰, test → 테스트)
3. Prefer natural Korean expressions over literal translations
4. Maintain technical accuracy

For MIXED tasks:
- Preserve original text in Korean section
- No translation needed (already comprehensible to Korean speakers)

### 3. Storage Layer

**Dual Storage Architecture:**

**Sessions Directory** (`sessions/{session_id}.md`)
- **Purpose**: Chronological, detailed task history
- **Operation**: Append-only
- **Format**: Session header + timestamped TodoWrite sections
- **Use Case**: Full session replay, debugging, detailed audit trail

**By-Date Directory** (`by-date/{YYYY-MM-DD}.md`)
- **Purpose**: Daily aggregated view of all sessions
- **Operation**: Overwrite current session section on each TodoWrite
- **Format**: Date header + session sections with links
- **Use Case**: Daily standup, commit message reference, quick lookup

**Why Dual Storage?**

1. **Different Access Patterns**
   - Sessions: "What happened in this specific work session?"
   - By-Date: "What did I accomplish today?"

2. **Optimized for Common Queries**
   - Sessions: Complete history, state transitions
   - By-Date: Latest state, cross-session overview

3. **Complementary Strengths**
   - Sessions: Detailed, preserves all state changes
   - By-Date: Concise, easy to scan, git-friendly

### 4. Duplicate Detection

**Scope:** Session-based only (not global)

**Rationale:**
- Same task may appear in different sessions (legitimate)
- Within a session, duplicate entries are noise
- State transitions (pending → in_progress → completed) are NOT duplicates

**Algorithm:**
```python
def is_duplicate(new_task, existing_tasks_in_session):
    for existing_task in existing_tasks_in_session:
        if (new_task.content == existing_task.content and
            new_task.status == existing_task.status):
            return True
    return False
```

**Edge Cases:**
- ✅ "Implement auth" (pending) → "Implement auth" (in_progress): NOT duplicate
- ❌ "Implement auth" (pending) → "Implement auth" (pending): Duplicate, skip
- ✅ "Implement auth" Session A → "Implement auth" Session B: NOT duplicate

### 5. Status Emoji Mapping

**Mapping Table:**

| Internal Status | Emoji | Semantic Meaning |
|----------------|-------|------------------|
| `completed`    | ✅    | Finished successfully |
| `in_progress`  | 🔄    | Currently active |
| `pending`      | 🕐    | Queued, not started |
| `blocked`      | 🚧    | Waiting on dependency |

**Why Emoji?**
- Visual scanning efficiency (spot status at a glance)
- Language-agnostic (works in English and Korean)
- Git-friendly (renders in GitHub, GitLab, Bitbucket)
- Universal recognition across cultures

## Data Flow

### TodoWrite → Persistence Flow

**Step-by-Step Execution:**

1. **User Request** → Claude Code session begins
2. **TodoWrite Operation** → Task list created/updated
3. **Post-Processing Hook** → MANDATORY todo-logger invocation
4. **Sub-Agent Spawn** → New todo-logger instance created
5. **TodoRead** → Current task list state retrieved
6. **Language Detection** → Tasks classified (KR/EN/Mixed)
7. **Translation** → English tasks translated to Korean
8. **Session File Read** → Check for existing session file
9. **Duplicate Check** → Compare against existing tasks in session
10. **Session File Append** → Add new TodoWrite section
11. **Daily File Read** → Load current day's aggregation
12. **Daily File Update** → Overwrite current session section
13. **Confirmation** → `✅ Recorded: N tasks` output

**Timing:**
- Total execution: <2 seconds (target)
- Session append: ~200ms
- Daily overwrite: ~300ms
- Language detection: ~100ms
- Translation: ~500ms

### File Operation Patterns

**Session File (Append-Only):**
```
Read existing file
  ↓
Parse content to find Last Activity line
  ↓
Generate new TodoWrite section
  ↓
Update Last Activity timestamp
  ↓
Append new section
  ↓
Write to disk
```

**Daily File (Selective Overwrite):**
```
Read existing file (if exists)
  ↓
Parse into session sections
  ↓
Find current session section
  ↓
Replace with latest task state
  ↓
Preserve other session sections
  ↓
Write entire file
```

## File Formats

### Session File Format

```markdown
# Session: {session_id}

Started: {YYYY-MM-DD HH:MM:SS}
Last Activity: {YYYY-MM-DD HH:MM:SS}

---

## TodoWrite {HH:MM:SS}

### English
- [emoji] Task description

### Korean (한국어)
- [emoji] 작업 설명

## TodoWrite {HH:MM:SS}

...
```

**Header Section:**
- Session ID in YYYYMMDD-HHMMSS format
- Started timestamp (never changes)
- Last Activity timestamp (updated on each TodoWrite)

**TodoWrite Sections:**
- Chronologically ordered
- Timestamped with HH:MM:SS
- Dual language sections (English + Korean)
- Emoji status indicators

### Daily File Format

```markdown
# {YYYY-MM-DD}

## Session: [{session_id}](../sessions/{session_id}.md) ({HH:MM:SS})

### English
- [emoji] Task description

### Korean (한국어)
- [emoji] 작업 설명

---

## Session: [{another_session_id}](../sessions/{another_session_id}.md) ({HH:MM:SS})

...
```

**Header:** Date in YYYY-MM-DD format

**Session Sections:**
- Separated by `---` dividers
- Linked to detailed session files
- Shows latest task state per session
- Chronologically ordered by session start time

## Design Decisions

### Why Markdown?

**Rationale:**
- ✅ Human-readable without special tools
- ✅ Git-friendly (diffs work well)
- ✅ Searchable with standard tools (grep, ripgrep)
- ✅ Renders nicely on GitHub/GitLab
- ✅ No dependencies (no database, no special parsers)
- ✅ Future-proof format

**Alternatives Considered:**
- JSON: Machine-readable but not human-scannable
- YAML: Too verbose for simple lists
- Database: Adds complexity, reduces portability
- Plain text: Lacks structure and rendering support

### Why Dual Storage (sessions/ and by-date/)?

**Trade-offs:**

| Aspect | Sessions Only | By-Date Only | Dual Storage |
|--------|---------------|--------------|--------------|
| Disk usage | Low | Low | Medium (acceptable) |
| Query speed | Slow (scan all) | Fast (single file) | Fast (both patterns) |
| Complexity | Low | Low | Medium (justified) |
| Flexibility | High | Low | High |
| Git friendliness | Low (many files) | High (few files) | High (by-date for commits) |

**Decision:** Dual storage optimizes for both access patterns with acceptable overhead.

### Why Session-Scoped Duplicate Detection?

**Rationale:**
- Same task in different sessions is legitimate (continued work)
- Global deduplication would require expensive cross-file scans
- Within-session duplicates are user error or system bugs
- Session scope balances accuracy and performance

**Performance Impact:**
- Session-scoped: O(n) where n = tasks in current session (~10-20)
- Global-scoped: O(n*m) where m = total sessions (~100s) - too expensive

### Why Bilingual Support?

**Context:**
- Developer is Korean, works in English codebase
- Team communication in Korean, code in English
- Git commits should be understandable by both audiences

**Implementation:**
- Auto-detect language to minimize manual work
- Translate English → Korean for accessibility
- Preserve mixed text as-is (already comprehensible)

**Future:** Extensible to other language pairs (EN↔ES, EN↔JA, etc.)

### Why Sub-Agent Architecture?

**Advantages:**
- ✅ Isolation: Logging failures don't crash main session
- ✅ Modularity: Easy to update independently
- ✅ Reusability: Can be invoked from multiple contexts
- ✅ Testing: Can test sub-agent in isolation
- ✅ Performance: Can be optimized separately

**Claude Code Integration:**
- Native Task tool support
- Defined agent specification format
- Automatic spawning and lifecycle management
- Built-in error handling and retry logic

## Performance Considerations

### Optimization Strategies

**1. Minimal File I/O**
- Read session file once
- Append in single write operation
- Cache session ID for duration of invocation

**2. Efficient Parsing**
- Use regex for duplicate detection (fast pattern matching)
- Avoid full markdown parsing (treat as text)
- Stream large files if needed

**3. Concurrent Safety**
- Append-only sessions minimize conflicts
- Daily file overwrites are atomic
- Use file locks if available (future enhancement)

**4. Storage Efficiency**
- Markdown is compact (~50-100 bytes per task)
- Session files: ~1-5KB each
- Daily files: ~5-20KB each
- Total: <50MB per year of active use

### Scalability

**Current Limits:**
- Sessions: Unlimited (one file per session)
- Tasks per session: Effectively unlimited (tested up to 100)
- Daily sessions: Effectively unlimited (tested up to 20)

**Future Scaling:**
- Archive old sessions (>30 days) to separate directory
- Compress archived files (gzip)
- Implement monthly rollups for long-term storage

## Error Handling

### Failure Modes

**1. File Creation Failure**
- **Cause:** Permission denied, disk full, path doesn't exist
- **Handling:** Report error, don't block main workflow
- **Recovery:** Create parent directories, retry once

**2. Translation Failure**
- **Cause:** Unknown technical terms, ambiguous text
- **Handling:** Use original English text
- **Recovery:** Add term to translation dictionary

**3. Session ID Unavailable**
- **Cause:** Clock skew, timestamp failure
- **Handling:** Use fallback UUID or hash
- **Recovery:** Continue with alternate ID format

**4. Duplicate Detection False Positive**
- **Cause:** Similar but not identical text
- **Handling:** Log both (prefer false negative over false positive)
- **Recovery:** Manual cleanup if needed

### Graceful Degradation

**Principle:** Never block the main workflow

**Hierarchy:**
1. Full success: Both files updated
2. Partial success: Session file updated, daily file failed
3. Minimal success: Error logged, main session continues
4. Failure: Retry once, then give up gracefully

**User Communication:**
- Success: `✅ Recorded: N tasks`
- Partial: `⚠️ Recorded: N tasks (daily update failed)`
- Failure: `❌ Failed to record tasks (continuing...)`

## Future Enhancements

### Planned Features

**1. Web Dashboard**
- Visualize task completion over time
- Search across all sessions
- Generate reports (velocity, completion rates)
- Export to various formats (JSON, CSV, HTML)

**2. Additional Language Support**
- Spanish (EN ↔ ES)
- Japanese (EN ↔ JA)
- French (EN ↔ FR)
- Portuguese (EN ↔ PT)

**3. Analytics**
- Task completion rate tracking
- Time estimate accuracy
- Common task patterns
- Velocity metrics

**4. Integration Plugins**
- Jira: Sync tasks to issues
- Linear: Create issues from tasks
- Asana: Bidirectional sync
- GitHub Issues: Auto-create from completed tasks

**5. Advanced Search**
- Full-text search across history
- Regex pattern matching
- Date range filtering
- Status filtering

**6. Optimization**
- Background processing for large files
- Incremental updates
- Caching layer for frequently accessed data
- Compression for old archives

### Community Requests

Have a feature request? [Open an issue](https://github.com/yourusername/todo-logger/issues) or [start a discussion](https://github.com/yourusername/todo-logger/discussions).

---

**Document Version:** 1.0
**Author:** Todo-Logger Team
**Last Updated:** 2025-11-04
