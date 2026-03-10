# CLI Update Checker - Oh-My-Zsh Plugin

An Oh-My-Zsh plugin that automatically checks for updates to your CLI development tools and notifies you when new versions are available.

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
| GitHub Copilot | `@github/copilot` | `gh copilot` |
| OpenAI Codex | `@openai/codex` | `codex` |

## Installation

### Prerequisites

- [Oh-My-Zsh](https://ohmyz.sh/) installed
- [npm](https://www.npmjs.com/) installed
- One or more supported CLI tools installed

### Install Plugin

1. Clone this repository to your Oh-My-Zsh custom plugins directory:

```bash
git clone https://github.com/shalk/cli-update \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/cli-update
```

2. Add `cli-update` to your plugins in `~/.zshrc`:

```bash
plugins=(
  # ... other plugins
  cli-update
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
CLI_UPDATE_TOOLS=(gemini claude copilot codex)

# How often to check for updates, in days (default: 7)
CLI_UPDATE_CHECK_INTERVAL=7

# Enable automatic checking on shell start (default: true)
CLI_UPDATE_AUTO_CHECK=true

# Notification style: prompt, banner, or silent (default: prompt)
CLI_UPDATE_NOTIFICATION_STYLE="prompt"

# Cache directory location (default: ZSH cache dir)
CLI_UPDATE_CACHE_DIR="${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/cli-update"
```

### Configuration Examples

#### Only check specific tools

```bash
# Only check Gemini and Claude
CLI_UPDATE_TOOLS=(gemini claude)
```

#### Check more frequently

```bash
# Check every 3 days instead of 7
CLI_UPDATE_CHECK_INTERVAL=3
```

#### Use banner notifications

```bash
# Non-interactive banner instead of prompts
CLI_UPDATE_NOTIFICATION_STYLE="banner"
```

#### Disable automatic checks

```bash
# Disable automatic checks, only use manual command
CLI_UPDATE_AUTO_CHECK=false
```

#### Remove a specific tool from checks

```bash
# Remove codex from the default list
CLI_UPDATE_TOOLS=(${CLI_UPDATE_TOOLS[@]:#codex})
```

## Usage

### Automatic Checks

When `CLI_UPDATE_AUTO_CHECK=true` (default), the plugin automatically checks for updates based on your configured interval. Updates are checked in the background and won't block your shell prompt.

### Manual Commands

#### Check all configured tools

```bash
cli-update-check
```

#### Check a specific tool

```bash
cli-update-check gemini
```

#### Force check (ignore cache)

```bash
cli-update-check --force
```

#### Show help

```bash
cli-update-check --help
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

No notifications displayed. Updates are detected and cached, but you need to run `cli-update-check` manually to see them.

## How It Works

1. **Periodic Checks** - The plugin hooks into your shell's `precmd` to check for updates periodically
2. **Version Detection** - Runs version commands for installed tools to get current versions
3. **npm Registry Query** - Queries npm registry to get latest published versions
4. **Smart Caching** - Caches results to avoid excessive API calls
5. **User Notification** - Displays updates based on your notification style preference

## Cache Management

The plugin caches version information to avoid excessive npm registry queries:

- Cache location: `${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/cli-update`
- Cache duration: Configurable via `CLI_UPDATE_CHECK_INTERVAL` (default: 7 days)
- Force refresh: Use `cli-update-check --force` to ignore cache

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
gh copilot --version
codex --version
```

The plugin only checks installed tools.

### Force a fresh check

Clear the cache and check again:
```bash
rm -rf ${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/cli-update
cli-update-check --force
```

### Check plugin configuration

Verify your configuration:
```bash
echo $CLI_UPDATE_TOOLS
echo $CLI_UPDATE_CHECK_INTERVAL
echo $CLI_UPDATE_NOTIFICATION_STYLE
```

## Performance

The plugin is designed to be lightweight:

- Checks run in background (won't block your prompt)
- Results are cached to minimize API calls
- Only checks tools that are actually installed
- Silently skips unavailable tools

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

- Report issues: [GitHub Issues](https://github.com/shalk/cli-update/issues)
- Feature requests: [GitHub Discussions](https://github.com/shalk/cli-update/discussions)

---

**Happy coding! 🚀**
