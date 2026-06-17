#!/usr/bin/env bash
set -euo pipefail
set -a
source "$HOME/.config/restic/env"
set +a
exec restic "$@"
