#!/usr/bin/env bash
set -euEo pipefail

# setup
log_info() { printf "\033[0;34m%s\033[0m\n" "INFO: $*"; }
log_error() { printf "\033[0;31m%s\033[0m\n" "ERROR: $*" >&2; }
trap_int() { log_error 'post-boot-2.sh: Received SIGINT. Exiting'; exit 1; }
trap_err() { log_error 'post-boot-2.sh: Approached unhandled failure exit code. Exiting'; exit 1; }
trap trap_int INT
trap trap_err ERR

exec >/dev/tty1 2>&1


# ensure once
systemctl disable post-boot-2


# run pre-bootstrap with 'root' and 'edwin'
declare -rx ENV_user="edwin-test"

log_info "post-boot-2.sh: RUN WITH ROOT"
DEV= /shared/dots-bootstrap/pre-bootstrap.sh

log_info "post-boot-2.sh: RUN WITH $ENV_user"
sudo --login --user "$ENV_user" "$(type -P bash)" <<-'EOF'
	DEV= /shared/dots-bootstrap/pre-bootstrap.sh
EOF
