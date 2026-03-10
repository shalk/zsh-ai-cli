#!/usr/bin/env zsh

# Oh-My-Zsh CLI Update Checker Plugin
# Automatically checks for updates to CLI development tools

# Plugin configuration - users can override these in .zshrc before loading plugins

# Tools to check for updates (gemini, claude, copilot, codex)
if [[ -z "${CLI_UPDATE_TOOLS[@]}" ]]; then
  CLI_UPDATE_TOOLS=(gemini claude copilot codex)
fi

# Check interval in days
: ${CLI_UPDATE_CHECK_INTERVAL:=7}

# Enable automatic checking on shell start
: ${CLI_UPDATE_AUTO_CHECK:=true}

# Notification style: prompt, banner, or silent
: ${CLI_UPDATE_NOTIFICATION_STYLE:=prompt}

# Cache directory location
: ${CLI_UPDATE_CACHE_DIR:=${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/cli-update}

# Check if npm is available
if ! command -v npm &>/dev/null; then
  # Silently disable plugin if npm is not available
  # Users who need npm will have it installed
  return 0
fi

# Get the directory where this plugin is located
CLI_UPDATE_PLUGIN_DIR="${0:A:h}"

# Source library files
source "${CLI_UPDATE_PLUGIN_DIR}/lib/cache.zsh"
source "${CLI_UPDATE_PLUGIN_DIR}/lib/version-checker.zsh"
source "${CLI_UPDATE_PLUGIN_DIR}/lib/npm-tools.zsh"
source "${CLI_UPDATE_PLUGIN_DIR}/lib/ui.zsh"

# Background check hook for precmd
_cli_update_check_hook() {
  # Only run in interactive shells
  [[ -o interactive ]] || return

  # Skip if auto-check is disabled
  [[ "${CLI_UPDATE_AUTO_CHECK}" != "true" ]] && return

  # Skip if we shouldn't check based on interval
  _cli_should_check_updates || return

  # Run checks in background to avoid blocking prompt
  {
    local any_updates=false

    for tool in "${CLI_UPDATE_TOOLS[@]}"; do
      # Skip if tool is not installed (silently)
      if ! _cli_is_tool_installed "$tool"; then
        continue
      fi

      # Check for updates
      if _cli_check_tool_update "$tool"; then
        any_updates=true
        _cli_show_update_notification "$tool" "$CLI_TOOL_CURRENT" "$CLI_TOOL_LATEST"
      fi
    done

    # Update last check timestamp
    _cli_update_last_check
  } &!
}

# Manual check command
cli-update-check() {
  local force=false
  local specific_tool=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force|-f)
        force=true
        shift
        ;;
      --help|-h)
        echo "Usage: cli-update-check [OPTIONS] [TOOL]"
        echo ""
        echo "Check for CLI tool updates"
        echo ""
        echo "Options:"
        echo "  --force, -f     Force check, ignore cache"
        echo "  --help, -h      Show this help message"
        echo ""
        echo "Tools: gemini, claude, copilot, codex"
        echo ""
        echo "Examples:"
        echo "  cli-update-check              # Check all configured tools"
        echo "  cli-update-check gemini       # Check only gemini"
        echo "  cli-update-check --force      # Force check all tools"
        return 0
        ;;
      *)
        specific_tool="$1"
        shift
        ;;
    esac
  done

  # Force check by clearing cache
  if [[ "$force" == "true" ]]; then
    _cli_clear_cache
  fi

  # Check if npm is available
  if ! _cli_check_npm_available; then
    _cli_show_status "Error: npm is required for CLI update checks" "error"
    return 1
  fi

  # Check specific tool or all tools
  if [[ -n "$specific_tool" ]]; then
    # Validate tool
    if [[ -z "${CLI_NPM_PACKAGES[$specific_tool]}" ]]; then
      _cli_show_status "Error: Unknown tool '$specific_tool'" "error"
      echo "Available tools: ${(k)CLI_NPM_PACKAGES[@]}"
      return 1
    fi

    # Check if tool is installed
    if ! _cli_is_tool_installed "$specific_tool"; then
      _cli_show_status "Tool '$specific_tool' is not installed" "warning"
      return 1
    fi

    # Check for update
    if _cli_check_tool_update "$specific_tool"; then
      _cli_show_update_notification "$specific_tool" "$CLI_TOOL_CURRENT" "$CLI_TOOL_LATEST"
    else
      local current="$(_cli_get_current_version "$specific_tool")"
      if [[ -n "$current" ]]; then
        echo ""
        _cli_show_status "${specific_tool}: ${current} (up-to-date)" "success"
        echo ""
      else
        _cli_show_status "Could not determine version for ${specific_tool}" "error"
      fi
    fi
  else
    # Check all configured tools
    _cli_show_summary "${CLI_UPDATE_TOOLS[@]}"
  fi

  # Update last check timestamp
  _cli_update_last_check
}

# Register the precmd hook
autoload -Uz add-zsh-hook
add-zsh-hook precmd _cli_update_check_hook

# Export manual check command
# (zsh automatically makes functions available, but we document it here)
# Commands available:
#   cli-update-check        - Manual check for updates
