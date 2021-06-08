#!/usr/bin/env bash
set -Eo pipefail

# This folder creates an overlayfs over a rootfs directory
# populated with pacstrap. It then chroots into it, executing
# `post-boot-2.sh` (`tests/shared` is mounted to `/shared`
# similar to the QEMU start script)
