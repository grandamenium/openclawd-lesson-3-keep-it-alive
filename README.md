# Lesson 3: Keep It Alive - Persistence, tmux, and Auto-Restart

Your agent dies when you close the terminal. This lesson makes it permanent.

## What This Adds

Building on your project from Lessons 1 and 2, this adds:

- **`scripts/agent-wrapper.sh`** - Lifecycle manager (tmux, caffeinate, crash counting, rate limit backoff)
- **`scripts/generate-launchd.sh`** - Generates macOS launchd config to keep your agent alive forever
- **`config.json`** - Cron definitions your agent recreates on every restart
- **Updated `CLAUDE.md`** - Cron management and persistence instructions
- **Updated onboarding skill** - Detects existing setup, walks you through persistence via Telegram

## How to Use

**If you completed Lessons 1 and 2** (you have a working project with IDENTITY.md, SOUL.md, Telegram bot, etc.):

1. Open Claude Code in your existing project
2. Tell Claude:
   ```
   Pull in the lesson 3 files from https://github.com/grandamenium/openclawd-lesson-3-keep-it-alive - I need the scripts/, config.json, and the updated CLAUDE.md and onboarding skill. Don't overwrite my IDENTITY.md, SOUL.md, MEMORY.md, or any personalized files.
   ```
3. Run `/onboarding` - it detects your existing setup and jumps to persistence
4. Follow the Telegram conversation to test and go live

**If you're starting fresh** (didn't do Lessons 1 and 2):

1. Clone this repo: `git clone https://github.com/grandamenium/openclawd-lesson-3-keep-it-alive`
2. `cd openclawd-lesson-3-keep-it-alive`
3. Run `claude` then `/onboarding` - it walks you through everything from scratch

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed
- Telegram bot from Lesson 1 (or create one during onboarding)
- tmux installed (`brew install tmux`)
- macOS (launchd is macOS-only)

## Key Commands After Setup

```bash
# See your agent's live session
tmux attach -t my-agent

# Detach without killing (Ctrl+B then D)

# Check if running
tmux ls

# Restart
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.my-agent.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.my-agent.plist

# View logs
cat ~/.agent-logs/activity.log
cat ~/.agent-logs/crashes.log
```

## Course

This is **Module 1, Lesson 3** of the [OpenClawdCode](https://www.skool.com/openclawdcode) course.

- Lesson 1: [Your First Telegram Bot](https://github.com/grandamenium/openclawd-lesson-1-telegram-bot)
- Lesson 2: [Give Your Agent a Soul](https://github.com/grandamenium/openclawd-lesson-2-agent-soul)
- **Lesson 3: Keep It Alive** (you are here)
