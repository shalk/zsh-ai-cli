#!/usr/bin/env zsh

# User interface for AI CLI update notifications

# ANSI color codes (only used if terminal supports colors)
_aicli_setup_colors() {
  if [[ -t 1 ]] && [[ "${TERM}" != "dumb" ]]; then
    typeset -g CLI_COLOR_RESET='\033[0m'
    typeset -g CLI_COLOR_YELLOW='\033[1;33m'
    typeset -g CLI_COLOR_GREEN='\033[1;32m'
    typeset -g CLI_COLOR_CYAN='\033[1;36m'
    typeset -g CLI_COLOR_BLUE='\033[1;34m'
    typeset -g CLI_COLOR_RED='\033[1;31m'
  else
    typeset -g CLI_COLOR_RESET=''
    typeset -g CLI_COLOR_YELLOW=''
    typeset -g CLI_COLOR_GREEN=''
    typeset -g CLI_COLOR_CYAN=''
    typeset -g CLI_COLOR_BLUE=''
    typeset -g CLI_COLOR_RED=''
  fi
}

_aicli_setup_colors

_aicli_show_missing_tool() {
  local tool="$1"
  local install_cmd="$(_aicli_get_install_command "$tool")"

  _aicli_show_status "${tool}: missing" "warning"

  if [[ -n "$install_cmd" ]]; then
    echo -e "  ${CLI_COLOR_CYAN}Install:${CLI_COLOR_RESET} ${install_cmd}"
  else
    echo -e "  ${CLI_COLOR_CYAN}Install:${CLI_COLOR_RESET} Install ${tool} manually, then rerun ai-cli-check ${tool}"
  fi
}

# Show update notification based on configured style
_aicli_show_update_notification() {
  local tool="$1"
  local current="$2"
  local latest="$3"

  local style="${AICLI_NOTIFICATION_STYLE:-prompt}"

  # If stdin is not available (background process) and style is interactive,
  # fall back to non-interactive banner mode
  if [[ ! -t 0 ]] && [[ "$style" == "prompt" ]]; then
    style="banner"
  fi

  case "$style" in
    prompt)
      _aicli_prompt_update "$tool" "$current" "$latest"
      ;;
    banner)
      _aicli_banner_update "$tool" "$current" "$latest"
      ;;
    silent)
      # Just cache, no output
      ;;
    *)
      _aicli_banner_update "$tool" "$current" "$latest"
      ;;
  esac
}

# Interactive prompt mode
_aicli_prompt_update() {
  local tool="$1"
  local current="$2"
  local latest="$3"
  local package
  local update_cmd
  if _aicli_is_script_tool "$tool"; then
    update_cmd="${SCRIPT_TOOL_UPGRADE_COMMANDS[$tool]}"
  else
    package="$(_aicli_get_package_name "$tool")"
    update_cmd="npm install -g ${package}"
  fi

  echo ""
  echo -e "${CLI_COLOR_YELLOW}Update available for ${tool} CLI!${CLI_COLOR_RESET}"
  echo -e "  Current: ${CLI_COLOR_RED}${current}${CLI_COLOR_RESET}"
  echo -e "  Latest:  ${CLI_COLOR_GREEN}${latest}${CLI_COLOR_RESET}"
  echo ""
  echo -n "Update now? [y/N/d(isable)] "

  # Read user input
  read -r response

  case "$response" in
    y|Y|yes|Yes|YES)
      if _aicli_is_script_tool "$tool"; then
        _aicli_upgrade_script_tool "$tool"
      else
        _aicli_run_update "$tool" "$package"
      fi
      ;;
    d|D|disable|Disable|DISABLE)
      echo ""
      echo -e "${CLI_COLOR_CYAN}To disable update checks for ${tool}, add this to your .zshrc:${CLI_COLOR_RESET}"
      echo ""
      echo "  AICLI_TOOLS=(\${AICLI_TOOLS[@]:#${tool}})"
      echo ""
      echo -e "${CLI_COLOR_CYAN}Or to disable all automatic checks:${CLI_COLOR_RESET}"
      echo ""
      echo "  AICLI_AUTO_CHECK=false"
      echo ""
      ;;
    *)
      echo "Skipped. Run 'ai-cli-check ${tool}' to check again."
      ;;
  esac
}

# Banner mode (non-interactive)
_aicli_banner_update() {
  local tool="$1"
  local current="$2"
  local latest="$3"
  local update_cmd
  if _aicli_is_script_tool "$tool"; then
    update_cmd="${SCRIPT_TOOL_UPGRADE_COMMANDS[$tool]}"
  else
    local package="$(_aicli_get_package_name "$tool")"
    update_cmd="npm install -g ${package}"
  fi

  local width=45
  local title="Update Available: ${tool}"
  local version_line="Current: ${current} → Latest: ${latest}"

  echo ""
  echo -e "${CLI_COLOR_YELLOW}╔$(printf '═%.0s' {1..43})╗${CLI_COLOR_RESET}"
  echo -e "${CLI_COLOR_YELLOW}║${CLI_COLOR_RESET} ${CLI_COLOR_CYAN}${title}$(printf ' %.0s' {1..$((41 - ${#title}))})${CLI_COLOR_RESET} ${CLI_COLOR_YELLOW}║${CLI_COLOR_RESET}"
  echo -e "${CLI_COLOR_YELLOW}╟$(printf '─%.0s' {1..43})╢${CLI_COLOR_RESET}"
  echo -e "${CLI_COLOR_YELLOW}║${CLI_COLOR_RESET} ${version_line}$(printf ' %.0s' {1..$((41 - ${#version_line}))}) ${CLI_COLOR_YELLOW}║${CLI_COLOR_RESET}"
  echo -e "${CLI_COLOR_YELLOW}║${CLI_COLOR_RESET} ${CLI_COLOR_GREEN}Update:${CLI_COLOR_RESET} ${update_cmd}$(printf ' %.0s' {1..$((34 - ${#update_cmd}))}) ${CLI_COLOR_YELLOW}║${CLI_COLOR_RESET}"
  echo -e "${CLI_COLOR_YELLOW}╚$(printf '═%.0s' {1..43})╝${CLI_COLOR_RESET}"
  echo ""
}

# Execute npm update
_aicli_run_update() {
  local tool="$1"
  local package="$2"

  echo ""
  echo -e "${CLI_COLOR_CYAN}Updating ${tool}...${CLI_COLOR_RESET}"
  echo ""

  if npm install -g "$package"; then
    echo ""
    echo -e "${CLI_COLOR_GREEN}✓ Successfully updated ${tool}!${CLI_COLOR_RESET}"

    # Get new version
    local new_version="$(_aicli_get_current_version "$tool")"
    if [[ -n "$new_version" ]]; then
      echo -e "${CLI_COLOR_GREEN}  New version: ${new_version}${CLI_COLOR_RESET}"
    fi
    echo ""
  else
    echo ""
    echo -e "${CLI_COLOR_RED}✗ Failed to update ${tool}${CLI_COLOR_RESET}"
    echo -e "${CLI_COLOR_YELLOW}  You can try manually: npm install -g ${package}${CLI_COLOR_RESET}"
    echo ""
  fi
}

# Show summary of all updates
_aicli_show_summary() {
  local tools=("$@")
  local updates_available=()
  local missing_tools=()

  echo ""
  echo -e "${CLI_COLOR_CYAN}Checking for updates...${CLI_COLOR_RESET}"
  echo ""

  for tool in "${tools[@]}"; do
    if _aicli_is_script_tool "$tool"; then
      if ! _aicli_is_script_tool_installed "$tool"; then
        missing_tools+=("$tool")
        _aicli_show_missing_tool "$tool"
        continue
      fi
      if _aicli_check_script_tool_update "$tool"; then
        updates_available+=("$tool:${CLI_TOOL_CURRENT}:${CLI_TOOL_LATEST}")
        echo -e "  ${CLI_COLOR_YELLOW}${tool}${CLI_COLOR_RESET}: ${CLI_COLOR_RED}${CLI_TOOL_CURRENT}${CLI_COLOR_RESET} → ${CLI_COLOR_GREEN}${CLI_TOOL_LATEST}${CLI_COLOR_RESET}"
      else
        local current="$(_aicli_get_script_current_version "$tool")"
        if [[ -n "$current" ]]; then
          echo -e "  ${CLI_COLOR_GREEN}${tool}${CLI_COLOR_RESET}: ${current} (up-to-date)"
        fi
      fi
    else
      if ! _aicli_is_tool_installed "$tool"; then
        missing_tools+=("$tool")
        _aicli_show_missing_tool "$tool"
        continue
      fi
      if _aicli_check_tool_update "$tool"; then
        updates_available+=("$tool:${CLI_TOOL_CURRENT}:${CLI_TOOL_LATEST}")
        echo -e "  ${CLI_COLOR_YELLOW}${tool}${CLI_COLOR_RESET}: ${CLI_COLOR_RED}${CLI_TOOL_CURRENT}${CLI_COLOR_RESET} → ${CLI_COLOR_GREEN}${CLI_TOOL_LATEST}${CLI_COLOR_RESET}"
      else
        local current="$(_aicli_get_current_version "$tool")"
        if [[ -n "$current" ]]; then
          echo -e "  ${CLI_COLOR_GREEN}${tool}${CLI_COLOR_RESET}: ${current} (up-to-date)"
        fi
      fi
    fi
  done

  if [[ ${#updates_available[@]} -eq 0 ]] && [[ ${#missing_tools[@]} -eq 0 ]]; then
    echo ""
    echo -e "${CLI_COLOR_GREEN}All tools are up-to-date!${CLI_COLOR_RESET}"
    echo ""
  else
    echo ""
    if [[ ${#updates_available[@]} -gt 0 ]]; then
      echo -e "${CLI_COLOR_YELLOW}${#updates_available[@]} update(s) available${CLI_COLOR_RESET}"
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
      echo -e "${CLI_COLOR_CYAN}${#missing_tools[@]} tool(s) missing${CLI_COLOR_RESET}"
    fi

    if [[ "${AICLI_NOTIFICATION_STYLE:-prompt}" == "prompt" ]]; then
      echo ""
      for update_info in "${updates_available[@]}"; do
        local tool="${update_info%%:*}"
        local rest="${update_info#*:}"
        local current="${rest%%:*}"
        local latest="${rest##*:}"

        _aicli_prompt_update "$tool" "$current" "$latest"
      done
    fi
  fi
}

# Show status message
_aicli_show_status() {
  local message="$1"
  local type="${2:-info}"

  case "$type" in
    success)
      echo -e "${CLI_COLOR_GREEN}${message}${CLI_COLOR_RESET}"
      ;;
    error)
      echo -e "${CLI_COLOR_RED}${message}${CLI_COLOR_RESET}"
      ;;
    warning)
      echo -e "${CLI_COLOR_YELLOW}${message}${CLI_COLOR_RESET}"
      ;;
    *)
      echo -e "${CLI_COLOR_CYAN}${message}${CLI_COLOR_RESET}"
      ;;
  esac
}
