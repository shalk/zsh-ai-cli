#!/usr/bin/env zsh

# Version comparison logic for AI CLI tools

# Load zsh's is-at-least function
autoload -Uz is-at-least

# Clean version string by removing common prefixes and whitespace
_aicli_clean_version() {
  local version="$1"

  # Remove common prefixes
  version="${version#v}"
  version="${version#V}"
  version="${version#version }"
  version="${version#Version }"

  # Remove tool-specific prefixes
  version="${version#gemini-cli }"
  version="${version#claude-code }"
  version="${version#codex-cli }"
  version="${version#@google/gemini-cli@}"
  version="${version#@github/copilot@}"
  version="${version#@openai/codex@}"
  version="${version#claude-code@}"

  # Trim whitespace
  version="${version## }"
  version="${version%% }"

  echo "$version"
}

# Compare two semantic versions
# Returns 0 if update is available (latest > current)
# Returns 1 if current is up-to-date (current >= latest)
# Returns 2 if versions are invalid
_aicli_update_check_versions() {
  local current="$1"
  local latest="$2"

  # Clean both versions
  current="$(_aicli_clean_version "$current")"
  latest="$(_aicli_clean_version "$latest")"

  # Validate versions are not empty
  if [[ -z "$current" || -z "$latest" ]]; then
    return 2
  fi

  # Validate versions match semver pattern (basic check)
  if [[ ! "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] || [[ ! "$latest" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    return 2
  fi

  # Use zsh's built-in is-at-least function.
  # In zsh, is-at-least <minimum> <actual> returns 0 when <actual> >= <minimum>.
  if is-at-least "$latest" "$current"; then
    # Current is at least latest version (up-to-date)
    return 1
  else
    # Latest is newer than current (update available)
    return 0
  fi
}

# Extract version number from command output
# Handles various output formats from different tools
_aicli_extract_version() {
  local output="$1"

  # Try to extract semantic version (x.y.z)
  local version=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?' | head -n1)

  echo "$version"
}

# Validate that a version string looks reasonable
_aicli_is_valid_version() {
  local version="$1"

  [[ -n "$version" ]] && [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]
}
