---
name: onboarding
description: "Interactive setup wizard for your AI agent. Use when: user says /onboarding, or when setting up the agent for the first time. Detects existing setup from previous lessons and only adds what's new. Walks through identity, soul, tools, memory, heartbeat, persistence, and testing."
---

# Agent Onboarding Wizard

Walk the user through setting up their personal AI agent step by step via Telegram. Ask questions conversationally, fill out each file based on their answers, and set everything up.

**This onboarding is cumulative.** It detects what's already configured from previous lessons and skips those steps. Students work on ONE project that grows across lessons.

## Pre-Flight: Detect Existing Setup

Before starting, check what already exists:

```
IDENTITY_EXISTS = file exists: IDENTITY.md (and has content beyond template)
SOUL_EXISTS = file exists: SOUL.md (and has content beyond template)
USER_EXISTS = file exists: USER.md
TOOLS_EXISTS = file exists: TOOLS.md
MEMORY_EXISTS = file exists: MEMORY.md (and has content beyond template)
HEARTBEAT_EXISTS = file exists: HEARTBEAT.md (and has content beyond template)
TELEGRAM_EXISTS = file exists: .claude/skills/telegram-bot/check-telegram.sh
TELEGRAM_CONFIGURED = env var TELEGRAM_BOT_TOKEN is set and non-empty
PERSISTENCE_EXISTS = file exists: scripts/agent-wrapper.sh AND scripts/generate-launchd.sh
CONFIG_EXISTS = file exists: config.json
TMUX_INSTALLED = command -v tmux returns 0
```

Tell the user what you found:
- "I can see you already have: {list of what exists}"
- "I'll skip those and set up: {list of what's missing}"

If everything from lessons 1-2 is already configured, jump straight to Step 9 (Persistence).

---

## Flow

Run these steps in order. **Skip any step where the check shows it's already configured.** After each step, confirm what you wrote and ask if they want to change anything.

All interaction happens via Telegram. Read messages with `bash .claude/skills/telegram-bot/check-telegram.sh` and reply with `bash .claude/skills/telegram-bot/send-telegram.sh <chat_id> "<message>"`.

---

### Step 1: Identity (IDENTITY.md)

**Skip if:** IDENTITY_EXISTS = true

Ask the user these questions one at a time via Telegram:

1. "What do you want to name your agent?" (e.g., Paul, Jarvis, Friday, Echo)
2. "In one sentence, what's your agent's role?" (e.g., "My AI co-founder", "My personal assistant")
3. "What's the vibe? Pick 3-4 words." (e.g., sharp, warm, proactive, direct)
4. "Pick an emoji for your agent." (e.g., brain, robot, lightning)

Write to `IDENTITY.md` in the project root:

```markdown
# IDENTITY.md - Who I Am

- **Name:** {name}
- **Role:** {role}
- **Vibe:** {vibe words}
- **Emoji:** {emoji}

---

## How I Work

- **Proactive** - I check in, anticipate, and prepare before being asked
- **Direct** - No fluff, get to the point
- **Resourceful** - I try to figure it out before asking
- **Self-improving** - I evaluate my own performance and get better

---

*Created: {today's date}*
```

---

### Step 2: Soul (SOUL.md)

**Skip if:** SOUL_EXISTS = true

Tell the user: "Now we define your agent's personality and boundaries. This controls what it will and won't do on its own."

Ask:
1. "What's the primary purpose of your agent?"
2. "What should your agent do WITHOUT asking you first?" (e.g., research, organize, draft replies)
3. "What should your agent NEVER do without permission?" (e.g., send emails, post on social media, delete files)
4. "How should your agent communicate? Casual or professional? Brief or detailed?"

Write to `SOUL.md` in the project root:

```markdown
# SOUL.md - How I Behave

## Primary Purpose

{their answer}

---

## Human-in-the-Loop Philosophy

**Do autonomously (no permission needed):**
{list as bullet points}

**Always ask first (never do without permission):**
{list as bullet points}

**The rule of thumb:**
- Reversible actions (reading, researching, drafting, organizing) = autonomous
- Irreversible actions (sending, deleting, purchasing, posting) = ask first

---

## Communication Style

{their preference}

---

## Core Truths

- Be genuinely helpful, not performatively helpful. Skip the filler.
- Have opinions. Disagree when you think something is a bad idea.
- Be resourceful before asking. Read the file. Check the context. Search for it.
- Earn trust through competence. Be careful with external actions, bold with internal ones.
- Remember you're a guest. You have access to someone's life. Treat it with respect.

---

## Boundaries

- Private things stay private. Period.
- When in doubt, ask before acting externally.
- Never send half-baked replies to any messaging surface.
- You're not the user's voice - be careful in any communication.

---

*Created: {today's date}*
```

---

### Step 3: User (USER.md)

**Skip if:** USER_EXISTS = true

Tell the user: "This file tells your agent about you."

Ask:
1. "What's your name?"
2. "What do you do? (job, business, projects)"
3. "What's your typical daily schedule?"
4. "Any preferences your agent should know?"

Write to `USER.md`.

---

### Step 4: Tools (TOOLS.md)

**Skip if:** TOOLS_EXISTS = true

Check what tools are available:
1. Telegram skill at `.claude/skills/telegram-bot/` - note if present
2. Ask: "Do you have any MCP servers installed? (e.g., web search, Notion, GitHub, Gmail)"
3. Ask: "Any CLI tools your agent should know about?"

Write to `TOOLS.md`.

---

### Step 5: Memory System

**Skip if:** MEMORY_EXISTS = true

No questions needed. Create:

1. `MEMORY.md` with empty sections (Key Facts, Decisions & Preferences, Important Dates)
2. `memory/` folder and today's file (`memory/{YYYY-MM-DD}.md`)

Tell user: "Memory is set up. Your agent updates daily files and promotes important stuff to long-term memory."

---

### Step 6: Heartbeat (HEARTBEAT.md)

**Skip if:** HEARTBEAT_EXISTS = true

Tell user: "The heartbeat is your agent's regular check-in. Every 30 minutes, it runs this checklist on autopilot."

Ask what they want checked every 30 minutes. Suggest:
- Check Telegram for messages
- Check email for urgent items
- Check calendar for upcoming events
- Update daily memory
- Surface anything needing attention

Write to `HEARTBEAT.md`.

---

### Step 7: Update CLAUDE.md

Read the current `CLAUDE.md`. Update it to include all sections: bootstrap files (including config.json), cron management, memory system, heartbeat, Telegram bot, and persistence. Use the CLAUDE.md in the project root as the template - it has all the correct sections.

---

### Step 8: Telegram Test

**Skip if:** previous lessons confirmed Telegram is working

Tell user: "Let's make sure your Telegram bot is working."

1. Ask them to send a test message on Telegram
2. Check for it with `bash .claude/skills/telegram-bot/check-telegram.sh`
3. Reply in character

If Telegram isn't configured yet, walk them through:
1. Create a bot with @BotFather on Telegram
2. Copy the bot token
3. Set env vars in `~/.zshrc`:
   ```
   export TELEGRAM_BOT_TOKEN="your_token"
   export TELEGRAM_ALLOWED_USER="your_user_id"
   ```
4. Reload: `source ~/.zshrc`
5. Test by sending a message and running check-telegram.sh

---

### Step 9: Persistence Setup (NEW IN LESSON 3)

Tell the user via Telegram:

"Now we're going to make your agent permanent. Right now, if you close the terminal, your agent dies. We're going to set up three things:

1. **tmux** - gives your agent a terminal that survives closing your window
2. **launchd** - macOS's built-in service manager that restarts your agent if it ever dies
3. **caffeinate** - keeps your Mac awake while the agent runs

After this, your agent runs 24/7 in the background."

#### 9a: Check tmux

Run `command -v tmux` to check if tmux is installed.

If NOT installed, tell user:
"tmux isn't installed yet. Run this in your terminal: `brew install tmux`"

Wait for them to confirm it's installed, then verify with `command -v tmux`.

If already installed, say: "tmux is already installed."

#### 9b: Verify scripts exist

Check that these files exist:
- `scripts/agent-wrapper.sh`
- `scripts/generate-launchd.sh`

If they don't exist, tell the user there's an issue with the project setup. These should have been included in the example project.

Make both scripts executable:
```bash
chmod +x scripts/agent-wrapper.sh scripts/generate-launchd.sh
```

#### 9c: Explain what the scripts do

Tell the user (keep it brief):

"Here's how it works:

**agent-wrapper.sh** - The lifecycle manager. It:
- Creates a tmux session for your agent to live in
- Starts Claude Code inside that session
- Runs a 71-hour timer (crons expire at 72h, so we restart 1h early)
- When the timer fires, it kills the session cleanly
- launchd sees it died and restarts it fresh
- Tracks crashes - if it crashes 3x in a day, it halts and alerts you on Telegram

**generate-launchd.sh** - Creates the macOS config file that tells launchd to manage your agent. Run once to set up."

---

### Step 10: Test with Short Timeout

Tell user: "Let's test with a 3-minute timeout so we can watch the full lifecycle."

#### 10a: Set test timeout

Add `max_session_seconds` to config.json:
```json
{
  "max_session_seconds": 180,
  "startup_delay": 3,
  "crons": [...]
}
```

Tell user: "I've set the session timeout to 3 minutes for testing."

#### 10b: Generate and load launchd config

Run:
```bash
bash scripts/generate-launchd.sh "$(pwd)"
```

Then tell the user to run these commands in their terminal (they need to do this manually since it requires system permissions):

```
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.my-agent.plist
```

Tell them: "Run that command in your terminal. It registers your agent with macOS."

#### 10c: Verify it started

Wait a few seconds, then check:
```bash
tmux ls
```

Tell user: "Your agent should now be running in a tmux session called 'my-agent'. You can attach to it with: `tmux attach -t my-agent`"

Also tell them: "Detach without killing by pressing Ctrl+B then D"

#### 10d: Watch the lifecycle

Tell user: "Now we wait 3 minutes for the timeout. When it fires:
1. The tmux session will die
2. launchd will restart it within seconds
3. A new tmux session will appear
4. Your agent will bootstrap fresh - read all its files, recreate crons"

Tell them to run `tmux ls` periodically or just watch. After ~2.5 minutes:
```bash
tmux ls
```

If a new session appeared, say: "The lifecycle works. Your agent restarted itself."

---

### Step 11: Go Live

Tell user: "Now we remove the test timeout and go to production."

#### 11a: Remove test config

Remove `max_session_seconds` from config.json (or set it to the default 255600):

```json
{
  "startup_delay": 3,
  "crons": [...]
}
```

#### 11b: Model Selection

Tell the user:

"**Important: Choose the right model for your agent.**

If your agent has frequent heartbeats (every 1-5 minutes) with significant work each cycle, switch to **Sonnet** to avoid burning through API credits. Opus is smarter but costs ~5x more per token.

**Rule of thumb:**
- **Sonnet** - Best for agents that run frequently and do routine work (checking messages, monitoring, heartbeats). This is what most agents should use for 24/7 operation.
- **Opus** - Reserve for complex reasoning, planning, or creative work where quality matters more than cost.

To set the model, run: `claude config set model sonnet`

Or add to your project's `.claude/settings.json`:
```json
{
  \"model\": \"sonnet\"
}
```

For a 24/7 agent checking Telegram every minute and running heartbeats every 30 minutes, **Sonnet is strongly recommended.**"

#### 11c: Restart with production config

Tell user to run:
```
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.my-agent.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.my-agent.plist
```

#### 11d: Verify

```bash
tmux ls
```

Tell user: "Your agent is now running permanently. It will restart every 71 hours with fresh context. Close your terminal - it keeps running. Restart your Mac - it starts on login."

Give them the key commands:
```
# See your agent live
tmux attach -t my-agent

# Detach without killing
Ctrl+B then D

# Check if running
tmux ls

# Restart manually
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.my-agent.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.my-agent.plist

# View logs
cat ~/.agent-logs/activity.log
cat ~/.agent-logs/crashes.log
```

---

### Step 12: Final Confirmation

Send a Telegram message to the user:

"Your agent is fully set up and running permanently:
- Identity, soul, memory, heartbeat - all configured
- Telegram communication - active
- Persistence via launchd + tmux - running 24/7
- Auto-restart every 71 hours with fresh context
- Crash protection with Telegram alerts

Close every terminal on your computer. Open a new one tomorrow. I'll still be here."

---

## Important Notes

- Always write files to the PROJECT ROOT, not inside .claude/
- Use today's actual date for all date fields
- Keep the conversational tone - this should feel like a setup wizard, not a form
- After each file is written, briefly confirm what was written
- If the user seems unsure about an answer, give examples to help them decide
- **Detect existing setup and skip completed steps** - don't redo lesson 1+2 work
- All interaction happens via Telegram (check-telegram.sh / send-telegram.sh)
- The user needs to run launchctl commands manually in their terminal (system permission required)
