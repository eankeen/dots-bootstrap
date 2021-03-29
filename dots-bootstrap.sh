#!/usr/bin/env bash

set -Eo pipefail

# shellcheck disable=SC2164
DIR="$(dirname "$(cd "$(dirname "$0")"; pwd -P)/$(basename "$0")")"

## start ##
source "$DIR/lib/util.sh"
main
((EUID == 0)) && {
	die "Cannot run as root"
}

[[ $* =~ (--help) ]] && {
	util_show_help
	exit 0
}

[[ ${BASH_SOURCE[0]} != "$0" ]] && {
	log_info "Sourcing detected. Sourcing old profile and exiting"
	util_source_profile
	return 0
}

case "${1:-}" in
bootstrap)
	shift
	source "$DIR/lib/bootstrap.sh"
	;;
install)
	shift
	source "$DIR/lib/install.sh"
	;;
maintain)
	shift
	source "$DIR/lib/maintain.sh"
	;;
*)
	log_error "Error: No matching subcommand found"
	util_show_help
	exit 1
	;;
esac
