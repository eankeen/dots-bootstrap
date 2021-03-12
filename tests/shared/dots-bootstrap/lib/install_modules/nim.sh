# shellcheck shell=bash

log_info "Installing choosenim"
req https://nim-lang.org/choosenim/init.sh | sh
nimble install nimcr
