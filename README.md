# Todo-Logger

> **Persistent Task History for AI-Driven Development**
> Bridge the gap between ephemeral AI conversations and persistent project memory.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Compatible-green.svg)](https://github.com/anthropics/claude-code)
[![Status: Production](https://img.shields.io/badge/Status-Production-success.svg)]()

**English** | **[한국어](README.ko.md)**

## 🎯 Problem

When working with AI assistants like Claude Code, task lists exist only within the current session. Once the conversation ends:

- ✗ Task history is lost
- ✗ You can't reference what was accomplished yesterday
- ✗ Git commit messages require manual reconstruction
- ✗ No searchable task archive across sessions
- ✗ Team members can't see AI-driven work progress

## 💡 Solution

**Todo-Logger** automatically captures every task list update during AI sessions and persists them to organized markdown files. This creates a permanent, searchable record of all work tracked by your AI assistant.

### Key Features

🔄 **Automatic Persistence** - Zero-effort logging of all TodoWrite operations
🌐 **Bilingual Support** - Automatic English ↔ Korean translation
📝 **Git-Friendly Format** - Markdown files perfect for commit message reference
📊 **Dual Organization** - Both chronological (sessions) and date-based views
🤖 **Native Integration** - Seamless Claude Code sub-agent architecture
⚡ **Real-Time Logging** - Sub-2-second execution with minimal overhead
🔍 **Searchable History** - grep-friendly format for quick lookup
🎯 **Smart Deduplication** - Avoids redundant entries within sessions

## 🏗️ Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Claude Code Session                      │
│                                                               │
│  ┌──────────────┐         ┌─────────────────┐              │
│  │  TodoWrite   │────────▶│  Todo-Logger    │              │
│  │  Operation   │         │   Sub-Agent     │              │
│  └──────────────┘         └────────┬────────┘              │
│                                     │                        │
└─────────────────────────────────────┼────────────────────────┘
                                      ▼
                    ┌─────────────────────────────────┐
                    │    Persistent Storage Layer     │
                    │                                 │
                    │  ┌──────────────────────────┐  │
                    │  │  sessions/               │  │
                    │  │  - 20251104-013244.md    │  │
                    │  │  - 20251104-020156.md    │  │
                    │  │  (chronological detail)  │  │
                    │  └──────────────────────────┘  │
                    │                                 │
                    │  ┌──────────────────────────┐  │
                    │  │  by-date/                │  │
                    │  │  - 2025-11-04.md         │  │
                    │  │  - 2025-11-03.md         │  │
                    │  │  (daily aggregation)     │  │
                    │  └──────────────────────────┘  │
                    └─────────────────────────────────┘
```

### Core Components

**1. Agent Definition** ([`agent/todo-logger.md`](agent/todo-logger.md))
- Language detection and translation logic
- Dual-format file operations
- Duplicate detection
- Error handling and recovery

**2. Storage Structure**
```
todo-history/
├── sessions/           # Chronological session logs
│   ├── 20251104-013244.md
│   └── 20251104-020156.md
├── by-date/           # Daily aggregated views
│   ├── 2025-11-04.md
│   └── 2025-11-03.md
└── archive/           # Historical backups
```

**3. Integration Protocol**
- Mandatory invocation after every TodoWrite
- Task tool with `todo-logger` sub-agent type
- Automatic retry on failure (1 attempt)
- Non-blocking error handling

## 🚀 Quick Start

### Installation

1. **Copy Agent Definition**
   ```bash
   cp agent/todo-logger.md ~/.claude/agents/
   ```

2. **Create Storage Directory**
   ```bash
   mkdir -p ~/.claude/todo-history/{sessions,by-date,archive}
   ```

3. **Configure Claude Code**

   Add to your `~/.claude/MODES.md`:
   ```markdown
   ### Mandatory todo-logger Integration

   **CRITICAL**: Every TodoWrite operation MUST be followed by todo-logger agent invocation.

   **Invocation Pattern**:
   ```
   <TodoWrite operation completes>
   → Immediately use Task tool to call todo-logger agent
   → Pass current TodoList state to agent
   → Confirm logging success before proceeding
   ```
   ```

### Verification

Run a test TodoWrite operation in Claude Code and verify files are created:

```bash
ls -lh ~/.claude/todo-history/sessions/
ls -lh ~/.claude/todo-history/by-date/
```

## 📖 Usage

### Automatic Invocation

Todo-Logger runs automatically after every TodoWrite operation. No manual intervention required.

**Example Flow:**
```
User: "Help me implement authentication"

Claude: <Creates TodoList with TodoWrite>
        <Automatically invokes todo-logger sub-agent>
        "✅ Recorded: 3 tasks"
```

### File Formats

**Session Log** (`sessions/1104_인증 시스템 구현.md`):
```markdown
20251104-013244

Start: 25-11-04 01:32:44
Last: 25-11-04 01:35:12
Session: 인증 시스템 구현

---

## 01:32:44
- 🔄 인증 시스템 구현
- 🕐 단위 테스트 작성
- 🕐 문서 업데이트

## 01:35:12
- ✅ 인증 시스템 구현
- 🔄 단위 테스트 작성
- 🕐 문서 업데이트
```

**Daily Aggregation** (`by-date/2025-11-04.md`):
```markdown
# 2025-11-04

## Session: [20251104-013244](../sessions/1104_인증 시스템 구현.md) (01:32:44)
- ✅ 인증 시스템 구현
- 🔄 단위 테스트 작성
- 🕐 문서 업데이트

---

## Session: [20251104-020156](../sessions/1104_단위 테스트 작성.md) (02:01:56)
- ✅ 단위 테스트 작성
- 🔄 문서 업데이트
```

### Status Emoji Mapping

- ✅ `completed` - Task finished successfully
- 🔄 `in_progress` - Currently being worked on
- 🕐 `pending` - Queued for future work
- 🚧 `blocked` - Waiting on dependency or external factor

## 🌐 Korean-Only Recording

### Language Processing

**All tasks are recorded in Korean only** for improved readability and token efficiency.

**1. Pure Korean** → Record as-is
```
Input: "데이터베이스 설계"
Output: "데이터베이스 설계"
```

**2. Pure English** → Auto-translate to Korean
```
Input: "Implement database schema"
Output: "데이터베이스 스키마 구현"
```

**3. Mixed (Korean + English)** → Record as-is
```
Input: "Implement 데이터베이스 설계"
Output: "Implement 데이터베이스 설계"
```

### Translation Guidelines

Common technical terms:
- `review` → `리뷰` (not 검토)
- `test` → `테스트`
- `integration` → `통합`
- `implementation` → `구현`
- `refactoring` → `리팩토링`

## 🔧 Integration

### Claude Code Integration

See [`docs/INTEGRATION.md`](docs/INTEGRATION.md) for detailed integration guide.

**Minimal Integration:**

Add to your Claude Code system prompt or MODES.md:

```markdown
After every TodoWrite operation, immediately invoke:
Task tool → subagent_type: "todo-logger" → pass current TodoList state
```

### Manual Invocation (for testing)

While automatic invocation is recommended, you can manually trigger:

```javascript
// In Claude Code session
{
  "tool": "Task",
  "subagent_type": "todo-logger",
  "description": "Log current tasks",
  "prompt": "Record the current TodoList state..."
}
```

## 📊 Use Cases

### 1. Git Commit Messages

```bash
# Open today's log before committing
cat ~/.claude/todo-history/by-date/$(date +%Y-%m-%d).md

# Use task descriptions for commit message
git commit -m "feat: Implement authentication system

- Completed user registration endpoint
- Added JWT token generation
- Implemented password hashing with bcrypt

Tracked in: todo-history/sessions/20251104-013244.md"
```

### 2. Daily Standup Reports

```bash
# Yesterday's accomplishments
cat ~/.claude/todo-history/by-date/2025-11-03.md | grep "✅"

# Today's plan
cat ~/.claude/todo-history/by-date/2025-11-04.md | grep "🔄\|🕐"
```

### 3. Project Retrospectives

```bash
# Search for specific feature work
grep -r "authentication" ~/.claude/todo-history/sessions/

# Count completed tasks this week
grep -r "✅" ~/.claude/todo-history/by-date/ | wc -l
```

### 4. Team Transparency

```bash
# Share AI session accomplishments
git add .claude/todo-history/
git commit -m "docs: Update todo-history with authentication work"
git push

# Team members can review AI-driven development progress
```

## 🎨 Configuration

### Custom Storage Location

Edit `agent/todo-logger.md` and update paths:

```markdown
Primary target: `/custom/path/todo-history/sessions/{session_id}.md`
Secondary target: `/custom/path/todo-history/by-date/{YYYY-MM-DD}.md`
```

### Custom Session ID Format

Default: `YYYYMMDD-HHMMSS`

To use UUIDs or custom format, modify session ID generation logic in agent definition.

### Language Preferences

To disable automatic translation:

```markdown
Language Detection:
- Pure Korean → Record Korean only
- Pure English → Record English only (no translation)
- Mixed → Record as-is
```

## 🧪 Testing

Run the test suite to verify installation:

```bash
# Test agent invocation
claude-code --test todo-logger

# Verify file creation
ls -lh ~/.claude/todo-history/sessions/
ls -lh ~/.claude/todo-history/by-date/
```

## 📚 Documentation

- [**Architecture Deep Dive**](docs/ARCHITECTURE.md) - System design and decisions
- [**Integration Guide**](docs/INTEGRATION.md) - Detailed setup instructions
- [**Design Philosophy**](docs/DESIGN.md) - Korean design documentation
- [**Examples**](examples/) - Real-world session and daily logs

## 🤝 Contributing

Contributions welcome! Areas for improvement:

- [ ] Additional language support (Spanish, French, Japanese)
- [ ] Web dashboard for visualizing task history
- [ ] Analytics (task completion rates, time estimates)
- [ ] Export formats (JSON, CSV, HTML)
- [ ] Integration with project management tools (Jira, Linear, Asana)

### Development Setup

```bash
git clone https://github.com/junyjeon/todo-logger.git
cd todo-logger
# Make changes to agent/todo-logger.md
# Test with Claude Code
# Submit PR
```

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- Built for [Claude Code](https://github.com/anthropics/claude-code) by Anthropic
- Inspired by the need for persistent task tracking in AI-driven development
- Community feedback and contributions

## 📬 Support

- **Issues**: [GitHub Issues](https://github.com/junyjeon/todo-logger/issues)
- **Discussions**: [GitHub Discussions](https://github.com/junyjeon/todo-logger/discussions)
- **Email**: junyjeon@gmail.com

---

**Made with ❤️ for developers who build with AI**
