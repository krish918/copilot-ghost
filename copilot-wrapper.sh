#!/bin/bash

SESSION_ID_FILE="$HOME/.copilot/one-off-sessionid"
FIVE_DAYS_SECONDS=$((5 * 24 * 60 * 60))
is_supported_model() {
    case "$1" in
        "claude-opus-4.8" | "claude-opus-4.7" | "claude-opus-4.6" | "claude-opus-4.5" | \
        "claude-sonnet-4.6" | "claude-sonnet-4.5" | \
        "claude-haiku-4.5" | \
        "gpt-5.5" | "gpt-5.4" | "gpt-5.3-codex" | "gpt-5.4-mini" | "gpt-5-mini" | \
        "gemini-3.1-pro-preview" | "gemini-3.5-flash")
          return 0
          ;;
        *)
          return 1
          ;;
    esac
}

MODEL="claude-sonnet-4.6"
PROMPT_START=1
RESUME=0

if is_supported_model "$1"; then
    MODEL="$1"
    PROMPT_START=2
fi

if [ "${@:$PROMPT_START:1}" = "--resume" ] || [ "${@:$PROMPT_START:1}" = "-r" ]; then
    RESUME=1
    PROMPT=""
else
    PROMPT="${@:$PROMPT_START}"
fi

if [ ! -f "$SESSION_ID_FILE" ]; then
    uuid > "$SESSION_ID_FILE"
elif [ -f "$SESSION_ID_FILE" ]; then
    FILE_MOD_TIME=$(stat -f%m "$SESSION_ID_FILE" 2>/dev/null || stat -c%Y "$SESSION_ID_FILE" 2>/dev/null)
    CURRENT_TIME=$(date +%s)
    FILE_AGE=$((CURRENT_TIME - FILE_MOD_TIME))
    
    if [ $FILE_AGE -gt $FIVE_DAYS_SECONDS ]; then
        uuid > "$SESSION_ID_FILE"
    fi
fi

SESSION_ID=$(cat "$SESSION_ID_FILE")

if [ $RESUME -eq 1 ]; then
    copilot --allow-all --add-dir "$(pwd)" --model "$MODEL" --session-id="$SESSION_ID"
else
    copilot --allow-all --add-dir "$(pwd)" --model "$MODEL" --session-id="$SESSION_ID" --prompt "$PROMPT"
fi
