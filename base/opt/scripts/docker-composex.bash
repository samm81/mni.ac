#!/usr/bin/env bash
set -euo pipefail

export PUID="$(id -u)"
export PGID="$(id -g)"

exec docker compose "$@"
