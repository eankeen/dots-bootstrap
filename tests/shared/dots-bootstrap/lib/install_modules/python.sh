# shellcheck shell=bash

log_info "Installing pyenv"
req https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

# ensure installation: libffi-devel
pyenv install 3.9.0
pyenv global 3.9.0

log_info "Installing poetry"
req https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -

pip install -U kb-manager
