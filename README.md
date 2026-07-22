# copilot-ghost

**copilot-ghost** is a lightweight shell wrapper for [GitHub Copilot CLI](https://githubnext.com/projects/copilot-cli) that gives you a persistent, named session reachable from any directory via the short `__` alias.

It installs itself into `~/.copilot`, wires up the `__` function in your shell rc files, and boots a session id that all future `__` invocations share — so Copilot remembers context across commands.

---

> [!CAUTION]
> **copilot-ghost always runs in privileged mode** (`--allow-all`). The agent
> has unrestricted access to your file system and can execute commands without
> asking for confirmation. Avoid using it for tasks that require human
> supervision, interactive approval, or any action you would not want run
> automatically — such as destructive file operations, pushes to remote
> repositories, or network requests to external services. Always review what
> you are asking the agent to do before invoking `__`.

---

## Quick start

```bash
git clone https://github.com/krish918/copilot-ghost.git
cd copilot-ghost
./install.sh
```

The installer reloads `~/.bashrc` automatically. If you use zsh, run `source ~/.zshrc` once in your open zsh session.

Run your first command:

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
__ "Fix the bug in main.go"                          # uses DEFAULT_MODEL from config
__ gpt-5-mini "Fix the bug in main.go"               # override for this call only
__ claude-haiku-4.5 "Fix the bug in main.go"         # fast Claude model
__ claude-sonnet-4.6 "Fix the bug in main.go"        # smarter model
__ claude-opus-4.8 "Refactor the entire auth module" # most capable model
```

To change the default model permanently:

```bash
__ --set-model claude-sonnet-4.6
```

Supported models:

| Model | ID |
|---|---|
| Claude Opus 4.8 | `claude-opus-4.8` |
| Claude Opus 4.7 | `claude-opus-4.7` |
| Claude Opus 4.6 | `claude-opus-4.6` |
| Claude Opus 4.5 | `claude-opus-4.5` |
| Claude Sonnet 4.6 | `claude-sonnet-4.6` |
| Claude Sonnet 4.5 | `claude-sonnet-4.5` |
| Claude Haiku 4.5 | `claude-haiku-4.5` |
| GPT-5.5 | `gpt-5.5` |
| GPT-5.4 | `gpt-5.4` |
| GPT-5.3 Codex | `gpt-5.3-codex` |
| GPT-5.4 mini | `gpt-5.4-mini` |
| GPT-5 mini *(default)* | `gpt-5-mini` |
| Gemini 3.1 Pro Preview | `gemini-3.1-pro-preview` |
| Gemini 3.5 Flash | `gemini-3.5-flash` |

### Resume interactive mode

```bash
__ --resume   # or: __ -r
```

---

## Configuration

copilot-ghost reads its settings from `~/.copilot/copilot-ghost.conf`, a plain
`KEY=VALUE` file installed alongside the wrapper. Edit it directly or use the
built-in subcommands.

```ini
# Default model used when no model is given as the first argument.
DEFAULT_MODEL=gpt-5-mini

# Number of days a one-off session is preserved before a new one starts.
SESSION_LIFETIME_DAYS=7
```

### Subcommands

| Command | Effect |
|---|---|
| `__ --set-model <model-id>` | Update `DEFAULT_MODEL` in the config file |
| `__ --set-ttl <days>` | Update `SESSION_LIFETIME_DAYS` in the config file |
| `__ --config` | Print the current config file path and contents |

Examples:

```bash
__ --set-model claude-sonnet-4.6   # switch default to Sonnet
__ --set-model gpt-5-mini          # switch back to GPT-5 mini
__ --set-ttl 14                    # keep session for 2 weeks
__ --set-ttl 0                     # always start a fresh session
__ --config                        # inspect current settings
```

---

## Session persistence

copilot-ghost keeps all `__` commands in the **same Copilot session** so the
agent retains context across invocations.

- The session id is stored in `~/.copilot/one-off-sessionid`.
- The session is valid for **`SESSION_LIFETIME_DAYS`** days (default: 7) from the last time the file was written.
- After that window the wrapper automatically rotates to a fresh session id.
- Every `__` call within that window resumes the same session — no matter which
  directory you run it from.

### Changing the session lifetime

Use the subcommand (updates `~/.copilot/copilot-ghost.conf` immediately):

```bash
__ --set-ttl 7    # 7 days (default)
__ --set-ttl 1    # 1 day
__ --set-ttl 14   # 2 weeks
__ --set-ttl 0    # always start a new session
```

Or edit `~/.copilot/copilot-ghost.conf` directly and change:

```ini
SESSION_LIFETIME_DAYS=7
```

### Force a new session immediately

Delete the session id file:

```bash
rm ~/.copilot/one-off-sessionid
```

The next `__` call will create a fresh session.

---

## How it works

`install.sh` does the following steps:

1. Copies `copilot-wrapper.sh` to `~/.copilot/copilot-wrapper.sh`.
2. Copies `copilot-ghost.conf` to `~/.copilot/copilot-ghost.conf` (skipped if
   already present, so user customisations are preserved on reinstall).
3. Appends the `__` function to `~/.bashrc`, `~/.zshrc`, or both — whichever
   exist — if not already present:
   ```bash
   function __(){
     ~/.copilot/copilot-wrapper.sh "$@"
   }
   ```
4. Sources `~/.bashrc` automatically if it exists so `__` is available
   immediately in the current bash session. For zsh, a reminder is printed.
5. Runs `copilot-wrapper.sh` once with a no-op prompt to seed the session id
   file at `~/.copilot/one-off-sessionid`.

The install is **idempotent** — running it again is safe.

---

## Files

| File | Purpose |
|---|---|
| `copilot-wrapper.sh` | Core wrapper — config loading, subcommands, session rotation, copilot invocation |
| `copilot-ghost.conf` | Default configuration (copied to `~/.copilot/` on install) |
| `install.sh` | One-time installer |

---

## Requirements

- [GitHub Copilot CLI](https://githubnext.com/projects/copilot-cli) (`copilot` on `$PATH`)
- `uuid` command (`apt install uuid` / `brew install ossp-uuid`)
- bash or zsh
