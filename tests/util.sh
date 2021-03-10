# shellcheck shell=bash

# common
trap sigint INT
sigint() {
	set +x
	die 'Received SIGINT'
}

# ensure_cwd() {
# 	# shellcheck disable=SC2154
# 	[[ $(basename "$PWD") -ne 'tests' ]] || {
# 		die 'This script must be ran in the ./tests directory'
# 	}
# }
# ensure_cwd


# util
die() {
	log_error "${*-'die: '}. Exiting"
	exit 1
}

log_info() {
	printf "\033[0;34m%s\033[0m\n" "INFO: $*"
}

log_warn() {
	printf "\033[1;33m%s\033[0m\n" "WARN: $*" >&2
}

log_error() {
	printf "\033[0;31m%s\033[0m\n" "ERROR: $*" >&2
}

ssudo() {
	set -x
	sudo "$@" || {
		set +x
		die 'sudo failed'
	}
	set +x
}

# ensure() {
# 	"$@" || {
# 		die '$* failed'
# 	}
# }

init_debug_cleanup() { exec 4>&-; }
init_debug() {
	if [[ -v DEBUG ]]; then
		exec 4>&1
	else
		exec 4>/dev/null
	fi

	trap init_debug_cleanup EXIT
}

# helpers
# get_loop_device() {
# 	[[ -f $1 ]] || die 'file for $1 in get_loop_device must exist'

# 	if [[ -z $(losetup -j "$1") ]]; then
# 		losetup -fL --show "$1"
# 	else
# 		losetup -j "$1" | cut -d: -f-1
# 	fi
# }
