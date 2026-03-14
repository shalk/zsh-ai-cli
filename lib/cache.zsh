#!/usr/bin/env zsh

# Cache management for AI CLI update checker
# Prevents excessive npm registry queries

# Get cache directory, create if needed
_aicli_get_cache_dir() {
  local cache_dir="${AICLI_CACHE_DIR:-${ZSH_CACHE_DIR:-$HOME/.cache/oh-my-zsh}/ai-cli}"

  if [[ ! -d "$cache_dir" ]]; then
    mkdir -p "$cache_dir" 2>/dev/null || {
      echo "Warning: Could not create cache directory: $cache_dir" >&2
      return 1
    }
  fi

  echo "$cache_dir"
}

# Get current day as epoch (days since Unix epoch)
_aicli_current_epoch() {
  echo $(( $(date +%s) / 86400 ))
}

# Check if we should run update checks based on interval
# Returns 0 (true) if check should run, 1 (false) if within interval
_aicli_should_check_updates() {
  local cache_dir="$(_aicli_get_cache_dir)" || return 0
  local last_check_file="$cache_dir/last_check.cache"

  # If cache file doesn't exist, we should check
  [[ ! -f "$last_check_file" ]] && return 0

  local last_check=$(cat "$last_check_file" 2>/dev/null)
  local current_epoch=$(_aicli_current_epoch)
  local interval="${AICLI_CHECK_INTERVAL:-7}"

  # If we can't read last check or it's malformed, check anyway
  [[ -z "$last_check" ]] && return 0

  # Check if enough days have passed
  local days_since=$(( current_epoch - last_check ))
  [[ $days_since -ge $interval ]] && return 0

  return 1
}

# Update last check timestamp
_aicli_update_last_check() {
  local epoch="${1:-$(_aicli_current_epoch)}"
  local cache_dir="$(_aicli_get_cache_dir)" || return 1
  local last_check_file="$cache_dir/last_check.cache"

  echo "$epoch" > "$last_check_file"
}

# Cache version information for a tool
_aicli_cache_version_info() {
  local tool="$1"
  local current="$2"
  local latest="$3"

  local cache_dir="$(_aicli_get_cache_dir)" || return 1
  local cache_file="$cache_dir/${tool}.cache"

  cat > "$cache_file" <<EOF
CURRENT=$current
LATEST=$latest
TIMESTAMP=$(_aicli_current_epoch)
EOF
}

# Get cached version information for a tool
# Returns 0 if cache exists and is valid, 1 otherwise
# Sets CLI_CACHED_CURRENT and CLI_CACHED_LATEST variables
_aicli_get_cached_info() {
  local tool="$1"
  local cache_dir="$(_aicli_get_cache_dir)" || return 1
  local cache_file="$cache_dir/${tool}.cache"

  [[ ! -f "$cache_file" ]] && return 1

  # Source the cache file to get variables
  local CURRENT LATEST TIMESTAMP
  source "$cache_file" 2>/dev/null || return 1

  # Verify we got the required variables
  [[ -z "$CURRENT" || -z "$LATEST" ]] && return 1

  # Export for caller
  CLI_CACHED_CURRENT="$CURRENT"
  CLI_CACHED_LATEST="$LATEST"

  return 0
}

# Clear all cache (useful for testing or force refresh)
_aicli_clear_cache() {
  local cache_dir="$(_aicli_get_cache_dir)" || return 1
  setopt local_options null_glob
  local cache_files=("$cache_dir"/*)
  [[ ${#cache_files[@]} -gt 0 ]] && rm -rf -- "${cache_files[@]}"
  echo "Cache cleared: $cache_dir"
}
