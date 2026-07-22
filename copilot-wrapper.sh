#!/bin/bash

COPILOT_DIR="$HOME/.copilot"
CONFIG_FILE="$COPILOT_DIR/copilot-ghost.conf"
SESSION_ID_FILE="$COPILOT_DIR/one-off-sessionid"

# Built-in defaults (used when config file is absent or a key is missing)
DEFAULT_MODEL="gpt-5-mini"
SESSION_LIFETIME_DAYS=7

# Load config — plain KEY=VALUE file, sourced directly
# shellcheck disable=SC1090
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

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

set_config_value() {
    local key="$1" value="$2"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Config file not found: $CONFIG_FILE" >&2
        exit 1
    fi
    # Replace the value in-place (works on both GNU and BSD sed via tmp file)
    local tmp
    tmp="$(mktemp)"
    sed "s|^[[:space:]]*${key}[[:space:]]*=.*|${key}=${value}|" "$CONFIG_FILE" > "$tmp"
    mv "$tmp" "$CONFIG_FILE"
    echo "Set ${key}=${value} in $CONFIG_FILE"
}

SESSION_LIFETIME_SECONDS=$((SESSION_LIFETIME_DAYS * 24 * 60 * 60))

# Handle subcommands before treating args as a prompt
case "${1:-}" in
    --set-model)
        if [ -z "${2:-}" ]; then
            echo "Usage: __ --set-model <model-id>" >&2; exit 1
        fi
        if ! is_supported_model "$2"; then
            echo "Unsupported model: $2" >&2; exit 1
        fi
        set_config_value "DEFAULT_MODEL" "$2"
        exit 0
        ;;
    --set-ttl)
        if [ -z "${2:-}" ] || ! printf '%s' "$2" | grep -qE '^[0-9]+$'; then
            echo "Usage: __ --set-ttl <days>" >&2; exit 1
        fi
        set_config_value "SESSION_LIFETIME_DAYS" "$2"
        exit 0
        ;;
    --config)
        echo "Config file: $CONFIG_FILE"
        cat "$CONFIG_FILE"
        exit 0
        ;;
esac

MODEL="$DEFAULT_MODEL"
PROMPT_START=1
RESUME=0

if is_supported_model "${1:-}"; then
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
else
    FILE_MOD_TIME=$(stat -f%m "$SESSION_ID_FILE" 2>/dev/null || stat -c%Y "$SESSION_ID_FILE" 2>/dev/null)
    CURRENT_TIME=$(date +%s)
    FILE_AGE=$((CURRENT_TIME - FILE_MOD_TIME))
    if [ "$FILE_AGE" -gt "$SESSION_LIFETIME_SECONDS" ]; then
        uuid > "$SESSION_ID_FILE"
    fi
fi

SESSION_ID=$(cat "$SESSION_ID_FILE")

if [ "$RESUME" -eq 1 ]; then
    copilot --allow-all --add-dir "$(pwd)" --model "$MODEL" --session-id="$SESSION_ID"
else
    copilot --allow-all --add-dir "$(pwd)" --model "$MODEL" --session-id="$SESSION_ID" --prompt "$PROMPT"
fi
