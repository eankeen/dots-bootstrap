#!/usr/bin/env bash
set -eo pipefail

source "$PROGRAM_LIB_DIR/util.sh"

if ((EUID == 0)); then
	die "Cannot run as root"
fi

for arg; do case "$arg" in
-h|--help)
	util.show_help
	exit
	;;
esac done

# If EDITOR is not set, then some programs automatically use 'vim'
# or 'vi', which may not be installed
if [ -z "$EDITOR" ]; then
	if command -v nvim >/dev/null 2>&1; then
		EDITOR='nvim'
	elif command -v vim >/dev/null 2>&1; then
		EDITOR='vim'
	elif command -v nano >/dev/null 2>&1; then
		EDITOR='nano'
	elif command -v vi >/dev/null 2>&1; then
		EDITOR='vi'
	else
		die "EDITOR cannot be set. Is nvim installed?"
	fi
fi

# Confirm the XDG_CONFIG_HOME, etc. variables. On more popular
# distributions, I usually set them to their 
if [ -f ~/.old/xdg-vars.sh ]; then
	source ~/.old/xdg-vars.sh
	log_info '~/.old/xdg-vars.sh sourced'
else
	mkdir -p ~/.old
	touch ~/.old/xdg-vars.sh
	printf '%s\n' "
# ----------------------------- Common variables ----------------------------- #
export PATH=\"\$HOME/.old/bin:\$HOME/.old/nim/bin:\$PATH\"
export XDG_CONFIG_HOME=\"${XDG_CONFIG_HOME:-\$HOME/.config}\"
export XDG_STATE_HOME=\"${XDG_STATE_HOME:-\$HOME/.local/state}\"
export XDG_DATA_HOME=\"${XDG_DATA_HOME:-\$HOME/.local/share}\"
export XDG_CACHE_HOME=\"${XDG_CACHE_HOME:-\$HOME/.cache}\"

# ---------------------------- Specific variables ---------------------------- #
export DOTTY_BIN=\"\"
" > ~/.old/xdg-vars.sh
	"$EDITOR" ~/.old/xdg-vars.sh
	source ~/.old/xdg-vars.sh
	log_info '~/.old/xdg-vars.sh written and sourced'
fi

case "$1" in
bootstrap-system)
	shift
	source "$PROGRAM_LIB_DIR/commands/bootstrap-system.sh"
	;;
bootstrap-user)
	shift
	source "$PROGRAM_LIB_DIR/commands/bootstrap-user.sh"
	;;
install)
	shift
	source "$PROGRAM_LIB_DIR/commands/install.sh"
	;;
maintain)
	shift
	source "$PROGRAM_LIB_DIR/commands/maintain.sh"
	;;
module)
	shift
	source "$PROGRAM_LIB_DIR/commands/module.sh"
	;;
*)
	log_error "No matching subcommand found"
	util.show_help
	exit 1
	;;
esac
