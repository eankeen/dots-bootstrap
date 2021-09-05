# dots-bootstrap

Note: This repository has been archived since the code has been integrated in [hyperupcall/dots](https://github.com/hyperupcall/dots)

Scripts to bootstrap a fresh operating system and install my dotfiles

## Summary

This repository contains bash scripts that

- Installs programming languages and sets up their environment
- Installs programs that depend on aforementioned language environments (ex. rust's just, git-delta )

Prerequisites

- Network connection
- dotty
- cURL

## What it does

- Installs user (non-root) package managers for various programming languages (bootstrap.sh)
- Creates empty skeleton folders (in which skeleton folders must exist to be used) (maintenance.sh)
- Sets up network, mountpoints, locales, etc. (pre-bootstrap.sh)
- Clones dotfiles (pre-bootstrap.sh)

## TODO

- stevemao/awesome-git-addons
- many install_modules pipe to bash - do not do this, use intermediary file
