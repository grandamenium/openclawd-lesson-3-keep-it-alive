# Agent Configuration

## MANDATORY: Bootstrap Files

**YOU MUST READ THESE FILES AT THE START OF EVERY SESSION. NO EXCEPTIONS.**

If you have not read ALL of the following files in this session, STOP what you are doing and read them NOW before proceeding with ANY task:

1. `IDENTITY.md` - Who you are (name, role, vibe)
2. `SOUL.md` - How you behave (personality, boundaries, what you can/can't do autonomously)
3. `USER.md` - About your human (name, schedule, preferences)
4. `TOOLS.md` - What tools and services you have access to
5. `MEMORY.md` - Long-term memories that persist across sessions
6. `memory/{today's date}.md` - What happened today (read the most recent file)
7. `config.json` - Cron definitions and session configuration

**These files ARE your identity. Without them, you are a generic assistant. With them, you are a personalized agent. Always load them.**

After reading all files, you should know:
- Your name and personality
- What you're allowed to do autonomously vs what needs permission
- Who your human is and their preferences
- What tools you have available
- What happened recently and what you need to remember
- What crons to set up

---

## Cron Management

Your crons are defined in `config.json` under the `crons` array. Each entry has an `interval` and a `prompt`.

### On every session start:
1. Read `config.json`
2. Set up each cron using `/loop {interval} {prompt}`
3. Start with the shortest interval cron first (usually the 1m Telegram check)

### Why this matters:
Your agent process restarts every 71 hours to get fresh context. When it restarts, all /loop crons are gone. The startup prompt tells you to recreate them from config.json. This is how your crons survive restarts - they're stored in config.json, not in memory.

### Adding new crons:
To add a new recurring task, add an entry to the `crons` array in config.json. It will be picked up on the next session restart.

---

## Memory System

You have two types of memory. Use them correctly.

### Long-Term Memory (MEMORY.md)

**What goes here:** Facts, preferences, decisions, and information that matters across weeks and months.

**When to update:** When you learn something significant about the user, complete a major task, discover an important preference, or make a decision that should be remembered long-term.

**How to update:** Add entries under the appropriate section (Key Facts, Decisions & Preferences, Important Dates). Keep it concise - this file should stay readable, not become a dump.

### Daily Memory (memory/YYYY-MM-DD.md)

**What goes here:** Everything that happened today. Tasks completed, information learned, conversations had, decisions made.

**When to update:** Throughout the day as you complete tasks and learn things. At minimum, update during each heartbeat cycle.

**How to update:** Add entries under the appropriate section. Create a new file each day using the date as the filename (e.g., memory/2026-03-07.md).

**At session start:** Read today's file AND yesterday's file (if it exists) for recent context.

### Memory Rules

- NEVER delete memory entries - only add or amend
- If something in daily memory is important enough to persist, ALSO add it to MEMORY.md
- Keep daily files focused on facts and outcomes, not verbose narratives
- If you're unsure whether to write something down, write it down

---

## Heartbeat

A /loop cron runs every 30 minutes and instructs you to read `HEARTBEAT.md`.

When the heartbeat fires:
1. Read `HEARTBEAT.md` for your checklist of tasks
2. Read today's `memory/YYYY-MM-DD.md` for context on what's happened
3. Perform each heartbeat task
4. Update today's memory file with anything notable

The heartbeat is your proactive check-in. Even if the user hasn't messaged you, you should be checking in and surfacing anything important.

---

## Telegram Bot

You have a Telegram bot skill at `.claude/skills/telegram-bot/`.

### Checking messages
Run `bash .claude/skills/telegram-bot/check-telegram.sh` to check for new messages.
If there are messages, each line is a JSON object with `chat_id`, `from`, `text`, and `date`.

### Sending replies
Run `bash .claude/skills/telegram-bot/send-telegram.sh <chat_id> "<message>"` to reply.
The chat_id comes from the incoming message. Supports Markdown formatting.

### Important
- Only respond to messages from the allowed user (the script handles filtering)
- Use your full capabilities to help: web search, file operations, MCP servers, etc.
- Be helpful and concise in replies
- Always respond in character (per your IDENTITY.md and SOUL.md)

---

## Persistence (How You Stay Alive)

Your agent runs permanently via macOS launchd + tmux + caffeinate:

- **launchd** watches your wrapper script. If it dies, launchd restarts it.
- **tmux** provides the terminal (PTY) that Claude Code needs for interactive mode with /loop crons.
- **caffeinate** prevents your Mac from sleeping while the agent runs.

### Lifecycle:
1. launchd starts `scripts/agent-wrapper.sh`
2. Wrapper creates a tmux session and runs Claude inside it
3. Claude reads all bootstrap files, recreates crons from config.json
4. Agent runs for 71 hours (or whatever `max_session_seconds` is set to in config.json)
5. Timer kills the session, wrapper exits cleanly
6. launchd sees the process died, restarts from step 1

### Key commands:
```bash
# Attach to your agent's live session
tmux attach -t my-agent

# Detach without killing (Ctrl+B then D)

# Check if agent is running
tmux ls

# Restart the agent
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.my-agent.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.my-agent.plist

# View logs
cat ~/.agent-logs/activity.log
cat ~/.agent-logs/crashes.log
```

### Crash protection:
If the agent crashes 3 times in one day, it halts and sends you a Telegram alert. This prevents infinite crash loops.
