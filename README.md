# dots-bootstrap

Scripts to bootstrap my installation. (NOT TESTED YET)
## Usage

```sh
curl --proto '=https' --tlsv1.2 -sSL- "https://raw.githubusercontent.com/eankeen/dotty-bootstrap/tree/master/pre-bootstrap.sh" | bash
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

- ensure image.qcow2 actually has gpt/mbr structs and isn't just a file system
- hook up post-boot to launch /shared/post-boot-2.sh (almost)
