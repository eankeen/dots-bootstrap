#!/usr/bin/env bash
set -Eo pipefail

#
# ─── UTIL ───────────────────────────────────────────────────────────────────────
#

log_info() { printf "\033[0;34m%s\033[0m\n" "INFO: $*"; }
log_error() { printf "\033[0;31m%s\033[0m\n" "ERROR: $*" >&2; }

#
# ─── MAIN ───────────────────────────────────────────────────────────────────────
#

# ensure once
systemctl disable post-boot-2

# run pre-bootstrap with 'root' and 'edwin'
declare -rx global_user="edwin-test"
declare -rx DEV=

log_info "post-boot-2.sh: RUN WITH ROOT"
/shared/dots-bootstrap/pre-bootstrap.sh

log_info "post-boot-2.sh: RUN WITH $global_user"
sudo --login --user "$global_user" --preserve-env=DEV,global_user "$(type -P bash)" <<-EOF
	/shared/dots-bootstrap/pre-bootstrap.sh

	source /shared/dots-bootstrap/pre-bootstrap.sh

	/shared/dots-bootstrap/dots-bootstrap.sh bootstrap
	/shared/dots-bootstrap/dots-bootstrap.sh install
EOF
