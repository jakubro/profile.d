#!/bin/bash

script_name=$(basename "$0") || exit 1
script_dir=$(dirname "$(realpath "$0")") || exit 1
root_dir=$(realpath "$script_dir"/../..) || exit 1

if [ -z "$1" ]; then
  echo "Invalid command line arguments

Usage:

  $script_name <image>

Examples:

  $ $script_name fedora
  $ $script_name ubuntu
  "
  exit 1
fi

echo "$root_dir"

docker run \
  --rm \
  -v "$root_dir":"$root_dir" \
  -it \
  "$1" \
  "$script_dir"/test-install-entrypoint.sh
