#!/usr/bin/env bash
set -euo pipefail

repo_directory=
repo_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
caddy_image=${CADDY_IMAGE:-caddy:2-alpine}
tree_directory=

mapfile -t shell_files < <(
    find "$repo_directory" -type f \
        \( -name '*.bash' -o -name '*.sh' \) \
        -not -path "$repo_directory/.git/*" -print | sort
)
mapfile -t yaml_files < <(
    find "$repo_directory" -type f \
        \( -name '*.yaml' -o -name '*.yml' \) \
        -not -path "$repo_directory/.git/*" -print | sort
)
mapfile -t markdown_files < <(
    find "$repo_directory" -type f -name '*.md' \
        -not -path "$repo_directory/.git/*" -print | sort
)
mapfile -t caddy_files < <(
    find "$repo_directory" -type f \
        \( -name 'Caddyfile' -o -name '*.caddy' -o -name '*.caddyfile' \) \
        -not -path "$repo_directory/.git/*" -print | sort
)

command_required() {
    local command_name=$1

    if ! command -v "$command_name" > /dev/null 2>&1; then
        printf 'error: required command not found: %s\n' "$command_name" >&2
        exit 1
    fi
}

tree_cleanup() {
    if [[ -n ${tree_directory:-} ]]; then
        rm -rf -- "$tree_directory"
    fi
}

caddy_format() {
    local caddy_file=$1
    shift

    if command -v caddy > /dev/null 2>&1; then
        caddy fmt "$@" "$caddy_file"
    else
        docker run --rm \
            --entrypoint caddy \
            --user "$(id -u):$(id -g)" \
            --volume "$repo_directory:/work" \
            --workdir /work \
            "$caddy_image" fmt "$@" "/work/${caddy_file#"$repo_directory"/}"
    fi
}

format_shell() {
    command_required shfmt
    shfmt -w -i 4 -ci -bn -sr "${shell_files[@]}"
}

format_caddy() {
    for caddy_file in "${caddy_files[@]}"; do
        caddy_format "$caddy_file" --overwrite
    done
}

format_yaml() {
    command_required prettier
    prettier --write -- "${yaml_files[@]}"
}

format_markdown() {
    command_required prettier
    prettier --write -- "${markdown_files[@]}"
}

format_check_shell() {
    command_required shfmt
    shfmt -d -i 4 -ci -bn -sr "${shell_files[@]}"
}

format_check_caddy() {
    for caddy_file in "${caddy_files[@]}"; do
        caddy_format "$caddy_file" | diff -u "$caddy_file" -
    done
}

format_check_yaml() {
    command_required prettier
    prettier --check -- "${yaml_files[@]}"
}

format_check_markdown() {
    command_required prettier
    prettier --check -- "${markdown_files[@]}"
}

format_check_whitespace() {
    command_required git
    git -C "$repo_directory" diff --check
}

lint_shell() {
    command_required shellcheck
    shellcheck --severity=warning "${shell_files[@]}"
}

lint_yaml() {
    command_required yamllint
    yamllint -c "$repo_directory/.yamllint" "${yaml_files[@]}"
}

lint_markdown() {
    command_required markdownlint-cli2
    markdownlint-cli2 --config "$repo_directory/.markdownlint.yaml" "${markdown_files[@]}"
}

tree_prepare() {
    command_required stow

    tree_directory=$(mktemp -d "${TMPDIR:-/tmp}/mni.ac-check.XXXXXX")
    trap tree_cleanup EXIT

    local package_directory
    local package_name
    local package_names=()
    for package_directory in "$repo_directory"/*; do
        [[ -d $package_directory ]] || continue

        package_name=${package_directory##*/}
        case $package_name in
            .git | .github | scripts)
                continue
                ;;
        esac

        if [[ -d $package_directory/bin || -d $package_directory/dot-config ||
            -d $package_directory/etc || -d $package_directory/opt ]]; then
            package_names+=("$package_name")
        fi
    done

    (
        cd "$repo_directory"
        # ponytail: ignore the host-specific absolute resticx link in this temporary tree.
        stow --dotfiles --no-folding --target="$tree_directory" \
            --ignore='^bin/resticx$' "${package_names[@]}"
    )

}

validate_stow() {
    tree_prepare
}

validate_compose() {
    command_required docker
    tree_prepare

    local caddy_directory=$tree_directory/opt/compose/caddy
    cp -- "$caddy_directory/example.env" "$caddy_directory/.env"
    cp -- "$tree_directory/opt/compose/beszel/example.env.beszel" \
        "$tree_directory/opt/compose/beszel/.env.beszel"
    cp -- "$tree_directory/opt/compose/beszel/example.env.beszel_agent" \
        "$tree_directory/opt/compose/beszel/.env.beszel_agent"
    cp -- "$tree_directory/opt/compose/postgres/example.env" \
        "$tree_directory/opt/compose/postgres/.env"

    (
        cd "$caddy_directory"
        PUID=1000 \
            PGID=1000 \
            DOCKER_GID=1000 \
            DOMAIN=example.com \
            CLAW_SRV="$tree_directory/opt/srv" \
            "$tree_directory/opt/scripts/docker-composex.bash" config --quiet
    )

    local compose_file
    local compose_directory
    local compose_name
    while IFS= read -r compose_file; do
        compose_directory=${compose_file%/*}
        [[ $compose_directory == "$caddy_directory" ]] && continue
        compose_name=${compose_file##*/}

        (
            cd "$compose_directory"
            PUID=1000 \
                PGID=1000 \
                DOCKER_GID=1000 \
                DOMAIN=example.com \
                CLAW_SRV="$tree_directory/opt/srv" \
                docker compose -f "$compose_name" config --quiet
        )
    done < <(
        find -L "$tree_directory/opt/compose" -type f \
            \( -name 'compose.yaml' -o -name 'compose.yml' -o \
            -name 'docker-compose.yaml' -o -name 'docker-compose.yml' \) \
            -not -path '*/compose.d/*' -print | sort
    )

}

validate_caddy() {
    tree_prepare
    local caddy_directory=$tree_directory/opt/compose/caddy

    if command -v caddy > /dev/null 2>&1; then
        DOMAIN=example.com caddy validate \
            --config "$caddy_directory/conf/Caddyfile" \
            --adapter caddyfile
    else
        docker run --rm \
            --entrypoint caddy \
            --env DOMAIN=example.com \
            --volume "$repo_directory:$repo_directory:ro" \
            --volume "$caddy_directory:/work:ro" \
            "$caddy_image" validate \
            --config /work/conf/Caddyfile \
            --adapter caddyfile
    fi
}

case ${1:-} in
    format/shell)
        format_shell
        ;;
    format/caddy)
        format_caddy
        ;;
    format/yaml)
        format_yaml
        ;;
    format/markdown)
        format_markdown
        ;;
    format/check/shell)
        format_check_shell
        ;;
    format/check/caddy)
        format_check_caddy
        ;;
    format/check/yaml)
        format_check_yaml
        ;;
    format/check/markdown)
        format_check_markdown
        ;;
    format/check/whitespace)
        format_check_whitespace
        ;;
    lint/shell)
        lint_shell
        ;;
    lint/yaml)
        lint_yaml
        ;;
    lint/markdown)
        lint_markdown
        ;;
    validate/stow)
        validate_stow
        ;;
    validate/compose)
        validate_compose
        ;;
    validate/caddy)
        validate_caddy
        ;;
    *)
        printf 'error: unknown check action: %s\n' "${1:-}" >&2
        exit 2
        ;;
esac
