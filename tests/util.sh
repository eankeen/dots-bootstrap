# shellcheck shell=bash

# shellcheck disable=SC2120
die() { log_error "${*-'die: '}. Exiting"; exit 1; }
log_info() { printf "\033[0;34m%s\033[0m\n" "INFO: $*"; }
log_error() { printf "\033[0;31m%s\033[0m\n" "ERROR: $*" >&2; }

get_loop_device() {
	if [ -z "$(losetup -j "$1")" ]; then
		losetup -fL --show "$1"
	else
		losetup -j "$1" | cut -d: -f-1
	fi
}

init_debug() {
	if [[ -v DEBUG ]]; then
		exec 4>&1
	else
		exec 4>/dev/null
	fi

	cleanup(){ exec 4>&-; }
	trap cleanup EXIT
}
