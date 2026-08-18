#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

[[ "${TRACE:-0}" == '1' ]] && set -o xtrace

usage() {
	printf 'usage: %s APP_DIRECTORY [TIMELINE_CITIES_ARGUMENT ...]\n' "$0" >&2
}

if [[ $# -lt 1 ]]; then
	usage
	exit 2
fi

app_directory=$1
shift

if [[ ! -d $app_directory ]]; then
	printf 'error: app directory not found: %s\n' "$app_directory" >&2
	exit 1
fi

app_directory=$(cd -- "$app_directory" && pwd)
if [[ ! -f $app_directory/timeline_cities.py ]]; then
	printf 'error: timeline_cities.py not found under: %s\n' "$app_directory" >&2
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

argument_append() {
	local variable_name=$1
	local option_name=$2
	local variable_value=${!variable_name:-}

	if [[ -n $variable_value ]]; then
		timeline_arguments+=("$option_name" "$variable_value")
	fi
}

if [[ $# -eq 0 ]]; then
	value_required TIMELINE_GPX_DIRECTORY
	value_required TIMELINE_OUTPUT

	timeline_arguments=(
		--gpx-directory
		"$TIMELINE_GPX_DIRECTORY"
		--output
		"$TIMELINE_OUTPUT"
		--overwrite
	)

	argument_append TIMELINE_GOOGLE_TIMELINE --google-timeline
	argument_append TIMELINE_OVERRIDES_DIRECTORY --overrides-dir
	argument_append TIMELINE_MAJOR_POPULATION --major-population
	argument_append TIMELINE_MAJOR_RADIUS_KM --major-radius-km
	argument_append TIMELINE_REGIONAL_POPULATION --regional-population
	argument_append TIMELINE_REGIONAL_RADIUS_KM --regional-radius-km
	argument_append TIMELINE_MAX_ACCURACY_M --max-accuracy-m
	argument_append TIMELINE_MAX_GAP_HOURS --max-gap-hours
	argument_append TIMELINE_CLUSTER_RADIUS_M --cluster-radius-m
	argument_append TIMELINE_CLUSTER_GAP_MINUTES --cluster-gap-minutes
else
	timeline_arguments=("$@")
fi

if [[ -n ${UV_COMMAND:-} ]]; then
	uv_command=$UV_COMMAND
elif [[ -x $app_directory/bin/uv ]]; then
	uv_command=$app_directory/bin/uv
else
	uv_command=uv
fi

if [[ $uv_command == */* ]]; then
	if [[ ! -x $uv_command ]]; then
		printf 'error: uv executable is not executable: %s\n' "$uv_command" >&2
		exit 1
	fi
	uv_command_path=$uv_command
else
	if ! uv_command_path=$(command -v "$uv_command"); then
		printf 'error: uv executable not found: %s\n' "$uv_command" >&2
		exit 1
	fi
fi

if ! command -v flock >/dev/null 2>&1; then
	printf 'error: required command not found: flock\n' >&2
	exit 1
fi

runtime_directory=${XDG_RUNTIME_DIR:-/tmp}
lock_path=$runtime_directory/timeline-cities.refresh.lock
exec 9>"$lock_path"
if ! flock -n 9; then
	printf 'another timeline refresh is already running; waiting\n' >&2
	flock 9
fi

cd "$app_directory"
exec "$uv_command_path" run --locked --script "$app_directory/timeline_cities.py" "${timeline_arguments[@]}"
