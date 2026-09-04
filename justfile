# profile.d development tasks

set shell := ["bash", "-euo", "pipefail", "-c"]

# List available recipes
default:
    @just --list

# Build the documentation site
[group('site')]
[working-directory('site')]
site:
    npm ci
    npm run build

# Serve docs/ with live reload
[group('site')]
[working-directory('site')]
preview HOST="127.0.0.1" PORT="4321":
    npm ci
    npm run dev -- --host {{ HOST }} --port {{ PORT }}
