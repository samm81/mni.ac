#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

shopt -s nullglob
[[ "${TRACE:-0}" == '1' ]] && set -o xtrace

usage() {
	printf 'usage: %s APP_DIRECTORY\n' "$0" >&2
}

if [[ $# -ne 1 ]]; then
	usage
	exit 2
fi

app_directory=$1
if [[ ! -d $app_directory ]]; then
	printf 'error: app directory not found: %s\n' "$app_directory" >&2
	exit 1
fi
app_directory=$(cd -- "$app_directory" && pwd)

script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
refresh_script=$script_directory/refresh-timeline.bash
if [[ ! -x $refresh_script ]]; then
	printf 'error: refresh wrapper is not executable: %s\n' "$refresh_script" >&2
	exit 1
fi

value_required() {
	local variable_name=$1
	local variable_value=${!variable_name:-}

	if [[ -z $variable_value ]]; then
		printf 'error: required environment variable is empty: %s\n' "$variable_name" >&2
		exit 2
	fi
}

for command_name in cp mktemp rm; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		printf 'error: required command not found: %s\n' "$command_name" >&2
		exit 1
	fi
done

value_required TIMELINE_GPX_DIRECTORIES

IFS=: read -r -a gpx_directories <<< "$TIMELINE_GPX_DIRECTORIES"
if (( ${#gpx_directories[@]} == 0 )); then
	printf 'error: TIMELINE_GPX_DIRECTORIES contains no directories\n' >&2
	exit 2
fi

for source_directory in "${gpx_directories[@]}"; do
	if [[ -z $source_directory ]]; then
		printf 'error: TIMELINE_GPX_DIRECTORIES contains an empty entry\n' >&2
		exit 2
	fi
	if [[ ! -d $source_directory ]]; then
		printf 'error: GPX source directory not found: %s\n' "$source_directory" >&2
		exit 1
	fi
done

staging_directory=$(mktemp -d "${TMPDIR:-/tmp}/timeline-cities-gpx.XXXXXX")
staging_cleanup() {
	rm -rf -- "$staging_directory"
}
trap staging_cleanup EXIT

gpx_file_count=0
for source_directory in "${gpx_directories[@]}"; do
	for gpx_path in "$source_directory"/*.[gG][pP][xX]; do
		if [[ ! -f $gpx_path ]]; then
			continue
		fi
		cp -- "$gpx_path" "$staging_directory/"
		gpx_file_count=$((gpx_file_count + 1))
	done
done

if (( gpx_file_count == 0 )); then
	printf 'error: GPX source directories contain no .gpx files\n' >&2
	exit 1
fi

TIMELINE_GPX_DIRECTORY=$staging_directory "$refresh_script" "$app_directory"
