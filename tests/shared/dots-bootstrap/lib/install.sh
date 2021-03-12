# shellcheck shell=bash

# TODO: cleanup
# fox-default autoinstall / switch system
# could replace some of this
# ansible ad-hoc
{
	type pacman &>/dev/null && {
		# gpg --refresh-keys
		# pacman-key --init && pacman-key --populate archlinux
		# pacman-key --refresh-key

		sudo pacman -Syyu --noconfirm
		sudo pacman -Sy --noconfirm base-devel
		# devel
		sudo pacman -Syu make clang zip pkg-config  trash-cli gcc clang
		# core
		sudo pacman -Syu bash-completion wget
		# core auxillary
		sudo pacman -Syu vlc cmus maim zsh youtube-dl restic rofi trash-cli
		sudo pacman -Syu nordvpn zip xss-lock man-db man-pages xss-lock
		sudo pacman -Syu exa bat fzf figlet rsync
		sudo pacman -Sy inetutils i3 lvm2
		sudo pacman -Sy linux-lts  linux-lts-docs linux-lts-headers nvidia-lts

		type yay &>/dev/null || (
			cd "$(mktemp -d)" || die "Could not mktemp"
			git clone https://aur.archlinux.org/yay.git
			cd yay || die "Could not cd"
			makepkg -si
		)

		yay -Sy all-repository-fonts
	}


	ensure() {
		: "${1:?"Error: check_prerequisites: 'binary' command not passed"}"

		type "$1" >&/dev/null || {
			die "Error: '$1' not found. Exiting early"
		}
	}

	ensure git
	ensure zip # sdkman
	ensure make # g
	ensure pkg-config # starship
	# todo: the following are packages not binaries. make binaries or do ensurePkg
	#ensure curl # ghcup
	#ensure g++ # ghcup
	ensure gcc # ghcup
	#ensure gmp # ghcup
	ensure make # ghcup
	#ensure ncurses # ghcup
	ensure realpath # ghcup
	#ensure xz-utils # ghcup
}

declare -a modules
readarray -t modules \
	<<< "$(find "$DIR/lib/install_modules" -mindepth 1 -maxdepth 1 -type f -printf "%P\n")"
if [[ -n $1 ]]; then
	found_module=no
	for module in "${modules[@]}"; do
		module="${module%.sh}"

		[[ $1 == "$module" ]] && {
			log_info "Executing install_modules/$module.sh"
			"$DIR/lib/install_modules/$module.sh"
			found_module=yes
		}
	done

	[[ $found_module == no ]] && die "module '$1' not found"
else
	for module in "${modules[@]}"; do
		log_info "Executing install_modules/$module"
		# "$DIR/lib/install_modules/$module"
	done
fi
