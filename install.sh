#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.copilot"
WRAPPER_SOURCE="$SCRIPT_DIR/copilot-wrapper.sh"
WRAPPER_TARGET="$TARGET_DIR/copilot-wrapper.sh"
SESSION_FILE="$TARGET_DIR/one-off-sessionid"
HOOK_BLOCK='function __(){
  ~/.copilot/copilot-wrapper.sh "$@"
}'

copy_wrapper() {
  mkdir -p "$TARGET_DIR"
  cp "$WRAPPER_SOURCE" "$WRAPPER_TARGET"
  chmod 755 "$WRAPPER_TARGET"
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

  if ! grep -Fq '~/.copilot/copilot-wrapper.sh "$@"' "$rc_file"; then
    printf '\n%s\n' "$HOOK_BLOCK" >> "$rc_file"
  fi
}

create_session() {
  if [ ! -x "$WRAPPER_TARGET" ]; then
    echo "wrapper is missing or not executable: $WRAPPER_TARGET" >&2
    exit 1
  fi

  "$WRAPPER_TARGET" "do nothing" >/dev/null

  if [ ! -s "$SESSION_FILE" ]; then
    echo "session id file was not created: $SESSION_FILE" >&2
    exit 1
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

if [ -n "${BASH_VERSION:-}" ] && [ -f "$HOME/.bashrc" ]; then
  # shellcheck disable=SC1090
  . "$HOME/.bashrc"
fi

create_session

printf 'Installed wrapper to %s\n' "$WRAPPER_TARGET"
printf 'Session id stored in %s\n' "$SESSION_FILE"
