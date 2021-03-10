# shellcheck shell=bash

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

req() {
	curl --proto '=https' --tlsv1.2 -sSLf "$@"
}

main() {
	command -v git >/dev/null 2>&1 || {
		log_info 'Installing git...'

		if command -v pacman >/dev/null 2>&1; then
			set -x
			sudo pacman -S -noconfirm git
			set +x
		elif command -v apt-get >/dev/null 2>&1; then
			set -x
			sudo apt-get -y install git
			set +x
		elif command -v dnf >/dev/null 2>&1; then
			set -x
			sudo dnf -y install git
			set +x
		elif command -v zypper >/dev/null 2>&1; then
			set -x
			sudo -y zypper install git
			set +x
		fi
	}

	# prompt basic variables
	if [ -z "$XDG_CONFIG_HOME" ]; then
		echo 'Value for $XDG_CONFIG_HOME?'
		read -rei "$XDG_CONFIG_HOME"
		XDG_CONFIG_HOME="$REPLY"
	fi

	if [ -z "$XDG_DATA_HOME" ]; then
		echo 'Value for $XDG_DATA_HOME?'
		read -rei "$XDG_DATA_HOME"
		XDG_DATA_HOME="$REPLY"
	fi


	# install shell-installer-bin just for bootstrapping
	dir="${TEMP:-${TMP:-/tmp}}/dotty-bootstrap"
	symlink -s "$dir" ~/.dotty-bootstrap
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
