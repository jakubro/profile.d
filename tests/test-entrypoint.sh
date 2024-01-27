#!/bin/bash

log_header() {

  local yellow="\e[93m"
  local endcolor="\e[0m"

  echo -ne "$yellow"
  echo "###########################################################################################"
  echo "###########################################################################################"
  echo "##"
  echo "## ${*}"
  echo "##"
  echo "###########################################################################################"
  echo "###########################################################################################"
  echo -ne "$endcolor"

}

script_dir=$(dirname "$(realpath "$0")") || exit 1
root_dir=$(realpath "$script_dir"/../..) || exit 1

cd ~ || exit 1

log_header "Installing prerequisites"

if command -v dnf &>/dev/null; then

  dnf install -y \
    make gcc patch \
    zlib-devel bzip2 bzip2-devel \
    readline-devel sqlite sqlite-devel \
    openssl-devel tk-devel libffi-devel \
    xz-devel libuuid-devel gdbm-libs \
    libnsl2 || exit 1
  dnf install -y gettext || exit 1

elif command -v apt &>/dev/null; then

  export DEBIAN_FRONTEND=noninteractive
  export TZ=Etc/UTC

  apt update -y || exit 1
  apt install -y \
    build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev \
    curl libncursesw5-dev xz-utils \
    tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev || exit 1
  apt install -y gettext || exit 1

else

  echo "Unsupported Linux distro"
  exit 1

fi

log_header "Testing installation"

PLUGIN_SOURCE="$root_dir"/plugins envsubst <"$script_dir"/.profiledrc >~/.profiledrc || exit 1
/bin/bash "$root_dir"/lib/bin/install.sh || exit 1

log_header "Testing loading"

set -o allexport
\. ~/.bashrc || exit 1
set +o allexport

log_header "Testing direnv"

cp "$script_dir"/.envrc ~/.envrc || exit 1
direnv allow ~/.envrc || exit 1
direnv exec ~ echo "hello world" || exit 1
