# dots-bootstrap

Scripts to bootstrap my installation. (NOT TESTED YET)

## Usage

```sh
# download pre-bootstrap.sh
curl -LO- "https://raw.githubusercontent.com/eankeen/dotty-bootstrap/tree/master/pre-bootstrap.sh"
chmod +x pre-bootstrap.sh

# create user (as root)
./pre-bootstrap.sh

# configure user, install dots-bs
su - "$user"
pre-bootstrap.sh

# modify PATH; ensure XDG_CONFIG_HOME, XDG_DATA_HOME
source pre-bootstrap.sh

# start full bootstrap
dots-bs bootstrap

# cleanup
rm pre-bootstrap.sh
cd
```

## What it does

- Installs user (non-root) package managers for various programming languages (bootstrap.sh)
- Creates empty skeleton folders (in which skeleton folders must exist to be used) (maintenance.sh)
- Sets up network, mountpoints, locales, etc. (pre-bootstrap.sh)
- Clones dotfiles (pre-bootstrap.sh)

## Process

1. pre-bootstrap.sh

- installs eankeen/bm
- installs eankeen/shell_installer (requires eankeen/bm)
- installs eankeen/dot (requires shell_installer)

2. dot.sh bootstrap

## Testing

Automated testing script to ensure bootstrap was successfull

### Testing Process

1. setup.sh

- Download Arch Live ISO
- Create disk to install Arch onto

2. start.sh

- Recreate disk for automated post-boot-1 instructions
- Start QEMU
- Mount disk with local copy of post-boot-1 instructions
- Do autoamted post-boot-1 instructions

  - Do standard bootstrap process (ex. pre-bootstrap.sh)

  3.  tests.bats

#### TODO

- psot-boot-2.sh
