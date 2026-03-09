#!/bin/bash
# Send a message to a Telegram chat
# Usage: bash .claude/skills/telegram-bot/send-telegram.sh <chat_id> "<message>"

BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
CHAT_ID="$1"
MESSAGE="$2"

if [ -z "$BOT_TOKEN" ]; then
  echo "ERROR: TELEGRAM_BOT_TOKEN not set"
  exit 1
fi

if [ -z "$CHAT_ID" ] || [ -z "$MESSAGE" ]; then
  echo "Usage: send-telegram.sh <chat_id> \"<message>\""
  exit 1
fi

# Send the message via Telegram Bot API
RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="$CHAT_ID" \
  --data-urlencode "text=$MESSAGE" \
  -d parse_mode="Markdown")

# Check for errors
if echo "$RESPONSE" | jq -e '.ok == true' > /dev/null 2>&1; then
  echo "Message sent successfully"
else
  echo "ERROR: Failed to send message:"
  echo "$RESPONSE" | jq -r '.description'
  exit 1
fi
