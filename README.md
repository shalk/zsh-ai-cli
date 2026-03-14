# AI CLI Update Checker - Oh-My-Zsh Plugin

An Oh-My-Zsh plugin that automatically checks for updates to your AI CLI development tools and notifies you when new versions are available.

## Features

- 🔔 **Automatic Update Checks** - Periodically checks for updates without blocking your shell
- 🎯 **Multiple Tool Support** - Supports popular CLI tools like Gemini CLI, Claude Code, GitHub Copilot, and OpenAI Codex
- ⚡ **Smart Caching** - Avoids excessive API calls with configurable check intervals
- 🎨 **Flexible Notifications** - Choose between interactive prompts, banner notifications, or silent mode
- 🛠️ **Easy Configuration** - Simple configuration options in your `.zshrc`
- 📦 **npm Integration** - Seamlessly checks npm registry for latest versions

## Supported Tools

| Tool | npm Package | Command |
|------|-------------|---------|
| Gemini CLI | `@google/gemini-cli` | `gemini` |
| Claude Code | `claude-code` | `claude` |
| GitHub Copilot | `@github/copilot` | `copilot` |
| OpenAI Codex | `@openai/codex` | `codex` |

## Installation

### Prerequisites

- [Oh-My-Zsh](https://ohmyz.sh/) installed
- [npm](https://www.npmjs.com/) installed
- One or more supported CLI tools installed

### Install Plugin

1. Clone this repository to your Oh-My-Zsh custom plugins directory:

```bash
git clone https://github.com/shalk/zsh-ai-cli \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ai-cli
```

2. Add `ai-cli` to your plugins in `~/.zshrc`:

```bash
plugins=(
  # ... other plugins
  ai-cli
)
```

3. Restart your shell or reload configuration:

```bash
source ~/.zshrc
```

## Configuration

All configuration options should be set in your `~/.zshrc` **before** the line that sources Oh-My-Zsh.

### Basic Configuration

```bash
# Which tools to check for updates (default: all supported tools)
AICLI_TOOLS=(gemini claude copilot codex)

# How often to check for updates, in days (default: 7)
AICLI_CHECK_INTERVAL=7

# Enable automatic checking on shell start (default: true)
AICLI_AUTO_CHECK=true

# Notification style: prompt, banner, or silent (default: prompt)
AICLI_NOTIFICATION_STYLE="prompt"

# Cache directory location (default: ZSH cache dir)
AICLI_CACHE_DIR="${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/ai-cli"

# Auto-upgrade confirmation (default: false)
# Set to true to require confirmation before each tool upgrade
AICLI_AUTO_UPGRADE_CONFIRM=false
```

### Configuration Examples

#### Only check specific tools

```bash
# Only check Gemini and Claude
AICLI_TOOLS=(gemini claude)
```

#### Check more frequently

```bash
# Check every 3 days instead of 7
AICLI_CHECK_INTERVAL=3
```

#### Use banner notifications

```bash
# Non-interactive banner instead of prompts
AICLI_NOTIFICATION_STYLE="banner"
```

#### Disable automatic checks

```bash
# Disable automatic checks, only use manual command
AICLI_AUTO_CHECK=false
```

#### Remove a specific tool from checks

```bash
# Remove codex from the default list
AICLI_TOOLS=(${AICLI_TOOLS[@]:#codex})
```

#### Require confirmation for upgrades

```bash
# Always require confirmation before upgrading tools
AICLI_AUTO_UPGRADE_CONFIRM=true
```

## Usage

### Automatic Checks

When `AICLI_AUTO_CHECK=true` (default), the plugin automatically checks for updates based on your configured interval. Updates are checked in the background and won't block your shell prompt.

### Manual Commands

#### Check all configured tools

```bash
ai-cli-check
```

#### Check a specific tool

```bash
ai-cli-check gemini
```

If a supported tool is missing, `ai-cli-check` shows `missing` and prints the recommended install command.

#### Force check (ignore cache)

```bash
ai-cli-check --force
```

#### Show help

```bash
ai-cli-check --help
```

#### Upgrade all configured tools automatically

```bash
ai-cli-upgrade
```

`ai-cli-upgrade` only upgrades tools that are already installed. Missing tools are reported and skipped.

#### Upgrade with confirmation for each tool

```bash
ai-cli-upgrade --confirm
```

#### Upgrade a specific tool

```bash
ai-cli-upgrade gemini
```

#### Upgrade multiple specific tools

```bash
ai-cli-upgrade claude gemini
```

#### Force check and upgrade (ignore cache)

```bash
ai-cli-upgrade --force
```

#### Show upgrade help

```bash
ai-cli-upgrade --help
```

## Notification Styles

### Prompt Mode (Default)

Interactive prompt that asks if you want to update now:

```
Update available for gemini CLI!
  Current: 0.31.0
  Latest:  0.32.1

Update now? [y/N/d(isable)]
```

Options:
- `y` - Install update immediately using npm
- `N` - Skip this time, check again later
- `d` - Show instructions to disable checks for this tool

### Banner Mode

Non-interactive notification with update command:

```
╔═══════════════════════════════════════════╗
║ Update Available: gemini                  ║
╟───────────────────────────────────────────╢
║ Current: 0.31.0 → Latest: 0.32.1          ║
║ Update: npm install -g @google/gemini-cli ║
╚═══════════════════════════════════════════╝
```

### Silent Mode

No notifications displayed. Updates are detected and cached, but you need to run `ai-cli-check` manually to see them.

## How It Works

1. **Periodic Checks** - The plugin hooks into your shell's `precmd` to check for updates periodically
2. **Version Detection** - Runs version commands for installed tools to get current versions
3. **npm Registry Query** - Queries npm registry to get latest published versions
4. **Smart Caching** - Caches results to avoid excessive API calls
5. **User Notification** - Displays updates based on your notification style preference

## Cache Management

The plugin caches version information to avoid excessive npm registry queries:

- Cache location: `${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/ai-cli`
- Cache duration: Configurable via `AICLI_CHECK_INTERVAL` (default: 7 days)
- Force refresh: Use `ai-cli-check --force` to ignore cache

Cache files:
- `last_check.cache` - Timestamp of last check
- `{tool}.cache` - Version information for each tool

## Troubleshooting

### Plugin not loading

Make sure npm is installed:
```bash
npm --version
```

The plugin silently disables itself if npm is not available.

### No updates shown

Check if tools are installed:
```bash
gemini --version
claude --version
copilot --version
codex --version
```

The plugin only checks installed tools.

If you run `ai-cli-check` for a supported tool that is not installed, the plugin reports it as `missing` and shows the install command instead of silently skipping it.

### Force a fresh check

Clear the cache and check again:
```bash
rm -rf ${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/ai-cli
ai-cli-check --force
```

### Check plugin configuration

Verify your configuration:
```bash
echo $AICLI_TOOLS
echo $AICLI_CHECK_INTERVAL
echo $AICLI_NOTIFICATION_STYLE
```

## Performance

The plugin is designed to be lightweight:

- Checks run in background (won't block your prompt)
- Results are cached to minimize API calls
- Only checks tools that are actually installed
- Automatic background checks still silently skip unavailable tools

## Contributing

Contributions are welcome! To add support for a new CLI tool:

1. Add the tool to `CLI_NPM_PACKAGES` in `lib/npm-tools.zsh`
2. Add the version command to `CLI_VERSION_COMMANDS`
3. Test the version detection and update flow
4. Update the README with the new tool

## License

MIT License - see [LICENSE](LICENSE) file for details

## Author

Created by [shalk](https://github.com/shalk)

## Acknowledgments

- Inspired by the need to keep multiple CLI dev tools up-to-date
- Built for the Oh-My-Zsh community
- Thanks to all contributors and users

## Related Projects

- [Oh-My-Zsh](https://ohmyz.sh/) - Framework for managing Zsh configuration
- [Gemini CLI](https://www.npmjs.com/package/@google/gemini-cli) - Google's Gemini CLI
- [Claude Code](https://www.npmjs.com/package/claude-code) - Anthropic's Claude CLI

## Support

- Report issues: [GitHub Issues](https://github.com/shalk/zsh-ai-cli/issues)
- Feature requests: [GitHub Discussions](https://github.com/shalk/zsh-ai-cli/discussions)

---

**Happy coding! 🚀**
