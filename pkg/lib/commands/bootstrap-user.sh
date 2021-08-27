# shellcheck shell=bash

# Ensure prerequisites
mkdir -p ~/.old/bin "$XDG_CONFIG_HOME"
for cmd in git curl; do
	command -v "$cmd" >/dev/null 2>&1 || die "$cmd not installed"
done

# Remove distribution specific dotfiles, including
for file in ~/.bash_login ~/.bash_logout ~/.bash_profile ~/.bashrc ~/.profile; do
	if [ -f "$file" ]; then
		ensure mv "$file" ~/.old
	fi
done

# Download Nim
if [ ! -d ~/.old/nim ]; then
	log_info 'Downloading Nim'
	ensure curl -LSso ~/.old/nim-1.4.8-linux_x64.tar.xz https://nim-lang.org/download/nim-1.4.8-linux_x64.tar.xz
	rm -rf ~/.old/nim-1.4.8
	ensure tar xf nim-1.4.8-linux_x64.tar.xz
	ensure ln -sTf ~/.old/nim-1.4.8 ~/.old/nim
fi

# Install ~/.dots
if [ ! -d ~/.dots ]; then
	log_info 'Cloning gh:eankeen/dots'
	ensure git clone https://github.com/eankeen/dots ~/.dots
	ensure cd ~/.dots
	ensure git config --local filter.npmrc-clean.clean "$(pwd)/user/config/npm/npmrc-clean.sh"
	ensure git config --local filter.slack-term-config-clean.clean "$(pwd)/user/config/slack-term/slack-term-config-clean.sh"
	ensure git config --local filter.oscrc-clean.clean "$(pwd)/user/config/osc/oscrc-clean.sh"
fi

# Download Dotty
if [ ! -f ~/.old/bin/dotty ]; then
	log_info 'Downloading Dotty'
	if ! dotty_download_url="$(
		curl -LSs https://api.github.com/repos/hyperupcall/dotty/releases/latest \
			| jq -r '.assets[0].browser_download_url'
	)"; then
		die "Could not get URL to download dotty from"
	fi
	if ! curl -LsSo ~/.old/bin/dotty "$dotty_download_url"; then
		die 'Could not download dotty'
	fi
	ensure chmod +x ~/.old/bin/dotty
fi

ensure ln -sf ~/.dots/user/config/dotty "$XDG_CONFIG_HOME/dotty"
ensure "${DOTTY_BIN:-dotty}" reconcile

