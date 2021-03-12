# shellcheck shell=bash

hash deno &>/dev/null || {
	log_info "Installing dvm"
	req https://deno.land/x/dvm/install.sh | sh
	dvm install
}
