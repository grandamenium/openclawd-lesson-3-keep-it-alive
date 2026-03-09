---
name: telegram-bot
description: "Check for new Telegram messages and send replies. Use when: the /loop cron fires and you need to check for incoming Telegram messages, or when you need to send a reply back to the user on Telegram."
---

# Telegram Bot Skill

Send and receive messages via a personal Telegram bot.

## Scripts

### Check for new messages
```bash
bash .claude/skills/telegram-bot/check-telegram.sh
```
Returns JSON of new messages from the allowed user. Returns nothing if no new messages.

### Send a reply
```bash
bash .claude/skills/telegram-bot/send-telegram.sh <chat_id> "<message>"
```
Sends a text message to the specified chat ID. Supports Markdown formatting.

## Environment Variables Required

- `TELEGRAM_BOT_TOKEN` - Bot token from @BotFather
- `TELEGRAM_ALLOWED_USER` - Your Telegram user ID (only messages from this user are processed)
- Set both in `~/.zshrc`:
  ```
  export TELEGRAM_BOT_TOKEN="your_token_here"
  export TELEGRAM_ALLOWED_USER="your_user_id_here"
  ```

## How It Works

1. `check-telegram.sh` calls the Telegram Bot API `getUpdates` endpoint
2. It tracks the last seen message offset in `~/.claude-telegram-offset`
3. Only messages from the allowed user ID are returned (others silently dropped)
4. `send-telegram.sh` calls the `sendMessage` endpoint with Markdown support

## Notes

- The offset file prevents reprocessing old messages
- If no new messages exist, check-telegram returns empty output
- Messages from unauthorized users are filtered out before Claude sees them
