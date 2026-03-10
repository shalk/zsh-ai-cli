#!/usr/bin/env zsh

# Oh-My-Zsh AI CLI Update Checker Plugin
# Automatically checks for updates to AI CLI development tools

# Plugin configuration - users can override these in .zshrc before loading plugins

# Tools to check for updates (gemini, claude, copilot, codex)
if [[ -z "${AICLI_TOOLS[@]}" ]]; then
  AICLI_TOOLS=(gemini claude copilot codex)
fi

# Check interval in days
: ${AICLI_CHECK_INTERVAL:=7}

# Enable automatic checking on shell start
: ${AICLI_AUTO_CHECK:=true}

# Notification style: prompt, banner, or silent
: ${AICLI_NOTIFICATION_STYLE:=prompt}

# Cache directory location
: ${AICLI_CACHE_DIR:=${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/ai-cli}

# Auto-upgrade confirmation (set to true to require confirmation before upgrades)
: ${AICLI_AUTO_UPGRADE_CONFIRM:=false}

# Check if npm is available
if ! command -v npm &>/dev/null; then
  # Silently disable plugin if npm is not available
  # Users who need npm will have it installed
  return 0
fi

# Get the directory where this plugin is located
AICLI_PLUGIN_DIR="${0:A:h}"

# Source library files
source "${AICLI_PLUGIN_DIR}/lib/cache.zsh"
source "${AICLI_PLUGIN_DIR}/lib/version-checker.zsh"
source "${AICLI_PLUGIN_DIR}/lib/npm-tools.zsh"
source "${AICLI_PLUGIN_DIR}/lib/ui.zsh"

# Background check hook for precmd
_aicli_update_check_hook() {
  # Only run in interactive shells
  [[ -o interactive ]] || return

  # Skip if auto-check is disabled
  [[ "${AICLI_AUTO_CHECK}" != "true" ]] && return

  # Skip if we shouldn't check based on interval
  _aicli_should_check_updates || return

  # Run checks in background to avoid blocking prompt
  {
    local any_updates=false

    for tool in "${AICLI_TOOLS[@]}"; do
      # Skip if tool is not installed (silently)
      if ! _aicli_is_tool_installed "$tool"; then
        continue
      fi

      # Check for updates
      if _aicli_check_tool_update "$tool"; then
        any_updates=true
        _aicli_show_update_notification "$tool" "$CLI_TOOL_CURRENT" "$CLI_TOOL_LATEST"
      fi
    done

    # Update last check timestamp
    _aicli_update_last_check
  } &!
}

# Manual check command
ai-cli-check() {
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
        echo "Usage: ai-cli-check [OPTIONS] [TOOL]"
        echo ""
        echo "Check for AI CLI tool updates"
        echo ""
        echo "Options:"
        echo "  --force, -f     Force check, ignore cache"
        echo "  --help, -h      Show this help message"
        echo ""
        echo "Tools: gemini, claude, copilot, codex"
        echo ""
        echo "Examples:"
        echo "  ai-cli-check              # Check all configured tools"
        echo "  ai-cli-check gemini       # Check only gemini"
        echo "  ai-cli-check --force      # Force check all tools"
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
    _aicli_clear_cache
  fi

  # Check if npm is available
  if ! _aicli_check_npm_available; then
    _aicli_show_status "Error: npm is required for AI CLI update checks" "error"
    return 1
  fi

  # Check specific tool or all tools
  if [[ -n "$specific_tool" ]]; then
    # Validate tool
    if [[ -z "${CLI_NPM_PACKAGES[$specific_tool]}" ]]; then
      _aicli_show_status "Error: Unknown tool '$specific_tool'" "error"
      echo "Available tools: ${(k)CLI_NPM_PACKAGES[@]}"
      return 1
    fi

    # Check if tool is installed
    if ! _aicli_is_tool_installed "$specific_tool"; then
      _aicli_show_status "Tool '$specific_tool' is not installed" "warning"
      return 1
    fi

    # Check for update
    if _aicli_check_tool_update "$specific_tool"; then
      _aicli_show_update_notification "$specific_tool" "$CLI_TOOL_CURRENT" "$CLI_TOOL_LATEST"
    else
      local current="$(_aicli_get_current_version "$specific_tool")"
      if [[ -n "$current" ]]; then
        echo ""
        _aicli_show_status "${specific_tool}: ${current} (up-to-date)" "success"
        echo ""
      else
        _aicli_show_status "Could not determine version for ${specific_tool}" "error"
      fi
    fi
  else
    # Check all configured tools
    _aicli_show_summary "${AICLI_TOOLS[@]}"
  fi

  # Update last check timestamp
  _aicli_update_last_check
}

# Upgrade command
ai-cli-upgrade() {
  # Parse flags
  local require_confirm=${AICLI_AUTO_UPGRADE_CONFIRM:-false}
  local specific_tools=()
  local force=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --confirm|-c)
        require_confirm=true
        shift
        ;;
      --force|-f)
        force=true
        shift
        ;;
      --help|-h)
        echo "Usage: ai-cli-upgrade [OPTIONS] [TOOL...]"
        echo ""
        echo "Upgrade AI CLI tools with available updates"
        echo ""
        echo "Options:"
        echo "  --confirm, -c   Require confirmation for each tool upgrade"
        echo "  --force, -f     Force check, ignore cache"
        echo "  --help, -h      Show this help message"
        echo ""
        echo "Tools: gemini, claude, copilot, codex"
        echo ""
        echo "Examples:"
        echo "  ai-cli-upgrade              # Upgrade all tools automatically"
        echo "  ai-cli-upgrade --confirm    # Upgrade with confirmation"
        echo "  ai-cli-upgrade gemini       # Upgrade only gemini"
        echo "  ai-cli-upgrade claude gemini # Upgrade multiple tools"
        echo "  ai-cli-upgrade --force      # Force check and upgrade"
        return 0
        ;;
      *)
        specific_tools+=("$1")
        shift
        ;;
    esac
  done

  # Check npm availability
  if ! _aicli_check_npm_available; then
    _aicli_show_status "Error: npm is required for upgrades" "error"
    return 1
  fi

  # Determine which tools to check
  local tools_to_check=("${specific_tools[@]}")
  if [[ ${#tools_to_check[@]} -eq 0 ]]; then
    tools_to_check=("${AICLI_TOOLS[@]}")
  fi

  # Force check by clearing cache if requested
  if [[ "$force" == "true" ]]; then
    _aicli_clear_cache
  fi

  # Find tools with available updates
  local tools_to_upgrade=()

  for tool in "${tools_to_check[@]}"; do
    # Skip if tool not installed
    if ! _aicli_is_tool_installed "$tool"; then
      continue
    fi

    # Check for updates
    if _aicli_check_tool_update "$tool"; then
      tools_to_upgrade+=("$tool:${CLI_TOOL_CURRENT}:${CLI_TOOL_LATEST}")
    fi
  done

  # If no updates available
  if [[ ${#tools_to_upgrade[@]} -eq 0 ]]; then
    echo ""
    _aicli_show_status "All tools are up-to-date!" "success"
    echo ""
    return 0
  fi

  # Show what will be upgraded
  echo ""
  echo -e "${CLI_COLOR_CYAN}Found ${#tools_to_upgrade[@]} update(s) available:${CLI_COLOR_RESET}"
  echo ""

  for update_info in "${tools_to_upgrade[@]}"; do
    local tool="${update_info%%:*}"
    local rest="${update_info#*:}"
    local current="${rest%%:*}"
    local latest="${rest##*:}"
    echo -e "  ${CLI_COLOR_YELLOW}${tool}${CLI_COLOR_RESET}: ${CLI_COLOR_RED}${current}${CLI_COLOR_RESET} → ${CLI_COLOR_GREEN}${latest}${CLI_COLOR_RESET}"
  done
  echo ""

  # Upgrade each tool
  for update_info in "${tools_to_upgrade[@]}"; do
    local tool="${update_info%%:*}"
    local rest="${update_info#*:}"
    local current="${rest%%:*}"
    local latest="${rest##*:}"
    local package="$(_aicli_get_package_name "$tool")"

    # Ask for confirmation if required
    if [[ "$require_confirm" == "true" ]]; then
      echo -n "Upgrade ${tool} from ${current} to ${latest}? [Y/n] "
      read -r response

      case "$response" in
        n|N|no|No|NO)
          echo "Skipped ${tool}"
          echo ""
          continue
          ;;
      esac
    fi

    # Run the upgrade
    _aicli_run_update "$tool" "$package"
  done

  # Update last check timestamp
  _aicli_update_last_check
}

# Register the precmd hook
autoload -Uz add-zsh-hook
add-zsh-hook precmd _aicli_update_check_hook

# Export manual check command
# (zsh automatically makes functions available, but we document it here)
# Commands available:
#   ai-cli-check        - Manual check for updates
#   ai-cli-upgrade      - Upgrade tools with available updates
