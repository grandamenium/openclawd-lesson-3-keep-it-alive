#!/bin/bash
# Check for new Telegram messages from the allowed user
# Usage: bash .claude/skills/telegram-bot/check-telegram.sh

BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
ALLOWED_USER="${TELEGRAM_ALLOWED_USER}"  # Your Telegram user ID - set in ~/.zshrc
OFFSET_FILE="$HOME/.claude-telegram-offset"

if [ -z "$BOT_TOKEN" ]; then
  echo "ERROR: TELEGRAM_BOT_TOKEN not set. Add to ~/.zshrc:"
  echo '  export TELEGRAM_BOT_TOKEN="your_token_here"'
  exit 1
fi

if [ -z "$ALLOWED_USER" ]; then
  echo "ERROR: TELEGRAM_ALLOWED_USER not set. Add to ~/.zshrc:"
  echo '  export TELEGRAM_ALLOWED_USER="your_telegram_user_id"'
  echo 'To find your ID, send a message to your bot and run:'
  echo "  curl -s \"https://api.telegram.org/bot\${TELEGRAM_BOT_TOKEN}/getUpdates\" | jq '.result[0].message.from.id'"
  exit 1
fi

# Read last processed offset
OFFSET=$(cat "$OFFSET_FILE" 2>/dev/null || echo "0")

# Fetch new updates from Telegram
RESPONSE=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?offset=${OFFSET}&timeout=5")

# Check for API errors
if echo "$RESPONSE" | jq -e '.ok == false' > /dev/null 2>&1; then
  echo "ERROR: Telegram API returned error:"
  echo "$RESPONSE" | jq -r '.description'
  exit 1
fi

# Filter to only messages from the allowed user
MESSAGES=$(echo "$RESPONSE" | jq --arg uid "$ALLOWED_USER" '[.result[] | select(.message.from.id == ($uid | tonumber))]')

# Update offset to acknowledge all received updates (including filtered ones)
NEW_OFFSET=$(echo "$RESPONSE" | jq '.result[-1].update_id + 1 // empty')
if [ -n "$NEW_OFFSET" ]; then
  echo "$NEW_OFFSET" > "$OFFSET_FILE"
fi

# Output only if there are messages from the allowed user
MSG_COUNT=$(echo "$MESSAGES" | jq 'length')
if [ "$MSG_COUNT" -gt 0 ]; then
  echo "$MESSAGES" | jq -c '.[] | {
    chat_id: .message.chat.id,
    from: .message.from.first_name,
    text: .message.text,
    date: .message.date
  }'
fi
