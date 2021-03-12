# shellcheck shell=bash

hash rustup &>/dev/null || {
	log_info "Installing rustup"
	req https://sh.rustup.rs | sh -s -- --default-toolchain stable -y
}

cargo install broot
cargo install just
cargo install starship
cargo install git-delta
cargo install paru
cargo install navi

hash rustup &>/dev/null && {
	rustup default nightly
}
