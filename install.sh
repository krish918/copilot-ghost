#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.copilot"
GHOST_DIR="$TARGET_DIR/.copilotghost"
WRAPPER_SOURCE="$SCRIPT_DIR/copilot-ghost.sh"
WRAPPER_TARGET="$GHOST_DIR/copilot-ghost.sh"
CONFIG_SOURCE="$SCRIPT_DIR/copilot-ghost.conf"
CONFIG_TARGET="$GHOST_DIR/copilot-ghost.conf"
SESSION_FILE="$GHOST_DIR/copilot-ghost-sessionid"
HOOK_BLOCK='function __(){
  ~/.copilot/.copilotghost/copilot-ghost.sh "$@"
}'

copy_wrapper() {
  mkdir -p "$GHOST_DIR"

  # Copy only the wrapper and the config (preserve existing config)
  cp -a "$WRAPPER_SOURCE" "$WRAPPER_TARGET"
  chmod 755 "$WRAPPER_TARGET" || true

  if [ -f "$CONFIG_SOURCE" ] && [ ! -f "$CONFIG_TARGET" ]; then
    cp -a "$CONFIG_SOURCE" "$CONFIG_TARGET"
  fi
}

ensure_hook() {
  local rc_file="$1"
  local rc_dir
  rc_dir="$(dirname "$rc_file")"
  mkdir -p "$rc_dir"

  if [ ! -f "$rc_file" ]; then
    printf '%s\n' "$HOOK_BLOCK" > "$rc_file"
    return 0
  fi

  if ! grep -Fq '~/.copilot/.copilotghost/copilot-ghost.sh "$@"' "$rc_file"; then
    printf '\n%s\n' "$HOOK_BLOCK" >> "$rc_file"
  fi
}

create_session() {
  if [ ! -x "$WRAPPER_TARGET" ]; then
    echo "wrapper is missing or not executable: $WRAPPER_TARGET" >&2
    exit 1
  fi


  if [ ! -s "$SESSION_FILE" ]; then
    "$WRAPPER_TARGET" "do nothing" >/dev/null
    if [ ! -s "$SESSION_FILE" ]; then
      echo "session id file was not created: $SESSION_FILE" >&2
      exit 1
    fi
  fi
}

copy_wrapper

rc_updated=0
if [ -f "$HOME/.bashrc" ]; then
  ensure_hook "$HOME/.bashrc"
  rc_updated=1
fi

if [ -f "$HOME/.zshrc" ]; then
  ensure_hook "$HOME/.zshrc"
  rc_updated=1
fi

if [ "$rc_updated" -eq 0 ]; then
  ensure_hook "$HOME/.bashrc"
fi

create_session

# Reload shell configuration where possible so __ is immediately available
if [ -f "$HOME/.bashrc" ]; then
  # shellcheck disable=SC1090
  . "$HOME/.bashrc" 2>/dev/null || true
  printf 'Reloaded ~/.bashrc\n'
fi

if [ -f "$HOME/.zshrc" ]; then
  printf '.zshrc was updated. Please source .zshrc file manually!\n'
fi

printf '\nInstalled copilot-ghost to %s\n' "$GHOST_DIR"
printf 'Config file at %s\n' "$CONFIG_TARGET"
printf 'Session id stored in %s\n' "$SESSION_FILE"
