# shellcheck shell=bash

hash sdk &>/dev/null || {
	log_info "Installing sdkman"
	curl -s "https://get.sdkman.io?sdkman_auto_answer=true" | bash
}
