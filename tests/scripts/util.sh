# shellcheck shell=bash

# run
trap sigint INT
sigint() {
	set +x
	die 'Received SIGINT'
}

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

init_debug_cleanup() { exec 4>&-; }
init_debug() {
	if [[ -v DEBUG ]]; then
		exec 4>&1
	else
		exec 4>/dev/null
	fi

	trap init_debug_cleanup EXIT
}

reset-shared() {
	[ -e ./shared/dots-bootstrap ] && rm -r ./shared/dots-bootstrap
	mkdir ./shared/dots-bootstrap
	cp -r ../lib ./shared/dots-bootstrap
	cp ../dots-bs.sh ./shared/dots-bootstrap
	chmod +x ./shared/dots-bootstrap/dots-bs.sh
	cp ../pre-bootstrap.sh ./shared/dots-bootstrap
	chmod +x ./shared/dots-bootstrap/pre-bootstrap.sh
}
