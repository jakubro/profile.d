#!/bin/bash
set -o pipefail

# To install: curl https://raw.githubusercontent.com/jakubro/profile.d/main/bin/install.sh | bash

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

    $prefix apt update -y \
      && $prefix apt install -y curl git || return 1

  elif has apt-get; then

    $prefix apt-get update -y \
      && $prefix apt-get install -y curl git || return 1

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

get_lib_remote() {

  if [ "${BASH_SOURCE[0]}" != "$0" ]; then

    # installing using curl

    echo https://github.com/jakubro/profile.d

  else

    # running locally - ./install.sh

    local script_dir
    script_dir=$(dirname "$(realpath "$0")") || return 1

    realpath "$script_dir"/.. || return 1

  fi

}

install_lib() {

  local remote
  remote=$(get_lib_remote) || return 1

  local local=~/.profile.d/lib

  if [ -e ~/.profile.d ] && [ ! -d ~/.profile.d ]; then
    rm_backup ~/.profile.d || return 1
  fi

  install_dir "$remote" "$local" || return 1
  link_dotfiles "$local" || return 1
  write_rc_file || return 1

}

install_plugins() {

  if [ -e ~/.profiledrc ]; then
    \. ~/.profiledrc || echo "Failed to read ~/.profiledrc"
  fi

  mkdir -p ~/.profile.d/plugins || return 1

  local remote

  for remote in "${PLUGINS[@]}"; do

    install_plugin "$remote" || log_error "Failed to install ${remote}"

  done

}

uninstall_plugins() {

  log_header "Uninstalling plugins"

  local path

  for path in ~/.profile.d/plugins/*; do

    uninstall_plugin "$path" || log_error "Failed to uninstall ${path}"

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

  local path=$1

  local name
  name=$(basename "$path") || return 1

  if [ -e ~/.profiledrc ]; then
    \. ~/.profiledrc || echo "Failed to read ~/.profiledrc"
  fi

  local remote
  local plugin_names=()

  for remote in "${PLUGINS[@]}"; do

    local name
    name=$(basename "$remote") || return 1

    plugin_names+=("$name")

  done

  if [[ " ${plugin_names[*]} " != *" ${name} "* ]]; then

    log_info "Uninstalling plugin ${name}..."

    if [ -L "$path" ]; then
      unlink "$path" || return 1
    else
      rm -rf "$path" || return 1
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

    find "$dir" -mindepth 1 -maxdepth 1 ! -name README.md -print0 \
      | while IFS= read -r -d "" file; do

        path=$(basename "$file") || return 1

        mklink "${dir}/${path}" ~/"$path" || return 1

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

log_header() {

  local blue="\e[94m"
  local endcolor="\e[0m"

  echo -ne "$blue"
  echo "==========================================================================================="
  echo "${*}"
  echo "==========================================================================================="
  echo -ne "$endcolor"

}

export -f log_header

log_debug() {

  local gray="\e[90m"
  local endcolor="\e[0m"

  echo -e "${gray}${*}${endcolor}"

}

export -f log_debug

log_info() {

  local green="\e[92m"
  local endcolor="\e[0m"

  echo -e "${green}${*}${endcolor}"

}

export -f log_info

log_warn() {

  local yellow="\e[93m"
  local endcolor="\e[0m"

  echo -e "${yellow}${*}${endcolor}"

}

export -f log_warn

log_error() {

  local red="\e[31m"
  local endcolor="\e[0m"

  echo >&2 -e "${red}${*}${endcolor}"

}

export -f log_error

has() {
  command -v "$@" &>/dev/null
}

export -f has

is_uri() {
  grep -qE '^[^ ]+://.+$' <<<"$1"
}

export -f is_uri

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

export -f mklink

rm_backup() {

  local path=$1
  local timestamp

  if [ -e "$path" ]; then

    path=$(realpath "$path") || return 1
    timestamp=$(date +%s) || return 1
    local backup="${path}.backup.${timestamp}"

    mv -fv "$path" "$backup" || return 1

  fi

}

export -f rm_backup

has_flag() {

  local value=$1
  shift

  [[ " $* " == *" ${value} "* ]]

}

export -f has_flag

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

main
