# copilot-ghost

**copilot-ghost** is a lightweight shell wrapper for [GitHub Copilot CLI](https://githubnext.com/projects/copilot-cli) that gives you a persistent, named session reachable from any directory via the short `__` alias.

---

> [!CAUTION]
> **copilot-ghost always runs in privileged mode** (`--allow-all`). The agent
> has unrestricted access to your file system and can execute commands without
> asking for confirmation. Avoid using it for tasks that require human
> supervision, interactive approval, or any action you would not want run
> automatically.

---


## Requirements

- [GitHub Copilot CLI](https://githubnext.com/projects/copilot-cli) (`copilot` on `$PATH`)
- `uuid` command (`apt install uuid` / `brew install ossp-uuid`)
- bash or zsh

## Quick start

```bash
git clone https://github.com/krish918/copilot-ghost.git
cd copilot-ghost
./install.sh
```

The installer reloads `~/.bashrc` automatically. If you use zsh, run `source ~/.zshrc` once in your open zsh session.

Run your first command on your shell:

```bash
__ give the largest file in my current directory which is not owned by me
```

---

## Usage

```bash
__ <prompt>
```

> [!TIP]
> **Always quote your prompt** or escape special characters. Shell metacharacters
> like `!`, `$`, `&`, `|`, `>`, `<`, `;`, `(`, `)`, `` ` ``, and `\` can be
> interpreted by the shell before the wrapper receives them. Use single quotes to
> pass a prompt literally, or double quotes with `\` escaping where needed:
>
> ```bash
> __ 'Why does $HOME expand to nothing?'          # single quotes: literal
> __ "List files ending in *.go"                  # double quotes: safe for most cases
> __ "What does \`git status\` show?"             # escape backticks in double quotes
> __ 'Run: echo "hello & goodbye"'                # single quotes handle & and "
> ```

### Choose a model

Pass a model name as the first argument to override for a single call. The
persistent default is read from `~/.copilot/copilot-ghost.conf`.

```bash
__ "Fix the bug in main.go"                          # uses DEFAULT_MODEL from config (claude-haiku-4.5)
__ claude-haiku-4.5 "Fix the bug in main.go"         # explicit default
__ claude-haiku-4.5 "Fix the bug in main.go"         # fast Claude model
__ claude-sonnet-4.6 "Fix the bug in main.go"        # smarter model
__ claude-opus-4.8 "Refactor the entire auth module" # most capable model
```

To change the default model permanently:

```bash
__ --set-model claude-sonnet-4.6
```

Example models and their IDs to be used in your commands:

| Model | ID |
|---|---|
| Claude Opus 4.8 | `claude-opus-4.8` |
| Claude Opus 4.7 | `claude-opus-4.7` |
| Claude Opus 4.6 | `claude-opus-4.6` |
| Claude Opus 4.5 | `claude-opus-4.5` |
| Claude Sonnet 4.6 | `claude-sonnet-4.6` |
| Claude Sonnet 4.5 | `claude-sonnet-4.5` |
| Claude Haiku 4.5 *(default)* | `claude-haiku-4.5` |
| GPT-5.5 | `gpt-5.5` |
| GPT-5.4 | `gpt-5.4` |
| GPT-5.3 Codex | `gpt-5.3-codex` |
| GPT-5.4 mini | `gpt-5.4-mini` |
| GPT-5 mini | `gpt-5-mini` |
| Gemini 3.1 Pro Preview | `gemini-3.1-pro-preview` |
| Gemini 3.5 Flash | `gemini-3.5-flash` |

### Resume interactive mode

```bash
__ --resume   # or: __ -r
```

---

## Configuration

copilot-ghost reads its settings from `~/.copilot/.copilotghost/copilot-ghost.conf`, a plain
`KEY=VALUE` file installed alongside the wrapper. Edit it directly or use the
built-in subcommands.

```ini
# Default model used when no model is given as the first argument.
DEFAULT_MODEL=claude-haiku-4.5

# Number of days a one-off session is preserved before a new one starts.
SESSION_LIFETIME_DAYS=7
```

### Configuring from command line

| Command | Effect |
|---|---|
| `__ --set-model <model-id>` | Update `DEFAULT_MODEL` in the config file |
| `__ --set-ttl <days>` | Update `SESSION_LIFETIME_DAYS` in the config file |
| `__ --config` | Print the current config file path and contents |

Examples:

```bash
__ --set-model gpt-5.4-mini        # switch default model to GPT 5.4 Mini
__ --set-ttl 14                    # keep session for 2 weeks
__ --set-ttl 0                     # always start a fresh session
__ --config                        # inspect current settings
```

---

## Session persistence

copilot-ghost keeps all `__` commands in the **same Copilot session** so the
agent retains context across invocations.

- The session id is stored in `~/.copilot/.copilotghost/copilot-ghost-sessionid`.
- The session is valid for **`SESSION_LIFETIME_DAYS`** days (default: 7) from the last time the file was written.
- After that window the wrapper automatically rotates to a fresh session id.
- Every `__` call within that window resumes the same session — no matter which
  directory you run it from.

### Changing the session lifetime

Use the following options:

```bash
__ --set-ttl 7    # 7 days (default)
__ --set-ttl 1    # 1 day
__ --set-ttl 14   # 2 weeks
__ --set-ttl 0    # always start a new session
```

---

## Files

| File | Purpose |
|---|---|
| `copilot-ghost.sh` | Core wrapper — config loading, subcommands, session rotation, copilot invocation |
| `copilot-ghost.conf` | Default configuration |
| `install.sh` | One-time installer |

---
