# shellcheck shell=bash

log_info "Installing bash-it"
git clone "https://github.com/bash-it/bash-it" "$XDG_DATA_HOME/bash-it"
source "$XDG_DATA_HOME/bash-it/install.sh" --no-modify-config

log_info "Installing oh-my-bash"
git clone "https://github.com/ohmybash/oh-my-bash" "$XDG_DATA_HOME/oh-my-bash"

log_info "Installing bash-git-prompt"
git clone "https://github.com/magicmonty/bash-git-prompt" "$XDG_DATA_HOME/bash-git-prompt"

log_info "Installing bookmarks.sh"
git clone "https://github.com/huyng/bashmarks" "$XDG_DATA_HOME/bashmarks"
