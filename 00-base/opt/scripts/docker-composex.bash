#!/usr/bin/env bash
set -euo pipefail

export PUID="$(id -u)"
export PGID="$(id -g)"
export DOCKER_GID="$(getent group docker | cut -d: -f3)"

exec docker compose "$@"
