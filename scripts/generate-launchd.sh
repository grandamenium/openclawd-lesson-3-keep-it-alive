#!/usr/bin/env bash
# generate-launchd.sh - Generate a macOS launchd plist to keep your agent alive
# Usage: generate-launchd.sh <project_dir>
#
# Creates ~/Library/LaunchAgents/com.my-agent.plist
# The plist tells macOS to run agent-wrapper.sh on login and restart it if it dies.

set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"
SCRIPT_DIR="${PROJECT_DIR}/scripts"
PLIST_NAME="com.my-agent"
PLIST_PATH="${HOME}/Library/LaunchAgents/${PLIST_NAME}.plist"
LOG_DIR="${HOME}/.agent-logs"

# Verify agent-wrapper.sh exists
if [[ ! -f "${SCRIPT_DIR}/agent-wrapper.sh" ]]; then
    echo "ERROR: agent-wrapper.sh not found at ${SCRIPT_DIR}/agent-wrapper.sh" >&2
    exit 1
fi

# Auto-detect where claude binary lives
CLAUDE_BIN=$(which claude 2>/dev/null || echo "")
if [[ -z "${CLAUDE_BIN}" ]]; then
    echo "ERROR: 'claude' not found in PATH. Make sure Claude Code CLI is installed." >&2
    echo "Install: npm install -g @anthropic-ai/claude-code" >&2
    exit 1
fi
CLAUDE_DIR=$(dirname "${CLAUDE_BIN}")

# Build PATH for launchd (it doesn't inherit your shell PATH)
LAUNCHD_PATH="${CLAUDE_DIR}:/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin"

# Add common tool directories if they exist
for extra_dir in "${HOME}/.pyenv/shims" "${HOME}/.nvm/versions/node/"*/bin; do
    [[ -d "${extra_dir}" ]] && LAUNCHD_PATH="${extra_dir}:${LAUNCHD_PATH}"
done

mkdir -p "${HOME}/Library/LaunchAgents" "${LOG_DIR}"

# Make wrapper executable
chmod +x "${SCRIPT_DIR}/agent-wrapper.sh"

cat > "${PLIST_PATH}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPT_DIR}/agent-wrapper.sh</string>
        <string>${PROJECT_DIR}</string>
    </array>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>${LAUNCHD_PATH}</string>
        <key>HOME</key>
        <string>${HOME}</string>
        <key>LANG</key>
        <string>en_US.UTF-8</string>
    </dict>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>${LOG_DIR}/stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/stderr.log</string>

    <key>WorkingDirectory</key>
    <string>${PROJECT_DIR}</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST

echo "Plist generated at: ${PLIST_PATH}"
echo ""
echo "To start your agent:"
echo "  launchctl bootstrap gui/\$(id -u) ${PLIST_PATH}"
echo ""
echo "To stop your agent:"
echo "  launchctl bootout gui/\$(id -u) ${PLIST_PATH}"
echo ""
echo "To restart:"
echo "  launchctl bootout gui/\$(id -u) ${PLIST_PATH} 2>/dev/null; launchctl bootstrap gui/\$(id -u) ${PLIST_PATH}"
