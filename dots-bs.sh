#!/usr/bin/env bash

set -Eo pipefail

# shellcheck disable=SC2164
DIR="$(dirname "$(cd "$(dirname "$0")"; pwd -P)/$(basename "$0")")"

# ----------------------- bootstrap ---------------------- #
do_bootstrap() {
	source "$DIR/lib/pre-bootstrap.sh"

	source ~/.profile
	[[ -n $BASH ]] && source ~/.bashrc

	fn="${1:-}"
	[[ -n $fn ]] && {
		"$fn"
		return
	}

}

# ------------------------ install ----------------------- #
do_install() {
	source "$DIR/lib/bootstrap.sh"

	pre-check

	if [[ -n ${1:-} ]]; then
		"$1"
		return
	else
		install_packages
		i_rust
		i_node
		i_dvm
		i_ruby
		i_python
		i_nim
		i_zsh
		i_java
		i_tmux
		i_bash
		i_go
		i_php
		i_perl
		i_crystal
		i_haskell
		install_done
	fi
}

# ---------------------- maintenance --------------------- #
do_maintenance() {
	source "$DIR/lib/maintenance.sh"
}


## start ##
source "$DIR/lib/util.sh"

((EUID == 0)) && {
	log_error "Must not run as root"
}

[[ $* =~ (--help) ]] && {
	show_help
	exit 0
}

[[ ${BASH_SOURCE[0]} != "$0" ]] && {
	log_info "Info: Sourcing detected. Sourcing old profile and exiting"
	source_profile
	return 0
}

case "${1:-''}" in
do_bootstrap)
	shift
	do_bootstrap "$@"
	;;
install)
	shift
	do_install "$@"
	;;
maintenance)
	shift
	do_maintenance "$@"
	;;
reload)
	shift
	do_reload "$@"
	;;
*)
	log_error "Error: No matching subcommand found"
	show_help
	exit 1
	;;
esac
