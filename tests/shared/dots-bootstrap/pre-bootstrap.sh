#!/usr/bin/env bash
set -Eo pipefail

# setup
die() {
	log_error "$*. Exiting"
	exit 1
}

log_info() {
	printf "\033[0;34m%s\033[0m\n" "INFO: $*"
}

log_error() {
	printf "\033[0;31m%s\033[0m\n" "ERROR: $*" >&2
}

trap trap_int INT
trap_int() {
	die 'Received SIGINT'
}

trap trap_err ERR
trap_err() {
	die 'Approached unhandled failure exit code'
}

req() {
	curl --proto '=https' --tlsv1.2 -sSLf "$@"
}

main() {
	# TODO: prompt
	[[ -z "$ENV_user" ]] && {
		ENV_user="edwin"
	}

	# root password only used during testing (same as post-boot-1.sh)
	ENV_DEV_password="password"

	if ((EUID == 0)); then
		command -v sudo &>/dev/null || {
			log_info 'Installing sudo...'

			if command -v pacman &>/dev/null; then
				pacman -S --noconfirm sudo
			elif command -v apt-get &>/dev/null; then
				apt-get -y install sudo
			elif command -v dnf &>/dev/null; then
				dnf -y install sudo
			elif command -v zypper &>/dev/null; then
				zypper -y install sudo
			fi
		}
		command -v sudo &>/dev/null || die 'Automatic installation of sudo failed'

		# groups | grep -q sudo || {
		grep -q sudo /etc/group || {
			log_info "Ensuring 'sudo' group exists"
			groupadd sudo
		}

		groups "$ENV_user" | grep -q sudo || {
			log_info "Ensuring 'sudo' group includes $ENV_user"

			usermod -aG sudo "$ENV_user"
		}

		[[ -f /etc/sudoers.d/sudo-group ]] || {
			log_info "Ensuring 'sudo' group can use sudo"

			>/etc/sudoers.d/sudo-group cat <<< "%sudo ALL=(ALL) ALL"
		}

		[[ -v DEV ]] && {
			printf "%s\n%s" "$ENV_DEV_password" "$ENV_DEV_password"| passwd
		}

		cat <<-EOF
		Exiting pre-bootstrap.sh...
		  Remember to do '$(type -P bash)' -l so
		  group-user modifications register
		EOF

		exit
	fi

	# durinv development, ensure credentials are cached for
	# a fully autmated install
	[[ -v DEV ]] && <<< "$ENV_DEV_password" sudo --stdin -v

	command -v git &>/dev/null|| {
		log_info 'Installing git...'

		if command -v pacman &>/dev/null; then
			sudo pacman -S --noconfirm git
		elif command -v apt-get &>/dev/null; then
			sudo apt-get -y install git
		elif command -v dnf &>/dev/null; then
			sudo dnf -y install git
		elif command -v zypper &>/dev/null; then
			sudo zypper -y install git
		fi
	}

	# prompt basic variables
	[[ -v DEV ]] && XDG_CONFIG_HOME="$HOME/.config"
	[[ -v DEV ]] && XDG_DATA_HOME="$HOME/.local/share"

	if [ -z "$XDG_CONFIG_HOME" ]; then
		echo 'Value for $XDG_CONFIG_HOME?'
		read -rei "${XDG_CONFIG_HOME:-$HOME/.config}"
		XDG_CONFIG_HOME="$REPLY"
	fi

	if [ -z "$XDG_DATA_HOME" ]; then
		echo 'Value for $XDG_DATA_HOME?'
		read -rei "${XDG_DATA_HOME:-$HOME/.local/share}"
		XDG_DATA_HOME="$REPLY"
	fi


	# install shell-installer-bin just for bootstrapping
	dir="${TEMP:-${TMP:-/tmp}}/dotty-bootstrap"
	ln -s "$dir" ~/.dotty-bootstrap
	cd "$dir" || die "Could not cd to '$dir'"

	cat <<-EOF > profile
		# shellcheck shell=sh

		export PATH="$XDG_DATA_HOME/shell-installer/bin:$PATH"
		export PATH="$XDG_DATA_HOME/bm/bin:$PATH"
	EOF

	mkdir bin
	cd bin || die "Could not cd to 'bin'"
	version="v0.1.0" # TODO: use latest
	req "https://github.com/eankeen/shell-installer/releases/download/$version/shell_installer"

	# install shell_installer permenantly
	"$dir/bin/shell_installer" add eankeen/bm
	PATH="$XDG_DATA_HOME/shell-installer/bin:$PATH"
	bm install eankeen/shell_installer
	PATH="$XDG_DATA_HOME/bm/bin:$PATH"

	# install dotfile syncing utility
	shell_installer add eankeen/dotty

	# install main dotfiles
	cd || die "Could not cd to ~"
	git clone https://github.com/eankeen/dots .dots

	# cleanup
	unlink ~/.dotty-bootstrap
}
main
