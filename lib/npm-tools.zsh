#!/usr/bin/env zsh

# NPM tool detection and version management

# Tool to npm package mapping
typeset -gA CLI_NPM_PACKAGES
CLI_NPM_PACKAGES=(
  gemini     "@google/gemini-cli"
  claude     "claude-code"
  copilot    "@github/copilot"
  codex      "@openai/codex"
  crush      "@charmland/crush"
)

# Tool to version command mapping
typeset -gA CLI_VERSION_COMMANDS
CLI_VERSION_COMMANDS=(
  gemini     "gemini --version"
  claude     "claude --version"
  copilot    "copilot --version"
  codex      "codex --version"
  crush      "crush --version"
)

# Tool to install command mapping
typeset -gA CLI_INSTALL_COMMANDS
CLI_INSTALL_COMMANDS=(
  gemini     "npm install -g @google/gemini-cli"
  claude     "curl -fsSL https://claude.ai/install.sh | bash"
  copilot    "npm install -g @github/copilot"
  codex      "npm install -g @openai/codex"
)

# Run a shell command with timeout when available.
# Falls back to normal execution if neither timeout nor gtimeout exists.
_aicli_eval_with_timeout() {
  local seconds="$1"
  shift
  local cmd="$*"

  if command -v timeout &>/dev/null; then
    timeout "${seconds}s" zsh -c "$cmd"
    return $?
  fi

  if command -v gtimeout &>/dev/null; then
    gtimeout "${seconds}s" zsh -c "$cmd"
    return $?
  fi

  eval "$cmd"
}

# Check if a tool is installed
_aicli_is_tool_installed() {
  local tool="$1"

  command -v "$tool" &>/dev/null
}

# Get current installed version of a tool
_aicli_get_current_version() {
  local tool="$1"

  # Check if tool is installed
  if ! _aicli_is_tool_installed "$tool"; then
    return 1
  fi

  local version_cmd="${CLI_VERSION_COMMANDS[$tool]}"
  [[ -z "$version_cmd" ]] && return 1

  # Execute version command with timeout
  local output
  output=$(eval "$version_cmd" 2>&1 | head -n 10)

  # Extract version from output
  local version="$(_aicli_extract_version "$output")"

  if [[ -n "$version" ]]; then
    echo "$version"
    return 0
  fi

  return 1
}

# Get latest version from npm registry
_aicli_get_latest_version() {
  local tool="$1"
  local package="${CLI_NPM_PACKAGES[$tool]}"

  [[ -z "$package" ]] && return 1

  # Check if npm is available
  if ! command -v npm &>/dev/null; then
    return 1
  fi

  # Query npm registry with timeout
  # Using npm view instead of npm show for better reliability
  local output
  output=$(_aicli_eval_with_timeout 5 "npm view \"$package\" version" 2>/dev/null)

  if [[ $? -eq 0 && -n "$output" ]]; then
    # npm view returns just the version number
    local version="$(_aicli_extract_version "$output")"
    if [[ -n "$version" ]]; then
      echo "$version"
      return 0
    fi
  fi

  return 1
}

# Check if a tool has an available update
# Returns 0 if update is available, 1 otherwise
# Stores current and latest versions in global variables for caller
_aicli_check_tool_update() {
  local tool="$1"

  # Global variables to store versions and check status metadata
  typeset -g CLI_TOOL_CURRENT CLI_TOOL_LATEST CLI_TOOL_CHECK_STATUS CLI_TOOL_LATEST_SOURCE
  CLI_TOOL_CHECK_STATUS="check-failed"
  CLI_TOOL_LATEST_SOURCE="unknown"

  # Check if tool is in our supported list
  if [[ -z "${CLI_NPM_PACKAGES[$tool]}" ]]; then
    return 1
  fi

  # Check if tool is installed
  if ! _aicli_is_tool_installed "$tool"; then
    return 1
  fi

  # Get current version
  CLI_TOOL_CURRENT="$(_aicli_get_current_version "$tool")"
  if [[ -z "$CLI_TOOL_CURRENT" ]]; then
    return 1
  fi

  # Get latest version from npm
  CLI_TOOL_LATEST="$(_aicli_get_latest_version "$tool")"
  if [[ -z "$CLI_TOOL_LATEST" ]]; then
    # Try to use cached version if available
    if _aicli_get_cached_info "$tool"; then
      CLI_TOOL_LATEST="$CLI_CACHED_LATEST"
      CLI_TOOL_LATEST_SOURCE="cache"
    else
      return 1
    fi
  else
    # Cache the version info
    _aicli_cache_version_info "$tool" "$CLI_TOOL_CURRENT" "$CLI_TOOL_LATEST"
    CLI_TOOL_LATEST_SOURCE="registry"
  fi

  # Compare versions
  if _aicli_update_check_versions "$CLI_TOOL_CURRENT" "$CLI_TOOL_LATEST"; then
    CLI_TOOL_CHECK_STATUS="update-available"
    return 0  # Update available
  fi

  CLI_TOOL_CHECK_STATUS="up-to-date"
  return 1  # No update needed
}

# Get the npm package name for a tool
_aicli_get_package_name() {
  local tool="$1"
  echo "${CLI_NPM_PACKAGES[$tool]}"
}

# Get the install command for a supported tool
_aicli_get_install_command() {
  local tool="$1"

  if _aicli_is_script_tool "$tool"; then
    echo "${SCRIPT_TOOL_INSTALL_COMMANDS[$tool]}"
    return 0
  fi

  if [[ -n "${CLI_INSTALL_COMMANDS[$tool]}" ]]; then
    echo "${CLI_INSTALL_COMMANDS[$tool]}"
    return 0
  fi

  local package="${CLI_NPM_PACKAGES[$tool]}"
  if [[ -n "$package" ]]; then
    echo "npm install -g ${package}"
    return 0
  fi

  return 1
}

# Check if npm is available
_aicli_check_npm_available() {
  if ! command -v npm &>/dev/null; then
    return 1
  fi
  return 0
}
