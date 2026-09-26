#!/bin/bash
# Covers bin/install behaviour the Docker test cannot reach: how it resolves its own source, and
# which plugins a run decides to remove.
set -uo pipefail
# Note: No 'set -e' - every assertion runs so one report names all the failures, not just the first.

script_dir=$(dirname "$(realpath "$0")") || exit 1
install_script=$(realpath "$script_dir"/../bin/install) || exit 1
checkout=$(realpath "$script_dir"/..) || exit 1

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

# Call one function of bin/install with the script sourced from a real file.
call_sourced() {
  PROFILE_D_DEFINE_ONLY=1 bash -c '\. "$1" && shift && "$@"' _ "$install_script" "$@"
}

# Call one function of bin/install with the script piped into bash, as the install command does.
call_piped() {
  {
    cat "$install_script"
    printf '%s\n' "$*"
  } | PROFILE_D_DEFINE_ONLY=1 bash
}

echo "get_lib_remote"

# Inside a function BASH_SOURCE[0] holds "main" under a pipe, so a check for emptiness reads the
# piped case as a local checkout and resolves "main" against the caller's directory.
assert_equal \
  "resolves a local checkout to its root" \
  "$checkout" \
  "$(call_sourced get_lib_remote)"

assert_equal \
  "resolves a piped script to the git remote" \
  "https://github.com/jakubro/profile.d" \
  "$(cd / && call_piped get_lib_remote)"

assert_equal \
  "resolves a piped script to the git remote from any directory" \
  "https://github.com/jakubro/profile.d" \
  "$(cd "$checkout"/bin && call_piped get_lib_remote)"

echo "install_dir"

# mklink removes its target before linking, so a self-targeting install used to delete the tree.
target=$(mktemp -d) || exit 1
trap 'rm -rf "$target"' EXIT

mkdir -p "$target"/src || exit 1
echo marker >"$target"/src/include || exit 1

call_sourced install_dir "$target" "$target" >/dev/null 2>&1

assert_equal "leaves a self-targeting install in place" "marker" "$(cat "$target"/src/include 2>&1)"
assert_equal "leaves it a directory, not a symlink" "no" "$([ -L "$target" ] && echo yes || echo no)"

echo "plugin_name"

assert_equal "names a path entry by its last segment" "my-plugin" "$(call_sourced plugin_name /work/my-plugin)"
assert_equal "names a URL entry by its last segment" "profile.d-pyenv" \
  "$(call_sourced plugin_name https://x/profile.d-pyenv)"
assert_equal "names an entry by the part after a '#'" "profile.d-dotfiles" \
  "$(call_sourced plugin_name /work/dotfiles#profile.d-dotfiles)"
assert_equal "rejects a name holding a '/'" "rejected" \
  "$(call_sourced plugin_name '/work/dotfiles#a/b' >/dev/null 2>&1 && echo accepted || echo rejected)"
assert_equal "rejects an empty name" "rejected" \
  "$(call_sourced plugin_name '/work/dotfiles#' >/dev/null 2>&1 && echo accepted || echo rejected)"

echo "install_plugin"

# Install one entry into a throwaway home and print where the plugin directory points.
run_install_plugin() {

  local entry=$1
  local name=$2

  local home
  home=$(mktemp -d) || return 1
  mkdir -p "$home"/.profile.d/plugins || return 1

  HOME=$home PROFILE_D_DEFINE_ONLY=1 \
    bash -c '\. "$1" && install_plugin "$2"' _ "$install_script" "$entry" >/dev/null 2>&1
  readlink "$home"/.profile.d/plugins/"$name"

  rm -rf "$home"

}

source_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$target" "$source_dir"' EXIT

assert_equal "installs a path entry under the name after its '#'" "$source_dir" \
  "$(run_install_plugin "${source_dir}#profile.d-dotfiles" profile.d-dotfiles)"

echo "install_plugins"

# Two entries resolving to one name would let the second install delete the first.
home=$(mktemp -d) || exit 1
printf '#!/bin/bash\nPLUGINS=(%s)\n' "${source_dir}#twin https://x/twin" >"$home"/.profiledrc || exit 1
HOME=$home PROFILE_D_DEFINE_ONLY=1 \
  bash -c '\. "$1" && install_plugins' _ "$install_script" >/dev/null 2>&1
assert_equal "rejects two entries installing as one name" "1 " \
  "$? $(ls -A "$home"/.profile.d/plugins)"
rm -rf "$home"

echo "uninstall_plugins"

# Run uninstall_plugins against a throwaway home holding a .profiledrc and an installed plugin
# set, reporting either the surviving directories or what the run printed. $HOME is what
# bin/install resolves PLUGINS_PATH from at source time.
run_uninstall() {

  local report=$1
  local listed=$2
  local installed=$3

  local home
  home=$(mktemp -d) || return 1

  printf '#!/bin/bash\nPLUGINS=(%s)\n' "$listed" >"$home"/.profiledrc || return 1
  mkdir -p "$home"/.profile.d/plugins || return 1

  local name
  for name in $installed; do
    mkdir -p "$home"/.profile.d/plugins/"$name" || return 1
  done

  local log
  log=$(HOME=$home PROFILE_D_DEFINE_ONLY=1 \
    bash -c '\. "$1" && uninstall_plugins' _ "$install_script" 2>&1)

  if [ "$report" = log ]; then
    echo "$log"
  else
    # shellcheck disable=SC2012
    ls "$home"/.profile.d/plugins | sort | tr '\n' ' ' | sed 's/ $//'
  fi

  rm -rf "$home"

}

# The removal test reads $name after a loop that used to reuse the same variable, so a listed
# plugin and an unlisted one have to be present together for the defect to show.
assert_equal \
  "removes a plugin the config no longer lists" \
  "profile.d-direnv profile.d-pyenv" \
  "$(run_uninstall plugins 'https://x/profile.d-direnv https://x/profile.d-pyenv' \
    'profile.d-direnv profile.d-hstr profile.d-pyenv')"

assert_equal \
  "keeps every plugin the config still lists" \
  "profile.d-direnv profile.d-pyenv" \
  "$(run_uninstall plugins 'https://x/profile.d-direnv https://x/profile.d-pyenv' \
    'profile.d-direnv profile.d-pyenv')"

assert_equal \
  "keeps a plugin under the name after its '#'" \
  "profile.d-dotfiles" \
  "$(run_uninstall plugins '/work/profile.d#profile.d-dotfiles' 'profile.d profile.d-dotfiles')"

assert_equal \
  "removes everything when the config lists nothing" \
  "" \
  "$(run_uninstall plugins '' 'profile.d-direnv')"

# An unexpanded glob would otherwise be taken for a plugin named "*" and announced on the first
# install. Two things make this scenario the only one that shows it: the config has to be empty,
# or the name test wrongly matches and prints nothing anyway; and the assertion has to read the
# output, because the directory listing is empty either way.
assert_equal \
  "announces nothing on a first install" \
  "0" \
  "$(run_uninstall log '' '' | grep -c Uninstalling)"

echo
if [ "$failures" -gt 0 ]; then
  echo "${failures} failure(s)"
  exit 1
fi

echo "all assertions passed"
