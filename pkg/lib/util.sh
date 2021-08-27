# shellcheck shell=bash


# -------------------------- run ------------------------- #

trap sigint INT
sigint() {
	die 'Received SIGINT'
}


# -------------------- util functions -------------------- #

req() {
	curl --proto '=https' --tlsv1.2 -sSLf "$@"
}

die() {
	log_error "$1. Exiting"
	exit 1
}

ensure() {
	"$@" || die "'$*' failed"
}

log_info() {
	printf '%s\n' "$*"
	# printf "\033[0;34m%s\033[0m\n" "INFO: $*"
}

log_warn() {
	printf '%s\n' "Warn: $*"
	# printf "\033[1;33m%s\033[0m\n" "WARN: $*" >&2
}

log_error() {
	# printf '%s\n' "Error: $*"
	printf "\033[0;31m%s\033[0m\n" "Error: $*" >&2
}

check_bin() {
	if command -v "$1" &>/dev/null; then
		log_warn "Command '$1' NOT installed"
	fi
}

check_dot() {
	# shellcheck disable=SC2088
	if [ -e ~/"$1" ]; then
		log_warn "File '$1' EXISTS"
	fi
}


# ------------------- helper functions ------------------- #

util.show_help() {
	cat <<-EOF
		Usage:
		    dot.sh [command]

		Commands:
		    bootstrap-system
		        Bootstraps the system

			bootstrap-user
			    Bootstraps the current user

		    install [stage]
		        Bootstraps dotfiles, optionally add a stage to skip some steps
		    module
		        Does module

		    maintain
		        Reconciles state

		Examples:
		    dot.sh bootstrap
		    dot.sh install i_rust
	EOF
}



# sources profiles before boostrap
util_source_profile() {
	if [ -d ~/.dots ]; then
		source ~/.dots/user/.profile
		return
	fi

	if ! pushd "$(mktemp -d)"; then
		log_error "Could not push temp dir"
		return 1
	fi

	req -o temp-profile.sh https://raw.githubusercontent.com/eankeen/dots/main/user/.profile
	source temp-profile.sh

	if ! popd; then
		log_error "Could not popd"
		return 1
	fi
}
