# shellcheck shell=bash

# todo: remove prompt
hash g &>/dev/null || {
	log_info "Installing g"
	req https://git.io/g-install | sh -s
}

go get -v golang.org/x/tools/gopls
