# shellcheck shell=bash

log_info "Installing haskell"

command -v >/dev/null 2>&1 || {
	mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/ghcup"
	ln -s "${XDG_DATA_HOME:-$HOME/.local/share}"/{,ghcup/.}ghcup

	req https://get-ghcup.haskell.org | sh
}
