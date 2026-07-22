#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.copilot"
GHOST_DIR="$TARGET_DIR/copilot-ghost"
WRAPPER_SOURCE="$SCRIPT_DIR/copilot-wrapper.sh"
WRAPPER_TARGET="$GHOST_DIR/copilot-wrapper.sh"
CONFIG_SOURCE="$SCRIPT_DIR/copilot-ghost.conf"
CONFIG_TARGET="$GHOST_DIR/copilot-ghost.conf"
SESSION_FILE="$TARGET_DIR/one-off-sessionid"
HOOK_BLOCK='function __(){
  ~/.copilot/copilot-ghost/copilot-wrapper.sh "$@"
}'

copy_wrapper() {
  mkdir -p "$GHOST_DIR"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete --exclude 'copilot-ghost.conf' "$SCRIPT_DIR/" "$GHOST_DIR/"
    # copy config only if not present
    if [ ! -f "$CONFIG_TARGET" ] && [ -f "$CONFIG_SOURCE" ]; then
      cp "$CONFIG_SOURCE" "$CONFIG_TARGET"
    fi
  else
    # fallback: copy files individually but preserve existing config
    for f in "$SCRIPT_DIR"/*; do
      base="$(basename "$f")"
      if [ "$base" = "copilot-ghost.conf" ] && [ -f "$CONFIG_TARGET" ]; then
        continue
      fi
      cp -a "$f" "$GHOST_DIR/"
    done
  fi

  chmod 755 "$WRAPPER_TARGET" || true
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

  if ! grep -Fq '~/.copilot/copilot-ghost/copilot-wrapper.sh "$@"' "$rc_file"; then
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

create_session

# Reload shell configuration where possible so __ is immediately available
if [ -f "$HOME/.bashrc" ]; then
  # shellcheck disable=SC1090
  . "$HOME/.bashrc"
  printf 'Reloaded ~/.bashrc\n'
fi

if [ -f "$HOME/.zshrc" ]; then
  printf 'Note: ~/.zshrc was updated — run `source ~/.zshrc` in any open zsh session.\n'
fi

printf 'Installed copilot-ghost to %s\n' "$GHOST_DIR"
printf 'Config file at %s\n' "$CONFIG_TARGET"
printf 'Session id stored in %s\n' "$SESSION_FILE"
