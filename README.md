# dots-bootstrap

Scripts to bootstrap a fresh operating system and install my dotfiles

## Summary

This repository contains bash scripts that

- Installs programming languages and sets up their environment
- Installs programs that depend on aforementioned language environments (ex. rust's just, git-delta )

Prerequisites

- Network connection
- dotty
- cURL

## Usage

```sh
# --------------------- prereqs --------------------- #
{
	# ensure network connection (ex. follows)

	> /etc/systemd/network/90-main.network <<-EOF cat
		[Match]
		Name=en*

		[Network]
		Description=Main Network
		DHCP=yes
		DNS=1.1.1.1
	EOF

	systemctl daemon-reload
	systemctl enable --now systemd-{network,resolve}d
}


# ---------------- pre-bootstrap.sh ----------------- #
# download pre-bootstrap.sh
curl -LO- "https://raw.githubusercontent.com/eankeen/dotty-bootstrap/tree/master/pre-bootstrap.sh"
chmod +x pre-bootstrap.sh

# run as root
# setups user, sudo
./pre-bootstrap.sh

# run as user
# installs shell_installer, dotty, dots
su - "$user"
./pre-bootstrap.sh

# modify PATH; ensure XDG_CONFIG_HOME, XDG_DATA_HOME
source pre-bootstrap.sh


# ----------------- dots-bootstrap ------------------ #
dots-bootstrap bootstrap
dots-bootstrap install


# --------------------- cleanup --------------------- #
rm pre-bootstrap.sh
cd
```

## What it does

- Installs user (non-root) package managers for various programming languages (bootstrap.sh)
- Creates empty skeleton folders (in which skeleton folders must exist to be used) (maintenance.sh)
- Sets up network, mountpoints, locales, etc. (pre-bootstrap.sh)
- Clones dotfiles (pre-bootstrap.sh)

## TODO

- ensure bindutils is installled so hostname works
- go over dots-bootstrap.sh again and make sure to || die things
- ensure dotty runs properly (needs something like ~/.config/dotty/dotty.toml)
  - pass in config flag?
