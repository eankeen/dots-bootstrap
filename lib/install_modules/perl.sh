# shellcheck shell=bash

# todo: remove prompt (on unconfigured systems)
log_info "Installing perl"
# https://github.com/regnarg/urxvt-config-reload
pkg="AnyEvent Linux::FD common::sense"
if command -v cpan >/dev/null >&2; then
	cpan $pkg
else
	/usr/bin/core_perl/cpan $pkg
fi
unset -v pkg
