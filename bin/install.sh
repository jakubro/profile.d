#!/bin/bash
set -o pipefail

# To install: curl https://raw.githubusercontent.com/jakubro/profile.d/main/bin/install.sh | bash

LOCATION=https://github.com/jakubro/profile.d
TIMESTAMP=$(date +%s) || exit 1

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  SCRIPT_DIR=$(dirname "$(realpath "$0")") || exit 1
  LOCATION=$(realpath "$SCRIPT_DIR"/..) || exit 1
fi

if [ -e ~/.profiledrc ]; then
  \. ~/.profiledrc || echo "Failed to process ~/.profiledrc"
fi

PLUGIN_REMOTES=("${PLUGINS[@]}")
PLUGIN_NAMES=()

for _plugin in "${PLUGINS[@]}"; do
  _name=$(basename "$_plugin") || exit 1
  PLUGIN_NAMES+=("$_name")
done

# Main

main() {

  cd ~ || return 1

  install_prerequisites || return 1
  install_lib || return 1
  install_plugins || return 1
  uninstall_plugins || return 1

  log_header "Successfully installed"

  log_info "Run the following command for the changes to take effect:"
  log_info "  \. ~/.bashrc"

}

# profile.d

install_prerequisites() {

  if has curl && has git; then
    return 0
  fi

  local prefix=""
  if has sudo; then
    prefix="sudo"
  fi

  # Fedora derivatives

  if has dnf; then

    $prefix dnf install -y curl git || return 1

  elif has yum; then

    $prefix yum install -y curl git || return 1

  # Debian derivatives

  elif has apt; then

    $prefix apt update -y &&
      $prefix apt install -y curl git || return 1

  elif has apt-get; then

    $prefix apt-get update -y &&
      $prefix apt-get install -y curl git || return 1

  # Arch Linux

  elif has pacman; then

    $prefix pacman -S --needed curl git || return 1

  # Alpine

  elif has apk; then

    $prefix apk add curl git || return 1

  # SUSE

  elif has zypper; then

    $prefix zypper install -y curl git || return 1

  # macOS

  elif has brew; then

    $prefix brew install curl git || return 1

  else

    echo "Cannot install curl and git. Please install them manually."
    return 1

  fi

}

install_lib() {

  local remote=$LOCATION
  local local=~/.profile.d/lib

  if [ -e ~/.profile.d ] && [ ! -d ~/.profile.d ]; then
    rm_backup ~/.profile.d || return 1
  fi

  install_dir "$remote" "$local" || return 1
  link_dotfiles "$local" || return 1
  write_rc_file || return 1

}

install_plugins() {

  mkdir -p ~/.profile.d/plugins || return 1

  local remote=""

  for remote in "${PLUGIN_REMOTES[@]}"; do

    install_plugin "$remote" || log_error "Failed to install ${remote}"

  done

}

uninstall_plugins() {

  log_header "Uninstalling plugins"

  local local=""

  for local in ~/.profile.d/plugins/*; do

    uninstall_plugin "$local" || log_error "Failed to uninstall ${local}"

  done

}

install_plugin() {

  local remote=$1

  local name
  name=$(basename "$remote") || return 1

  local local=~/.profile.d/plugins/"$name"

  install_dir "$remote" "$local" || return 1
  link_dotfiles "$local" || return 1

  if [ -e "$local"/bin/install.sh ]; then
    /bin/bash "$local"/bin/install.sh || return 1
  fi

}

uninstall_plugin() {

  local local=$1

  local name
  name=$(basename "$local") || return 1

  if [[ " ${PLUGIN_NAMES[*]} " != *" ${name} "* ]]; then

    log_info "Uninstalling plugin ${name}..."

    if [ -L "$local" ]; then
      unlink "$local" || return 1
    else
      rm -rf "$local" || return 1
    fi

  fi

}

install_dir() {

  local remote=$1
  local local=$2

  local name
  name=$(basename "$remote") || return 1

  local local_parent
  local_parent=$(dirname "$local") || return 1

  log_header "${name}"

  mkdir -p "$local_parent" || return 1

  if is_uri "$remote"; then

    if [ ! -e "$local" ]; then

      log_info "Installing from ${remote}..."
      git clone --quiet "$remote" "$local" || return 1

    else
      (

        log_info "Updating ${name}..."

        cd "$local" || return 1
        git pull --quiet || return 1

      )
    fi

  else

    log_info "Installing from ${remote}..."
    mklink "$remote" "$local" -f || return 1

  fi

}

link_dotfiles() {

  local dir=${1}/home

  if [ -e "$dir" ]; then

    log_info "Linking dotfiles into home directory..."

    find "$dir" -mindepth 1 -maxdepth 1 ! -name README.md -print0 |
      while IFS= read -r -d "" file; do

        source=$(basename "$file") || return 1
        target=${source%.private}

        mklink "${dir}/${source}" ~/"$target" || return 1

      done || return 1

  fi

}

write_rc_file() {

  if [ ! -f ~/.profiledrc ]; then

    cat <<EOF >~/.profiledrc || return 1
#!/bin/bash
# https://github.com/jakubro/profile.d

PLUGINS=()
EOF

  fi

}

# Utils

has() {
  command -v "$@" &>/dev/null
}

is_uri() {
  grep -qE '^[^ ]+://.+$' <<<"$1"
}

log_header() {

  local blue="\e[94m"
  local endcolor="\e[0m"

  echo -ne "$blue"
  echo "==========================================================================================="
  echo "${*}"
  echo "==========================================================================================="
  echo -ne "$endcolor"

}

log_debug() {

  local gray="\e[90m"
  local endcolor="\e[0m"

  echo -e "${gray}${*}${endcolor}"

}

log_info() {

  local green="\e[92m"
  local endcolor="\e[0m"

  echo -e "${green}${*}${endcolor}"

}

log_warn() {

  local yellow="\e[93m"
  local endcolor="\e[0m"

  echo -e "${yellow}${*}${endcolor}"

}

log_error() {

  local red="\e[31m"
  local endcolor="\e[0m"

  echo 1>&2 -e "${red}${*}${endcolor}"

}

mklink() {

  local source=$1
  shift

  local target=$1
  shift

  local target_dir
  target_dir=$(dirname "$target") || return 1

  local target_name
  target_name=$(basename "$target") || return 1

  if [ -L "$target" ]; then

    unlink "$target" || return 1

  elif [ -e "$target" ]; then

    if has_flag -f "$*"; then
      rm -rf "$target" || return 1
    else
      rm_backup "$target" || return 1
    fi

  fi

  (
    cd "$target_dir" || return 1
    ln -sfv "$source" "$target_name" || return 1
  )

}

rm_backup() {

  local path=$1

  if [ -e "$path" ]; then

    path=$(realpath "$path") || return 1
    local backup="${path}.backup.${TIMESTAMP}"

    mv -fv "$path" "$backup" || return 1

  fi

}

has_flag() {

  local value=$1
  shift

  [[ " $* " == *" ${value} "* ]]

}

# Main

export -f log_header
export -f log_debug
export -f log_info
export -f log_warn

main
