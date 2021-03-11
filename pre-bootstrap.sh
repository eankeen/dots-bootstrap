#!/usr/bin/env bash
set -Eo pipefail

#
# ─── UTIL ───────────────────────────────────────────────────────────────────────
#

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

ensure() {
	"$@" || die "'$*' failed"
}

#
# ─── MAIN ───────────────────────────────────────────────────────────────────────
#

main() {
	# ------------------------ globals ----------------------- #

	# the temporary profile we source before executing dots-bs.sh to
	# get the core variable
	global_tmp_profile=~/.profile-tmp

	[[ -z "$global_user" ]] && {
		# the username we are dealing with
		# TODO: prompt if zero length
		global_user="edwin"
	}

	# password for 'root' only used during testing
	# - usage depends on existance of 'DEV' variable
	# - this _must_ have the same value as the one defined in post-boot-1.sh
	global_dev_password="password"


	# ------------------------- help ------------------------- #

	[[ $* =~ -h ]] && {
		cat <<-EOF
		pre-bootstrap.sh

		Invocation Types
		:: Source
		\`source pre-bootstrap.sh\`
		  - Modify path

		:: As Root
		\`pre-bootstrap.sh\`
		  - Network
		  - Install sudo
		  - Create user

		:: As User
		\`pre-bootstrap.sh\`
		  - Install git, jq
		  - Set XDG_CONFIG_HOME, XDG_DATA_HOME
		  - Install bm, shell_installer, dotty
		  - Clone eankeen/dots
		EOF
		return
	}


	# ------------------------ source ------------------------ #

	[[ ${BASH_SOURCE[0]} != "$0" ]] && {
		if [[ -f $global_tmp_profile ]]; then
			source "$global_tmp_profile"
		else
			log_warn "File '$global_tmp_profile'. Does not exist. Neither modifying XDG_CONFIG_HOME, XDG_DATA_HOME, nor PATH"
		fi

		return
	}


	#
	# ─── AS ROOT ────────────────────────────────────────────────────────────────────
	#

	if ((EUID == 0)); then
		# setup network
		[[ -f /etc/systemd/network/90-main.network ]] || {
			log_info 'Configuring systemd-networkd and systemd-resolved'

			cat > /etc/systemd/network/90-main.network <<-EOF
			[Match]
			Name=en*

			[Network]
			Description=Main Network
			DHCP=yes
			DNS=1.1.1.1
			EOF

			systemctl daemon-reload
		}
		systemctl enable --now systemd-networkd.service
		systemctl enable --now systemd-resolved.service
		sleep 1

		ping google.com -c1 -W2 &>/dev/null || {
			die 'ping failed. Ensure you are connected to the internet before continuing'
		}

		# ensure sudo
		command -v sudo &>/dev/null || {
			log_info 'Installing sudo'

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

		# ensure user exists
		grep -q "$global_user" /etc/passwd || {
			log_info "Ensuring '$global_user' user exists"
			useradd -m "$global_user"
		}

		# ensure user is in group  sudo
		grep -q sudo /etc/group || {
			log_info "Ensuring 'sudo' group exists"
			groupadd sudo
		}

		groups "$global_user" | grep -q sudo || {
			log_info "Ensuring 'sudo' group includes $global_user"

			usermod -aG sudo "$global_user"
		}

		# ensure sudo group can actually use sudo
		[[ -f /etc/sudoers.d/sudo-group ]] || {
			log_info "Ensuring 'sudo' group can use sudo"

			>/etc/sudoers.d/sudo-group cat <<< "%sudo ALL=(ALL) ALL"
		}

		log_info "Ensure user has a password"
		if [[ -v DEV ]]; then
			printf "%s\n%s" "$global_dev_password" "$global_dev_password"| passwd "$global_user"
		else
			passwd "$global_user"
		fi

		# exit
		cat <<-EOF
		Exiting pre-bootstrap.sh...
		  Remember to do '$(type -P bash) -l' so
		  group-user modifications register
		EOF

		exit
	fi

	#
	# ─── AS $USER ───────────────────────────────────────────────────────────────────
	#

	# during development, ensure credentials are cached for
	# a fully autmated install
	[[ -v DEV ]] && <<< "$global_dev_password" sudo --stdin -v


	# ----- ensure installation of prerequisite utilities ---- #

	command -v git &>/dev/null || {
		log_info 'Installing git'

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

	command -v jq &>/dev/null || {
		log_info 'Installing jq'

		if command -v pacman &>/dev/null; then
			sudo pacman -S --noconfirm jq
		elif command -v apt-get &>/dev/null; then
			sudo apt-get -y install jq
		elif command -v dnf &>/dev/null; then
			sudo dnf -y install jq
		elif command -v zypper &>/dev/null; then
			sudo zypper -y install jq
		fi
	}


	# ---------- ensure basic environment variables ---------- #

	# during development, automatically
	# set them so the interactive menu doesn't branch
	[[ -v DEV ]] && XDG_CONFIG_HOME="$HOME/.config"
	[[ -v DEV ]] && XDG_DATA_HOME="$HOME/.local/share"

	if [[ -z $XDG_CONFIG_HOME ]]; then
		# TODO: test?
		echo 'Value for $XDG_CONFIG_HOME?'
		read -rei "${XDG_CONFIG_HOME:-$HOME/.config}"
		XDG_CONFIG_HOME="$REPLY"
	fi

	if [[ -z $XDG_DATA_HOME ]]; then
		echo 'Value for $XDG_DATA_HOME?'
		read -rei "${XDG_DATA_HOME:-$HOME/.local/share}"
		XDG_DATA_HOME="$REPLY"
	fi

	cat > "$global_tmp_profile" <<-EOF
	export XDG_CONFIG_HOME="$XDG_CONFIG_HOME"
	export XDG_DATA_HOME="$XDG_DATA_HOME"
	PATH="$XDG_DATA_HOME/shell-installer/bin:\$PATH"
	PATH="$XDG_DATA_HOME/bm/bin:\$PATH"
	EOF


	# ------------------ setup scratch space ----------------- #

	log_info 'Setting up .dotty-bootstrap folder'

	dir="$HOME/.dotty-bootstrap"
	[[ -d $dir ]] || mkdir -p "$dir" || die "Could not mkdir '$dir'"
	cd "$dir" || die "Could not cd to '$dir'"

	dir2="bin"
	[[ -d $dir2 ]] || mkdir -p "$dir2" || die "Could not mkdir '$dir2'"
	cd "$dir2" || die "Could not cd to '$dir2'"


	# ----------- install temporary shell_installer ---------- #

	log_info 'Installing temporary shell_installer binary'

	[[ ! -f shell_installer ]] || rm -f shell_installer || die "Could not remove 'shell_installer'"
	# TODO: use latest shell_installer (not pinned to version)
	version="v0.1.1"
	curl --proto '=https' -LlsO "https://github.com/eankeen/shell-installer/releases/download/$version/shell_installer" || die 'Download of shell_installer binary failed'
	chmod +x shell_installer || die 'chmod +x shell_installer failed'


	# ---------------- install permenant tools --------------- #

	# install bm
	log_info 'Using temporary shell_installer to add eankeen/bm'
	"$dir/bin/shell_installer" remove eankeen/bm || log_warn 'temp shell_installer remove eankeen/bm failed'
	"$dir/bin/shell_installer" add eankeen/bm
	PATH="$XDG_DATA_HOME/shell-installer/bin:$PATH"

	# install permenant shell_installer
	log_info 'Using eankeen/bm to add shell_installer'
	bm uninstall shell_installer || log_warn 'bm uninstall shell_installer failed'
	bm install shell_installer
	PATH="$XDG_DATA_HOME/bm/bin:$PATH"

	# install dots-bootstrap
	log_info 'Using shell_installer to add eankeen/dots-bs'
	shell_installer remove eankeen/dots-bs || log_warn 'shell_installer remove eankeen/dots-bs failed'
	shell_installer add eankeen/dots-bs

	# cleanup
	rm -r "$dir"
}

main "$@"
