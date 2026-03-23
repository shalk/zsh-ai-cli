#!/usr/bin/env zsh

# Script-based (non-npm) tool detection and version management

# Tool to version command mapping
typeset -gA SCRIPT_TOOL_VERSION_COMMANDS
SCRIPT_TOOL_VERSION_COMMANDS=(
  kiro    "kiro-cli --version"
  claude  "claude --version"
)

# Tool to upgrade command mapping
typeset -gA SCRIPT_TOOL_UPGRADE_COMMANDS
SCRIPT_TOOL_UPGRADE_COMMANDS=(
  kiro    "kiro-cli update"
  claude  "claude update"
)

# Tool to install command mapping
typeset -gA SCRIPT_TOOL_INSTALL_COMMANDS
SCRIPT_TOOL_INSTALL_COMMANDS=(
  kiro    "curl -fsSL https://cli.kiro.dev/install | bash"
  claude  "curl -fsSL https://claude.ai/install.sh | bash"
)

# Tool to latest-version command mapping
typeset -gA SCRIPT_TOOL_LATEST_VERSION_CMDS
SCRIPT_TOOL_LATEST_VERSION_CMDS=(
  kiro    "curl -s https://desktop-release.q.us-east-1.amazonaws.com/latest/manifest.json | jq -r '.version'"
  claude  "curl -s https://api.github.com/repos/anthropics/claude-code/releases/latest | jq -r '.tag_name'"
)

# Check if a tool is a script tool (non-npm)
_aicli_is_script_tool() {
  local tool="$1"
  [[ -n "${SCRIPT_TOOL_VERSION_COMMANDS[$tool]}" ]]
}

# Check if a script tool's binary is installed
_aicli_is_script_tool_installed() {
  local tool="$1"
  # Derive binary name: kiro -> kiro-cli
  local bin
  case "$tool" in
    kiro) bin="kiro-cli" ;;
    *)    bin="$tool" ;;
  esac
  command -v "$bin" &>/dev/null
}

# Get current installed version of a script tool
_aicli_get_script_current_version() {
  local tool="$1"

  if ! _aicli_is_script_tool_installed "$tool"; then
    return 1
  fi

  local version_cmd="${SCRIPT_TOOL_VERSION_COMMANDS[$tool]}"
  [[ -z "$version_cmd" ]] && return 1

  local output
  output=$(eval "$version_cmd" 2>&1 | head -n 10)

  local version="$(_aicli_extract_version "$output")"
  if [[ -n "$version" ]]; then
    echo "$version"
    return 0
  fi

  return 1
}

# Get latest available version of a script tool
# Falls back to grep/cut if jq is not available
_aicli_get_script_latest_version() {
  local tool="$1"

  local latest_cmd="${SCRIPT_TOOL_LATEST_VERSION_CMDS[$tool]}"
  [[ -z "$latest_cmd" ]] && return 1

  local output
  if command -v jq &>/dev/null; then
    output=$(_aicli_eval_with_timeout 5 "$latest_cmd" 2>/dev/null)
  else
    # Fallback: fetch raw JSON and extract version with grep/cut
    local url field
    case "$tool" in
      kiro)   url="https://desktop-release.q.us-east-1.amazonaws.com/latest/manifest.json"
              field="version" ;;
      claude) url="https://api.github.com/repos/anthropics/claude-code/releases/latest"
              field="tag_name" ;;
      *)      return 1 ;;
    esac
    local raw_json
    raw_json=$(_aicli_eval_with_timeout 5 "curl -s \"$url\"" 2>/dev/null)
    output=$(echo "$raw_json" | grep -o "\"${field}\":\"[^\"]*\"" | cut -d'"' -f4)
  fi

  if [[ -n "$output" ]]; then
    local version="$(_aicli_extract_version "$output")"
    if [[ -n "$version" ]]; then
      echo "$version"
      return 0
    fi
  fi

  return 1
}

# Check if a script tool has an available update
# Returns 0 if update is available, 1 otherwise
# Stores current and latest versions in CLI_TOOL_CURRENT / CLI_TOOL_LATEST
_aicli_check_script_tool_update() {
  local tool="$1"

  typeset -g CLI_TOOL_CURRENT CLI_TOOL_LATEST CLI_TOOL_CHECK_STATUS CLI_TOOL_LATEST_SOURCE
  CLI_TOOL_CHECK_STATUS="check-failed"
  CLI_TOOL_LATEST_SOURCE="unknown"

  if ! _aicli_is_script_tool "$tool"; then
    return 1
  fi

  if ! _aicli_is_script_tool_installed "$tool"; then
    return 1
  fi

  CLI_TOOL_CURRENT="$(_aicli_get_script_current_version "$tool")"
  if [[ -z "$CLI_TOOL_CURRENT" ]]; then
    return 1
  fi

  CLI_TOOL_LATEST="$(_aicli_get_script_latest_version "$tool")"
  if [[ -z "$CLI_TOOL_LATEST" ]]; then
    if _aicli_get_cached_info "$tool"; then
      CLI_TOOL_LATEST="$CLI_CACHED_LATEST"
      CLI_TOOL_LATEST_SOURCE="cache"
    else
      return 1
    fi
  else
    _aicli_cache_version_info "$tool" "$CLI_TOOL_CURRENT" "$CLI_TOOL_LATEST"
    CLI_TOOL_LATEST_SOURCE="remote"
  fi

  if _aicli_update_check_versions "$CLI_TOOL_CURRENT" "$CLI_TOOL_LATEST"; then
    CLI_TOOL_CHECK_STATUS="update-available"
    return 0
  fi

  CLI_TOOL_CHECK_STATUS="up-to-date"
  return 1
}

# Execute the upgrade command for a script tool
_aicli_upgrade_script_tool() {
  local tool="$1"
  local upgrade_cmd="${SCRIPT_TOOL_UPGRADE_COMMANDS[$tool]}"

  if [[ -z "$upgrade_cmd" ]]; then
    echo -e "${CLI_COLOR_RED}No upgrade command defined for ${tool}${CLI_COLOR_RESET}"
    return 1
  fi

  echo ""
  echo -e "${CLI_COLOR_CYAN}Updating ${tool}...${CLI_COLOR_RESET}"
  echo ""

  if eval "$upgrade_cmd"; then
    echo ""
    echo -e "${CLI_COLOR_GREEN}✓ Successfully updated ${tool}!${CLI_COLOR_RESET}"

    local new_version="$(_aicli_get_script_current_version "$tool")"
    if [[ -n "$new_version" ]]; then
      echo -e "${CLI_COLOR_GREEN}  New version: ${new_version}${CLI_COLOR_RESET}"
    fi
    echo ""
  else
    echo ""
    echo -e "${CLI_COLOR_RED}✗ Failed to update ${tool}${CLI_COLOR_RESET}"
    echo -e "${CLI_COLOR_YELLOW}  You can try manually: ${upgrade_cmd}${CLI_COLOR_RESET}"
    echo ""
  fi
}
