# Todo-Logger Integration Guide

Complete guide for integrating Todo-Logger into Claude Code and other AI assistant workflows.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Claude Code Integration](#claude-code-integration)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Prerequisites

### System Requirements

- **Claude Code**: v0.1.0 or higher
- **Operating System**: Linux, macOS, or Windows (WSL2)
- **Disk Space**: ~50MB for typical yearly usage
- **Permissions**: Write access to `~/.claude/` directory

### Knowledge Requirements

- Basic understanding of Claude Code's TodoWrite system
- Familiarity with markdown format
- Basic bash/shell commands
- (Optional) Understanding of sub-agent architecture

## Installation

### Step 1: Clone or Download Todo-Logger

**Option A: Git Clone**
```bash
git clone https://github.com/yourusername/todo-logger.git
cd todo-logger
```

**Option B: Download ZIP**
```bash
wget https://github.com/yourusername/todo-logger/archive/main.zip
unzip main.zip
cd todo-logger-main
```

### Step 2: Install Agent Definition

Copy the agent definition to Claude Code's agents directory:

```bash
# Create agents directory if it doesn't exist
mkdir -p ~/.claude/agents

# Copy agent definition
cp agent/todo-logger.md ~/.claude/agents/

# Verify installation
ls -lh ~/.claude/agents/todo-logger.md
```

**Expected output:**
```
-rw-r--r-- 1 user user 4.6K Nov 04 01:32 /home/user/.claude/agents/todo-logger.md
```

### Step 2.5: Configure File Permissions

Grant Claude Code permission to access the todo-history directory.

**Option A: Using Claude Code Settings UI**

1. Open Claude Code Settings (Ctrl/Cmd + ,)
2. Search for "auto approved tools"
3. Add the following entries:
   - `Read(/home/user/.claude/todo-history/**)`
   - `Write(/home/user/.claude/todo-history/**)`
   - `Edit(/home/user/.claude/todo-history/**)`

**Option B: Manual Configuration**

Edit `~/.claude/settings.json` and add to `autoApprovedTools`:

```json
{
  "autoApprovedTools": [
    "Read(/home/user/.claude/todo-history/**)",
    "Write(/home/user/.claude/todo-history/**)",
    "Edit(/home/user/.claude/todo-history/**)",
    "Bash(mkdir:-p:/home/user/.claude/todo-history/*)"
  ]
}
```

**For macOS/Linux users:**
Replace `/home/user` with your actual home directory path (use `echo $HOME` to find it).

**For Windows (WSL2) users:**
Use the WSL path format: `/home/username/.claude/todo-history/**`

**Verify permissions:**
```bash
# Check if settings file is valid JSON
python3 -m json.tool ~/.claude/settings.json

# Or use jq if installed
jq . ~/.claude/settings.json
```

### Step 3: Create Storage Directories

Set up the directory structure for persistent storage:

```bash
# Create main storage directory
mkdir -p ~/.claude/todo-history

# Create subdirectories
mkdir -p ~/.claude/todo-history/sessions
mkdir -p ~/.claude/todo-history/by-date
mkdir -p ~/.claude/todo-history/archive

# Set permissions
chmod 755 ~/.claude/todo-history
chmod 755 ~/.claude/todo-history/sessions
chmod 755 ~/.claude/todo-history/by-date

# Verify structure
tree ~/.claude/todo-history
```

**Expected output:**
```
/home/user/.claude/todo-history
├── archive
├── by-date
└── sessions

3 directories, 0 files
```

### Step 4: Configure Claude Code

Add the mandatory todo-logger protocol to your Claude Code configuration.

**Option A: Update MODES.md (Recommended)**

Add to `~/.claude/MODES.md`:

```markdown
## TodoWrite Protocol & Persistence

### Mandatory todo-logger Integration

**CRITICAL**: Every TodoWrite operation MUST be followed by todo-logger agent invocation for persistent task history.

**Automatic Logging Protocol**:
1. **After TodoWrite**: Immediately invoke Task tool with `todo-logger` agent
2. **Purpose**: Maintain persistent log for commit messages and task history
3. **Log Location**: `/home/user/.claude/todo-history/`
   - `sessions/[YYYYMMDD-HHMMSS].md` - Individual session logs
   - `by-date/[YYYY-MM-DD].md` - Daily aggregated logs

**Invocation Pattern**:
```
<TodoWrite operation completes>
→ Immediately use Task tool to call todo-logger agent
→ Pass current TodoList state to agent
→ Agent creates/updates session and daily files
→ Confirm logging success before proceeding
```

**Error Handling**:
- If todo-logger fails, retry once
- If retry fails, log error but continue main operation
- Never block main workflow due to logging failures
```

**Option B: Create Custom Slash Command**

Create `~/.claude/commands/log-todos.md`:

```markdown
---
name: log-todos
description: Manually invoke todo-logger for current tasks
---

Invoke the todo-logger sub-agent to record the current TodoList state.

Steps:
1. Use TodoRead to get current task list
2. Invoke Task tool with subagent_type: "todo-logger"
3. Pass TodoList state to agent
4. Confirm recording with "✅ Recorded: N tasks"
```

## Claude Code Integration

### Automatic Invocation (Recommended)

Configure Claude Code to automatically invoke todo-logger after every TodoWrite operation.

**Add to System Prompt or RULES.md:**

```markdown
## TodoWrite Operations

MANDATORY: After every TodoWrite operation, immediately:

1. Invoke Task tool
2. Set subagent_type: "todo-logger"
3. Pass current TodoList state from TodoRead
4. Wait for confirmation: "✅ Recorded: N tasks"
5. Continue with main workflow

Example:
```json
{
  "tool": "Task",
  "subagent_type": "todo-logger",
  "description": "Log current tasks",
  "prompt": "Record the current TodoList state: [tasks here]"
}
```

**Error Handling:**
- Retry once on failure
- Log error but don't block on second failure
- Report logging issues to user
```

### Manual Invocation

For testing or manual logging, you can invoke directly:

**In Claude Code Chat:**
```
User: "Log my current tasks to history"

Claude: <Invokes TodoRead to get current state>
        <Invokes Task tool with todo-logger>
        "✅ Recorded: 3 tasks"
```

**Via Custom Slash Command:**
```
/log-todos
```

### Integration with Git Workflow

Add a git hook to remind you to check todo-history before commits:

**Create `.git/hooks/pre-commit`:**

```bash
#!/bin/bash

# Check if todo-history exists for today
TODAY=$(date +%Y-%m-%d)
TODO_FILE="$HOME/.claude/todo-history/by-date/$TODAY.md"

if [ -f "$TODO_FILE" ]; then
  echo "📋 Today's todo-history:"
  echo "────────────────────────────────────"
  cat "$TODO_FILE"
  echo "────────────────────────────────────"
  echo ""
  echo "💡 Use todo-history for commit message reference"
  echo ""
fi

# Always allow commit (informational only)
exit 0
```

**Make executable:**
```bash
chmod +x .git/hooks/pre-commit
```

## Configuration

### Customizing Storage Location

**Edit** `~/.claude/agents/todo-logger.md`:

```markdown
3. File Operations - sessions/
   - Primary target: `/custom/path/todo-history/sessions/{session_id}.md`

4. File Operations - by-date/
   - Secondary target: `/custom/path/todo-history/by-date/{YYYY-MM-DD}.md`
```

**Create storage directories:**
```bash
mkdir -p /custom/path/todo-history/{sessions,by-date,archive}
```

### Customizing Session ID Format

**Default:** `YYYYMMDD-HHMMSS` (e.g., `20251104-013244`)

**To use UUID format**, edit session ID generation logic:

```markdown
1. Extract Session Info
   - Generate session ID: Use UUID instead of timestamp
   - Example: `uuid.uuid4()` → `a1b2c3d4-e5f6-...`
```

**To use custom format**, define your pattern:

```markdown
1. Extract Session Info
   - Generate session ID: `{project}-{YYYYMMDD}-{HHMMSS}`
   - Example: `myapp-20251104-013244`
```

### Language Preferences

**Default:** English → Korean translation enabled

**To disable translation** (English-only mode):

```markdown
2. Language Detection
   - Pure English → Record English section only (NO translation)
   - Pure Korean → Record Korean section only
   - Mixed → Record as-is in appropriate section
```

**To add another language** (e.g., Spanish):

```markdown
2. Language Detection
   - Pure English → Record English + Spanish translation
   - Pure Spanish → Record Spanish + English translation
   - Pure Korean → Record Korean only
   - Mixed → Record in dominant language

Translation Guidelines:
   - "review" → "revisar" (Spanish), "리뷰" (Korean)
   - "test" → "prueba" (Spanish), "테스트" (Korean)
```

### Status Emoji Customization

**Default mapping:**

```markdown
- ✅ completed
- 🔄 in_progress
- 🕐 pending
- 🚧 blocked
```

**To customize**, edit status mapping section:

```markdown
- ✔️  completed (simple checkmark)
- ▶️  in_progress (play icon)
- ⏸️  pending (pause icon)
- 🛑 blocked (stop sign)
```

## Verification

### Test Installation

**1. Verify agent is installed:**

```bash
cat ~/.claude/agents/todo-logger.md | head -20
```

Expected: See agent metadata and description

**2. Verify storage directories exist:**

```bash
ls -la ~/.claude/todo-history/
```

Expected: See `sessions/`, `by-date/`, `archive/` directories

**3. Test manual invocation in Claude Code:**

```
User: "Create a test task list and log it"

Claude: <Creates TodoWrite with test tasks>
        <Invokes todo-logger>
        "✅ Recorded: 2 tasks"
```

**4. Verify files were created:**

```bash
# Check for today's session
ls -lh ~/.claude/todo-history/sessions/ | tail -1

# Check for today's daily log
cat ~/.claude/todo-history/by-date/$(date +%Y-%m-%d).md
```

Expected: See markdown files with task content

### Validation Checklist

- [ ] Agent definition exists at `~/.claude/agents/todo-logger.md`
- [ ] Storage directories created and writable
- [ ] MODES.md or system prompt includes mandatory protocol
- [ ] Test invocation creates session file
- [ ] Test invocation creates/updates daily file
- [ ] Files contain expected markdown format
- [ ] Bilingual support works (English + Korean)
- [ ] Emoji status mapping is correct
- [ ] Timestamps are in correct timezone (KST or local)

## Troubleshooting

### Common Issues

#### Issue: "Agent not found: todo-logger"

**Cause:** Agent definition not in correct location

**Solution:**
```bash
# Check agent exists
ls -lh ~/.claude/agents/todo-logger.md

# If not, copy from installation directory
cp agent/todo-logger.md ~/.claude/agents/

# Restart Claude Code to reload agents
```

#### Issue: "Permission denied" when writing files

**Cause:** Storage directory not writable

**Solution:**
```bash
# Fix permissions
chmod 755 ~/.claude/todo-history
chmod 755 ~/.claude/todo-history/sessions
chmod 755 ~/.claude/todo-history/by-date

# Verify ownership
ls -la ~/.claude/todo-history
```

#### Issue: Files not being created

**Cause:** todo-logger not being invoked after TodoWrite

**Solution:**
1. Check MODES.md includes mandatory protocol
2. Verify Task tool is available
3. Check Claude Code logs for errors
4. Test manual invocation

```bash
# Check logs
tail -f ~/.claude/logs/agent-invocations.log
```

#### Issue: Translation not working

**Cause:** Language detection failing

**Solution:**
1. Check task text encoding (UTF-8 required)
2. Verify translation guidelines in agent definition
3. Test with pure English and pure Korean tasks separately

**Debug:**
```bash
# Check Korean character encoding
file ~/.claude/todo-history/by-date/$(date +%Y-%m-%d).md
# Expected: UTF-8 Unicode text
```

#### Issue: Duplicate entries in session file

**Cause:** Duplicate detection not working correctly

**Solution:**
1. Verify duplicate detection logic in agent definition
2. Check if same task appears with same status twice
3. Clear session file and restart session if needed

```bash
# Backup and clear problematic session
cp ~/.claude/todo-history/sessions/20251104-013244.md{,.backup}
> ~/.claude/todo-history/sessions/20251104-013244.md
```

#### Issue: Daily file not aggregating correctly

**Cause:** Session section overwrite logic failing

**Solution:**
1. Check for malformed markdown in daily file
2. Verify session ID format matches agent expectation
3. Manually fix daily file structure if needed

**Template:**
```markdown
# 2025-11-04

## [251104-013244](../sessions/20251104-013244.md)  (01:32:44)

### English
- ✅ Task description

### Korean (한국어)
- ✅ 작업 설명

---
```

### Debug Mode

Enable detailed logging for troubleshooting:

**Edit** `~/.claude/agents/todo-logger.md`:

```markdown
### Output

Show: `✅ Recorded: N tasks`

DEBUG MODE (temporary):
Show detailed logging:
- Language detected: [language]
- Translation: [original] → [translated]
- Files written: [paths]
- Execution time: [milliseconds]
```

**Re-invoke and check output.**

### Getting Help

If issues persist:

1. **Check GitHub Issues**: [github.com/yourusername/todo-logger/issues](https://github.com/yourusername/todo-logger/issues)
2. **Join Discussions**: [github.com/yourusername/todo-logger/discussions](https://github.com/yourusername/todo-logger/discussions)
3. **Contact Support**: your.email@example.com

**When reporting issues, include:**
- Claude Code version
- Operating system
- Error messages or logs
- Steps to reproduce
- Example of expected vs. actual behavior

## Advanced Usage

### Custom Workflows

#### Workflow 1: Weekly Review

Create a script to generate weekly task summary:

```bash
#!/bin/bash
# weekly-review.sh

WEEK_START=$(date -d "last monday" +%Y-%m-%d)
WEEK_END=$(date +%Y-%m-%d)

echo "# Weekly Task Summary: $WEEK_START to $WEEK_END"
echo ""

for file in ~/.claude/todo-history/by-date/*.md; do
  DATE=$(basename "$file" .md)
  if [[ "$DATE" > "$WEEK_START" && "$DATE" < "$WEEK_END" ]]; then
    echo "## $DATE"
    grep "✅" "$file" || echo "No completed tasks"
    echo ""
  fi
done
```

**Usage:**
```bash
chmod +x weekly-review.sh
./weekly-review.sh > weekly-review.md
```

#### Workflow 2: Commit Message Generator

Create a script to generate commit messages from today's tasks:

```bash
#!/bin/bash
# generate-commit-message.sh

TODAY=$(date +%Y-%m-%d)
TODO_FILE="$HOME/.claude/todo-history/by-date/$TODAY.md"

if [ ! -f "$TODO_FILE" ]; then
  echo "No todo-history for today"
  exit 1
fi

echo "Suggested commit message based on completed tasks:"
echo ""
echo "feat: Implement today's features"
echo ""
grep "✅" "$TODO_FILE" | sed 's/- ✅/- /'
echo ""
echo "Reference: todo-history/by-date/$TODAY.md"
```

**Usage:**
```bash
./generate-commit-message.sh > commit-msg.txt
git commit -F commit-msg.txt
```

#### Workflow 3: Task Analytics

Create a script to analyze task completion patterns:

```bash
#!/bin/bash
# task-analytics.sh

echo "Task Analytics"
echo "=============="
echo ""

TOTAL_SESSIONS=$(ls ~/.claude/todo-history/sessions/*.md | wc -l)
echo "Total Sessions: $TOTAL_SESSIONS"

TOTAL_COMPLETED=$(grep -r "✅" ~/.claude/todo-history/by-date/ | wc -l)
echo "Total Completed Tasks: $TOTAL_COMPLETED"

TOTAL_PENDING=$(grep -r "🕐" ~/.claude/todo-history/by-date/ | wc -l)
echo "Total Pending Tasks: $TOTAL_PENDING"

COMPLETION_RATE=$(echo "scale=2; $TOTAL_COMPLETED * 100 / ($TOTAL_COMPLETED + $TOTAL_PENDING)" | bc)
echo "Completion Rate: $COMPLETION_RATE%"
```

### Integration with Other Tools

#### VS Code Extension

Create a VS Code task to view today's todos:

**`.vscode/tasks.json`:**

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "View Today's Todos",
      "type": "shell",
      "command": "cat ~/.claude/todo-history/by-date/$(date +%Y-%m-%d).md",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "panel": "new"
      }
    }
  ]
}
```

#### Alfred Workflow (macOS)

Create an Alfred workflow to quickly search todo-history:

1. Create new workflow in Alfred
2. Add "Keyword" input: `todos`
3. Add "Run Script" action:

```bash
query="{query}"
grep -r "$query" ~/.claude/todo-history/by-date/ | cat
```

#### Raycast Extension

Create a Raycast script command:

**`view-todays-todos.sh`:**

```bash
#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title View Today's Todos
# @raycast.mode fullOutput

cat ~/.claude/todo-history/by-date/$(date +%Y-%m-%d).md
```

### API Integration

For programmatic access, create a simple wrapper:

**`todo-logger-api.py`:**

```python
#!/usr/bin/env python3
import os
from datetime import date
from pathlib import Path

TODO_HISTORY_PATH = Path.home() / ".claude" / "todo-history"

def get_today_todos():
    """Get today's todo list"""
    today = date.today().strftime("%Y-%m-%d")
    daily_file = TODO_HISTORY_PATH / "by-date" / f"{today}.md"

    if daily_file.exists():
        return daily_file.read_text()
    return None

def search_todos(query):
    """Search all todos for a query"""
    results = []
    for file in (TODO_HISTORY_PATH / "by-date").glob("*.md"):
        content = file.read_text()
        if query.lower() in content.lower():
            results.append({
                "date": file.stem,
                "matches": [line for line in content.split("\n")
                           if query.lower() in line.lower()]
            })
    return results

if __name__ == "__main__":
    print(get_today_todos())
```

**Usage:**
```python
from todo_logger_api import get_today_todos, search_todos

# Get today's tasks
todos = get_today_todos()
print(todos)

# Search for "authentication" tasks
results = search_todos("authentication")
for result in results:
    print(f"{result['date']}: {result['matches']}")
```

---

**Integration Support:** For additional integration help, see [GitHub Discussions](https://github.com/yourusername/todo-logger/discussions)
