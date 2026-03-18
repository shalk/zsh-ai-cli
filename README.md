# zsh-ai-cli

A zsh plugin that checks for updates to AI CLI development tools and notifies you when new versions are available.

## Features

- Automatic periodic update checks without blocking your shell
- Multiple tool support: Gemini CLI, Claude Code, GitHub Copilot, OpenAI Codex, Kiro
- Smart caching to avoid excessive npm registry queries
- Banner or silent notification styles
- Manual check and upgrade commands

## Supported Tools

| Tool | Package / Install | Command |
|------|-------------------|---------|
| Gemini CLI | `@google/gemini-cli` (npm) | `gemini` |
| Claude Code | `claude-code` (npm) | `claude` |
| GitHub Copilot | `@github/copilot` (npm) | `copilot` |
| OpenAI Codex | `@openai/codex` (npm) | `codex` |
| Kiro | Script installer | `kiro` |

## Installation

### oh-my-zsh

```zsh
git clone https://github.com/shalk/zsh-ai-cli \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ai-cli
```

Add `ai-cli` to your plugins list in `~/.zshrc`:

```zsh
plugins=(... ai-cli)
```

### zinit

```zsh
zinit light shalk/zsh-ai-cli
```

### zplug

```zsh
zplug "shalk/zsh-ai-cli"
```

### Manual

```zsh
git clone https://github.com/shalk/zsh-ai-cli ~/.zsh/zsh-ai-cli
# Add to ~/.zshrc:
source ~/.zsh/zsh-ai-cli/ai-cli.plugin.zsh
```

## Configuration

Set variables in `~/.zshrc` **before loading the plugin**.

| Variable | Default | Description |
|----------|---------|-------------|
| `AICLI_TOOLS` | `(gemini claude copilot codex kiro)` | Tools to check |
| `AICLI_CHECK_INTERVAL` | `7` | Check interval in days |
| `AICLI_AUTO_CHECK` | `true` | Check on shell start |
| `AICLI_NOTIFICATION_STYLE` | `banner` | `banner` or `silent` |
| `AICLI_CACHE_DIR` | `${ZSH_CACHE_DIR:-$HOME/.cache}/ai-cli` | Cache directory |

### Examples

```zsh
# Check only specific tools
AICLI_TOOLS=(gemini claude)

# Check every 3 days
AICLI_CHECK_INTERVAL=3

# Suppress notifications (check manually)
AICLI_NOTIFICATION_STYLE=silent

# Disable automatic checks entirely
AICLI_AUTO_CHECK=false

# Remove one tool from the default list
AICLI_TOOLS=(${AICLI_TOOLS[@]:#codex})
```

## Commands

| Command | Description |
|---------|-------------|
| `ai-cli-check` | Check all configured tools for updates |
| `ai-cli-check <tool>` | Check a specific tool |
| `ai-cli-check --force` | Force check, ignoring cache |
| `ai-cli-upgrade` | Upgrade all tools with available updates |
| `ai-cli-upgrade <tool>` | Upgrade a specific tool |
| `ai-cli-upgrade --confirm` | Upgrade with per-tool confirmation |
| `ai-cli-upgrade --force` | Force check then upgrade |

## Notification Styles

### Banner (default)

A non-interactive box shown when an update is available:

```
╔═══════════════════════════════════════════╗
║ Update Available: gemini                  ║
╟───────────────────────────────────────────╢
║ Current: 0.31.0 → Latest: 0.32.1          ║
║ Update: npm install -g @google/gemini-cli ║
╚═══════════════════════════════════════════╝
```

### Silent

No output. Updates are detected and cached; run `ai-cli-check` to view status.

## License

MIT — see [LICENSE](LICENSE)
