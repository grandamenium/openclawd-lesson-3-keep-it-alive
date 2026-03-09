#!/usr/bin/env bash
# agent-wrapper.sh - Keep your Claude Code agent alive permanently
# Called by launchd. Manages tmux session, crash counting, and session timeouts.
# Usage: agent-wrapper.sh <project_dir>
#
# Lifecycle:
#   1. launchd starts this script
#   2. We create a tmux session and run claude inside it (provides PTY)
#   3. Claude bootstraps, creates /loop crons, runs until timeout (default 71h)
#   4. Timer kills the tmux session, wrapper exits, launchd respawns fresh
#
# User can attach: tmux attach -t my-agent
#
# NOTE: --dangerously-skip-permissions is required for headless mode.
# Agent boundaries are enforced via SOUL.md instructions, not CLI permissions.

set -euo pipefail

PROJECT_DIR="$1"
AGENT_NAME=$(basename "${PROJECT_DIR}")
LOG_DIR="${HOME}/.agent-logs"
CRASH_LOG="${LOG_DIR}/crashes.log"
CRASH_COUNT_FILE="${LOG_DIR}/.crash_count_today"
MAX_CRASHES_PER_DAY=3
TMUX_SESSION="my-agent"

mkdir -p "${LOG_DIR}"

# Source .env if it exists (for TELEGRAM_BOT_TOKEN, etc.)
if [[ -f "${PROJECT_DIR}/.env" ]]; then
    set -a
    source "${PROJECT_DIR}/.env"
    set +a
fi

# Source shell profile for global env vars (PATH, API keys, etc.)
for profile in "${HOME}/.zshrc" "${HOME}/.bashrc" "${HOME}/.bash_profile" "${HOME}/.profile"; do
    if [[ -f "${profile}" ]]; then
        # Only source export lines to avoid interactive shell issues
        grep -E '^export ' "${profile}" 2>/dev/null | while read -r line; do
            eval "${line}" 2>/dev/null || true
        done
        break
    fi
done

# --- Crash counting ---
TODAY=$(date +%Y-%m-%d)
if [[ -f "${CRASH_COUNT_FILE}" ]]; then
    STORED_DATE=$(cut -d: -f1 "${CRASH_COUNT_FILE}" 2>/dev/null || echo "")
    CRASH_COUNT=$(cut -d: -f2 "${CRASH_COUNT_FILE}" 2>/dev/null || echo "0")
else
    STORED_DATE=""
    CRASH_COUNT=0
fi

[[ "${STORED_DATE}" != "${TODAY}" ]] && CRASH_COUNT=0

if [[ ${CRASH_COUNT} -ge ${MAX_CRASHES_PER_DAY} ]]; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) HALTED: exceeded ${MAX_CRASHES_PER_DAY} crashes today. Manual restart required." >> "${CRASH_LOG}"

    # Alert on Telegram if configured
    # For private chats, TELEGRAM_ALLOWED_USER is the same as chat_id
    if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_ALLOWED_USER:-}" ]]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_ALLOWED_USER}" \
            -d text="ALERT: Your agent has crashed ${MAX_CRASHES_PER_DAY} times today and has been halted. Restart with: launchctl bootout gui/\$(id -u) ~/Library/LaunchAgents/com.my-agent.plist && launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/com.my-agent.plist" \
            > /dev/null 2>&1 || true
    fi

    sleep 86400
    exit 1
fi

# --- Session config ---
# Default 71 hours (255600s). /loop crons expire at 72h, so restart 1h before.
# Set "max_session_seconds" in config.json for testing (e.g. 120)
CONFIG_FILE="${PROJECT_DIR}/config.json"
MAX_SESSION=$(jq -r '.max_session_seconds // 255600' "${CONFIG_FILE}" 2>/dev/null || echo "255600")

# Startup delay (avoids issues on rapid restarts)
DELAY=$(jq -r '.startup_delay // 3' "${CONFIG_FILE}" 2>/dev/null || echo "3")
sleep ${DELAY}

# --- Startup prompt ---
STARTUP_PROMPT="You are starting a new session. Read all bootstrap files listed in CLAUDE.md. Then read config.json and set up your crons using /loop for each entry in the crons array. Start with the comms cron (1m) first. After crons are set up, send a Telegram message to the user saying you're back online and what you're about to work on."

cd "${PROJECT_DIR}"

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Starting fresh (session cap: ${MAX_SESSION}s)" >> "${LOG_DIR}/activity.log"

# Write a "booting" heartbeat so monitoring knows we're alive
HEARTBEAT_FILE="${LOG_DIR}/heartbeat.json"
printf '{"last_heartbeat":"%s","status":"booting","current_task":"starting fresh session"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${HEARTBEAT_FILE}"

# Prevent Mac from sleeping while agent runs
caffeinate -is -w $$ &

# Kill stale tmux session from previous run
tmux kill-session -t "${TMUX_SESSION}" 2>/dev/null || true

# Start Claude inside a tmux session
# tmux provides the PTY that Claude needs for interactive mode + /loop crons
tmux new-session -d -s "${TMUX_SESSION}" \
    "cd '${PROJECT_DIR}' && claude --dangerously-skip-permissions '${STARTUP_PROMPT}'"

# Background timer: kills tmux session after MAX_SESSION seconds
(
    sleep ${MAX_SESSION}
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) SESSION_TIMEOUT after ${MAX_SESSION}s" >> "${CRASH_LOG}"
    tmux kill-session -t "${TMUX_SESSION}" 2>/dev/null || true
) &
TIMER_PID=$!

# Wait for tmux session to end (claude exits or timer kills it)
while tmux has-session -t "${TMUX_SESSION}" 2>/dev/null; do
    sleep 5
done

# If we get here, tmux session ended
kill ${TIMER_PID} 2>/dev/null || true

# --- Classify the exit ---

# Check for rate limiting (prevents crash loops from API limits)
if tail -20 "${LOG_DIR}/stderr.log" 2>/dev/null | grep -qi "rate.limit\|429\|capacity"; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) RATE_LIMITED" >> "${CRASH_LOG}"
    RATE_COUNT=$(grep -c "RATE_LIMITED" "${CRASH_LOG}" 2>/dev/null || echo "0")
    BACKOFF=$((300 * (RATE_COUNT > 3 ? 4 : RATE_COUNT + 1)))
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Backing off ${BACKOFF}s due to rate limiting" >> "${LOG_DIR}/activity.log"
    sleep ${BACKOFF}
    exit 0  # Clean exit, launchd respawns after backoff
fi

# Timeout = clean lifecycle restart
if tail -1 "${CRASH_LOG}" 2>/dev/null | grep -q "SESSION_TIMEOUT"; then
    exit 0  # launchd respawns with fresh session
fi

# Otherwise = unexpected exit, count as crash
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) CRASH" >> "${CRASH_LOG}"
echo "${TODAY}:$((CRASH_COUNT + 1))" > "${CRASH_COUNT_FILE}"
exit 1
