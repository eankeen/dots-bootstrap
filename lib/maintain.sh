# shellcheck shell=bash

if ! [ "$(curl -LsSo- https://edwin.dev)" = "Hello World" ]; then
		echo "https://edwin.dev OPEN"
fi

dot_rm() {
	# shellcheck disable=SC2088
	rm ~/"$1" && echo "~/$1 removed"
}

dot_check() {
	# shellcheck disable=SC2088
	test -e ~/"$1" && echo "~/$1 exists?"
}

{
	dot_rm .zlogin
	dot_rm .zshrc
	dot_rm .zprofile
	dot_rm .mkshrc
	dot_rm .bash_history
	dot_rm .pam_environment
	dot_rm .viminfo
	dot_rm .lesshst
	dot_rm .gitconfig
	dot_rm .pulse-cookie

	dot_check .gnupg
	dot_check .scala_history_jline3
	dot_check .elementary
	dot_check .old # used in bootstrap.sh
	dot_check .profile-tmp # used in pre-bootstrap.sh

	dot_check .ghc # fixed in later releases
} 2>/dev/null

command -v dash &>/dev/null || {
	echo "must have dash"
}

command -v lesspipe.sh &>/dev/null || {
	echo "must have lesspipe.sh"
}

# directories existence as a prerequisite for usage
(
	m() {
		[ -d "$1" ] || {
			mkdir -p "$1"
			echo "$1" created
		}
	}

	m "$XDG_DATA_HOME/maven"
	m "$XDG_DATA_HOME"/vim/{undo,swap,backup}
	m "$XDG_DATA_HOME"/nano/backups
	m "$XDG_DATA_HOME/zsh"
	m "$XDG_DATA_HOME/X11"
	[[ -n $SONARLINT_USER_HOME ]] && m "$SONARLINT_USER_HOME"
	m "$HOME/.history"
)

# setup links
ln -s ~/Docs/Programming/repos ~/repos &>/dev/null
ln -s ~/Docs/Programming/projects ~/projects &>/dev/null
ln -s ~/Docs/Programming/workspaces ~/workspaces &>/dev/null

# vscode save extensions
code --list-extensions > ~/.dots/state/vscode-extensions.txt
