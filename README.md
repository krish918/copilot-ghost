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

Pass a model name as the first argument. When omitted, the default model
`claude-haiku-4.5` is used.

```bash
__ "Fix the bug in main.go"                          # default: claude-haiku-4.5
__ claude-haiku-4.5 "Fix the bug in main.go"         # explicit default
__ claude-sonnet-4.6 "Fix the bug in main.go"        # smarter model
__ gpt-5-mini "Summarize this repo"                  # alternative fast model
__ claude-opus-4.8 "Refactor the entire auth module" # most capable model
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

## Session persistence

copilot-ghost keeps all `__` commands in the **same Copilot session** so the
agent retains context across invocations.

- The session id is stored in `~/.copilot/one-off-sessionid`.
- The session is valid for **5 days** from the last time the file was written.
- After 5 days the wrapper automatically rotates to a fresh session id.
- Every `__` call within that window resumes the same session — no matter which
  directory you run it from.

### Changing the session lifetime

Open `~/.copilot/copilot-wrapper.sh` and edit the `SESSION_LIFETIME_DAYS`
variable near the top:

```bash
# Number of days a one-off session is kept before a new one starts automatically.
# Increase this to preserve context longer; set to 0 to always start a fresh session.
SESSION_LIFETIME_DAYS=5
```

Examples:

```bash
SESSION_LIFETIME_DAYS=1    # 1 day
SESSION_LIFETIME_DAYS=14   # 2 weeks
SESSION_LIFETIME_DAYS=0    # always start a new session
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
2. Appends the `__` function to `~/.bashrc`, `~/.zshrc`, or both — whichever
   exist — if not already present:
   ```bash
   function __(){
     ~/.copilot/copilot-wrapper.sh "$@"
   }
   ```
3. Sources `~/.bashrc` automatically if it exists so `__` is available
   immediately in the current bash session. For zsh, a reminder is printed.
4. Runs `copilot-wrapper.sh` once with a no-op prompt to seed the session id
   file at `~/.copilot/one-off-sessionid`.

The install is **idempotent** — running it again is safe.

---

## Files

| File | Purpose |
|---|---|
| `copilot-wrapper.sh` | Core wrapper — model selection, session rotation, copilot invocation |
| `install.sh` | One-time installer |

---

## Requirements

- [GitHub Copilot CLI](https://githubnext.com/projects/copilot-cli) (`copilot` on `$PATH`)
- `uuid` command (`apt install uuid` / `brew install ossp-uuid`)
- bash or zsh
