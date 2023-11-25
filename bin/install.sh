#!/bin/bash
set -eo pipefail

# To install: curl https://raw.githubusercontent.com/jakubro/profile.d/main/bin/install.sh | bash

LOCATION=https://github.com/jakubro/profile.d
TIMESTAMP=$(date +%s)

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  SCRIPT_DIR=$(dirname "$(realpath "$0")")
  LOCATION=$(realpath "$SCRIPT_DIR"/..)
fi

# Main

main() {

  cd ~

  install_lib
  install_plugins

  log_header "Successfully installed"

  log_info "Run the following command for the changes to take effect:"
  log_info "  \. ~/.bashrc"

}

# Lib

install_lib() {

  local remote=$LOCATION
  local local=~/.profile.d/lib

  if [ -e ~/.profile.d ] && [ ! -d ~/.profile.d ]; then
    rm_backup ~/.profile.d
  fi

  install_dir "$remote" "$local"
  link_dotfiles "$local"

}

install_plugins() {

  if [ -e ~/.profiledrc ]; then
    \. ~/.profiledrc
  fi

  local remote

  for remote in "${PLUGINS[@]}"; do

    local name
    name=$(basename "$remote")

    local local=~/.profile.d/plugins/"$name"

    install_dir "$remote" "$local"
    link_dotfiles "$local"

    if [ -e "$local"/bin/install.sh ]; then
      /bin/bash "$local"/bin/install.sh
    fi

  done

}

link_dotfiles() {

  local dir=${1}/home

  if [ -e "$dir" ]; then

    log_info "Linking dotfiles into home directory..."

    find "$dir" -mindepth 1 -maxdepth 1 ! -name README.md -print0 |
      while IFS= read -r -d "" file; do

        source=$(basename "$file")
        target=${source%.private}

        mklink "${dir}/${source}" ~/"$target"

      done

  fi

}

install_dir() {

  local remote=$1
  local local=$2

  local name
  name=$(basename "$remote")

  local local_parent
  local_parent=$(dirname "$local")

  log_header "Installing ${name}"

  mkdir -p "$local_parent"

  if is_uri "$remote"; then

    if [ ! -e "$local" ]; then

      log_info "Installing from ${remote}..."
      git clone "$remote" "$local"

    else
      (

        log_info "Updating ${name}..."

        cd "$local"
        git pull

      )
    fi

  else

    log_info "Installing from ${remote}..."
    mklink "$remote" "$local" -f

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

is_uri() {

  grep -qE '^[^ ]+://.+$' <<<"$1"

}

mklink() {

  local source=$1
  shift

  local target=$1
  shift

  local target_dir
  target_dir=$(dirname "$target")

  local target_name
  target_name=$(basename "$target")

  if [ -L "$target" ]; then

    command unlink "$target"

  elif [ -e "$target" ]; then

    if ! has_flag -f "$*"; then
      rm_backup "$target"
    fi

  fi

  (
    cd "$target_dir"
    command ln -sfv "$source" "$target_name"
  )

}

rm_backup() {

  local path=$1

  if [ -e "$path" ]; then

    path=$(realpath "$path")
    local backup="${path}.backup.${TIMESTAMP}"

    command mv -fv "$path" "$backup"

  fi

}

has_flag() {

  local value=$1
  shift

  local flags=" $* "

  [[ ${flags} == *" ${value} "* ]]

}

# Main

export -f log_header
export -f log_debug
export -f log_info
export -f log_warn

main
