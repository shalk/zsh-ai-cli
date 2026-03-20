#!/usr/bin/env zsh

# Dependency tools detection (nvm, node, npm)
# These are fundamental dependencies for npm-based AI CLI tools

# NVM latest version (update periodically)
typeset -g NVM_LATEST_VERSION="v0.40.4"

# Check if nvm is available
_aicli_is_nvm_installed() {
  # nvm is a shell function, not a command
  # Check multiple ways to determine if nvm is available
  
  # Method 1: Check if nvm command exists (in case it's aliased or wrapped)
  if command -v nvm &>/dev/null; then
    return 0
  fi
  
  # Method 2: Check if NVM_DIR is set and nvm.sh exists
  if [[ -n "${NVM_DIR}" && -s "${NVM_DIR}/nvm.sh" ]]; then
    return 0
  fi
  
  # Method 3: Check common installation paths
  if [[ -s "${HOME}/.nvm/nvm.sh" ]]; then
    return 0
  fi
  
  if [[ -s "${XDG_CONFIG_HOME:-$HOME/.config}/nvm/nvm.sh" ]]; then
    return 0
  fi
  
  return 1
}

# Check if node is installed
_aicli_is_node_installed() {
  command -v node &>/dev/null
}

# Check if npm is installed
_aicli_is_npm_installed() {
  command -v npm &>/dev/null
}

# Get nvm version
_aicli_get_nvm_version() {
  if ! _aicli_is_nvm_installed; then
    return 1
  fi

  local version
  
  # Try to get version directly if nvm command is available
  if command -v nvm &>/dev/null; then
    version=$(nvm --version 2>/dev/null | head -n 1)
    if [[ -n "$version" ]]; then
      echo "$version"
      return 0
    fi
  fi
  
  # Otherwise, source nvm.sh and try again
  local nvm_sh=""
  if [[ -n "${NVM_DIR}" && -s "${NVM_DIR}/nvm.sh" ]]; then
    nvm_sh="${NVM_DIR}/nvm.sh"
  elif [[ -s "${HOME}/.nvm/nvm.sh" ]]; then
    nvm_sh="${HOME}/.nvm/nvm.sh"
  elif [[ -s "${XDG_CONFIG_HOME:-$HOME/.config}/nvm/nvm.sh" ]]; then
    nvm_sh="${XDG_CONFIG_HOME:-$HOME/.config}/nvm/nvm.sh"
  fi
  
  if [[ -n "$nvm_sh" ]]; then
    version=$(zsh -c "source '$nvm_sh' && nvm --version" 2>/dev/null | head -n 1)
    if [[ -n "$version" ]]; then
      echo "$version"
      return 0
    fi
  fi
  
  return 1
}

# Get node version
_aicli_get_node_version() {
  if ! _aicli_is_node_installed; then
    return 1
  fi

  local version
  version=$(node --version 2>/dev/null)
  
  if [[ -n "$version" ]]; then
    # Remove 'v' prefix if present
    echo "${version#v}"
    return 0
  fi
  
  return 1
}

# Get npm version
_aicli_get_npm_version() {
  if ! _aicli_is_npm_installed; then
    return 1
  fi

  local version
  version=$(npm --version 2>/dev/null)
  
  if [[ -n "$version" ]]; then
    echo "$version"
    return 0
  fi
  
  return 1
}

# Get nvm install command
_aicli_get_nvm_install_command() {
  echo "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST_VERSION}/install.sh | bash"
}

# Get nvm upgrade command
_aicli_get_nvm_upgrade_command() {
  echo "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST_VERSION}/install.sh | bash"
}

# Get node install command
_aicli_get_node_install_command() {
  if _aicli_is_nvm_installed; then
    echo "nvm install node"
  else
    echo "Install nvm first, then run: nvm install node"
  fi
}

# Get node upgrade command
_aicli_get_node_upgrade_command() {
  if _aicli_is_nvm_installed; then
    echo "nvm install node --reinstall-packages-from=current"
  else
    echo "Use nvm to manage node versions"
  fi
}

# Get npm install command
_aicli_get_npm_install_command() {
  echo "npm is installed with node"
}

# Get npm upgrade command
_aicli_get_npm_upgrade_command() {
  echo "npm install -g npm@latest"
}

# Check dependency status and return structured info
# Sets global variables: DEP_TOOL_NAME, DEP_TOOL_VERSION, DEP_TOOL_STATUS, DEP_TOOL_INSTALL_CMD, DEP_TOOL_UPGRADE_CMD
_aicli_check_dependency() {
  local tool="$1"
  
  typeset -g DEP_TOOL_NAME DEP_TOOL_VERSION DEP_TOOL_STATUS DEP_TOOL_INSTALL_CMD DEP_TOOL_UPGRADE_CMD
  
  DEP_TOOL_NAME="$tool"
  DEP_TOOL_STATUS="unknown"
  DEP_TOOL_VERSION=""
  DEP_TOOL_INSTALL_CMD=""
  DEP_TOOL_UPGRADE_CMD=""
  
  case "$tool" in
    nvm)
      if _aicli_is_nvm_installed; then
        DEP_TOOL_VERSION="$(_aicli_get_nvm_version)"
        if [[ -n "$DEP_TOOL_VERSION" ]]; then
          DEP_TOOL_STATUS="installed"
          DEP_TOOL_UPGRADE_CMD="$(_aicli_get_nvm_upgrade_command)"
        else
          DEP_TOOL_STATUS="error"
        fi
      else
        DEP_TOOL_STATUS="missing"
        DEP_TOOL_INSTALL_CMD="$(_aicli_get_nvm_install_command)"
      fi
      ;;
      
    node)
      if _aicli_is_node_installed; then
        DEP_TOOL_VERSION="$(_aicli_get_node_version)"
        if [[ -n "$DEP_TOOL_VERSION" ]]; then
          DEP_TOOL_STATUS="installed"
          DEP_TOOL_UPGRADE_CMD="$(_aicli_get_node_upgrade_command)"
        else
          DEP_TOOL_STATUS="error"
        fi
      else
        DEP_TOOL_STATUS="missing"
        DEP_TOOL_INSTALL_CMD="$(_aicli_get_node_install_command)"
      fi
      ;;
      
    npm)
      if _aicli_is_npm_installed; then
        DEP_TOOL_VERSION="$(_aicli_get_npm_version)"
        if [[ -n "$DEP_TOOL_VERSION" ]]; then
          DEP_TOOL_STATUS="installed"
          DEP_TOOL_UPGRADE_CMD="$(_aicli_get_npm_upgrade_command)"
        else
          DEP_TOOL_STATUS="error"
        fi
      else
        DEP_TOOL_STATUS="missing"
        DEP_TOOL_INSTALL_CMD="$(_aicli_get_npm_install_command)"
      fi
      ;;
      
    *)
      return 1
      ;;
  esac
  
  return 0
}

# Check all dependencies
_aicli_check_all_dependencies() {
  local deps=(nvm node npm)
  local results=()
  
  for dep in "${deps[@]}"; do
    if _aicli_check_dependency "$dep"; then
      results+=("${DEP_TOOL_NAME}:${DEP_TOOL_STATUS}:${DEP_TOOL_VERSION}:${DEP_TOOL_INSTALL_CMD}:${DEP_TOOL_UPGRADE_CMD}")
    fi
  done
  
  # Return results as array
  echo "${(j:\n:)results}"
}
