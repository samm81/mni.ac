#!/usr/bin/env bash
set -euo pipefail

PUID=$(id -u)
PGID=$(id -g)
DOCKER_GID=$(getent group docker | cut -d: -f3)
export PUID PGID DOCKER_GID

compose_file_base=
for compose_file_candidate in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
    if [[ -f $compose_file_candidate ]]; then
        compose_file_base=$compose_file_candidate
        break
    fi
done

compose_files_fragment=()
if [[ -d compose.d ]]; then
    while IFS= read -r -d '' compose_file_fragment; do
        compose_files_fragment+=(-f "$compose_file_fragment")
    done < <(
        find -L compose.d -maxdepth 1 -type f \
            \( -name '*.yaml' -o -name '*.yml' \) -print0 \
            | sort -z
    )
fi

env_files_fragment=()
if [[ -d .env.d ]]; then
    while IFS= read -r -d '' env_file_fragment; do
        env_files_fragment+=(--env-file "$env_file_fragment")
    done < <(
        find -L .env.d -maxdepth 1 -type f -name '*.env' -print0 \
            | sort -z
    )
fi

if ((${#env_files_fragment[@]} > 0)) && [[ -f .env ]]; then
    env_files_fragment+=(--env-file .env)
fi

if ((${#compose_files_fragment[@]} > 0)); then
    if [[ -z $compose_file_base ]]; then
        printf 'missing base compose file in %s\n' "$PWD" >&2
        exit 1
    fi

    exec docker compose "${env_files_fragment[@]}" \
        -f "$compose_file_base" "${compose_files_fragment[@]}" "$@"
fi

exec docker compose "${env_files_fragment[@]}" "$@"
