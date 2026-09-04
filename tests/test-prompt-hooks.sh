#!/bin/bash
# Asserts the prompt hooks are registered exactly once however often ~/.bashrc is re-sourced.
set -uo pipefail
# Note: No 'set -e' - every assertion runs so one report names all the failures, not just the first.

script_dir=$(dirname "$(realpath "$0")") || exit 1
hook=$(realpath "$script_dir"/../hooks/pre-init/01-register-prompt-hooks) || exit 1

failures=0

# Report one assertion and count it.
assert_equal() {

  local what=$1
  local expected=$2
  local actual=$3

  if [ "$expected" = "$actual" ]; then
    echo "  ok    ${what}"
  else
    echo "  FAIL  ${what}"
    echo "          expected: ${expected}"
    echo "          actual:   ${actual}"
    failures=$((failures + 1))
  fi

}

# Source the hook `count` times in one interactive shell and report the resulting entry count.
# The hook is a no-op in a non-interactive shell, so the probe has to ask for one.
prompt_command_size() {

  local initial=$1
  local count=$2

  bash --norc -i -c '
    unset PROMPT_COMMAND
    if [ -n "$1" ]; then PROMPT_COMMAND=("$1"); fi
    for _ in $(seq "$2"); do \. "$3"; done
    echo "${#PROMPT_COMMAND[@]}"
  ' _ "$initial" "$count" "$hook" 2>/dev/null

}

echo "01-register-prompt-hooks"

# An empty PROMPT_COMMAND caches as an empty array; a guard reading its first element cannot tell
# that from an absent cache, and re-caches the already-wrapped value on the next reload.
assert_equal "wraps an empty PROMPT_COMMAND once" "2" "$(prompt_command_size "" 1)"
assert_equal "stays wrapped once across reloads" "2" "$(prompt_command_size "" 4)"

assert_equal "keeps an existing PROMPT_COMMAND entry" "3" "$(prompt_command_size "distro_hook" 1)"
assert_equal "keeps it exactly once across reloads" "3" "$(prompt_command_size "distro_hook" 4)"

echo
if [ "$failures" -gt 0 ]; then
  echo "${failures} failure(s)"
  exit 1
fi

echo "all assertions passed"
