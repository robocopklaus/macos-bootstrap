#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/robocopklaus/macos-bootstrap.git"
CLONE_DIR="$HOME/.macos-bootstrap"

if [[ ! -d "$CLONE_DIR" ]]; then
  echo "Cloning macos-bootstrap to $CLONE_DIR..."
  git clone "$REPO_URL" "$CLONE_DIR"
else
  echo "Updating macos-bootstrap in $CLONE_DIR..."
  git -C "$CLONE_DIR" pull --rebase
fi

cd "$CLONE_DIR"
exec ./scripts/main.sh "$@" 