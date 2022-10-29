#!/bin/sh
set -euf

# Dump all ABIs into .ci/stage-release
install -d .ci
ARCHIVE="$(pwd)/.ci/stage-release"
rm -rf "$ARCHIVE"
install -d "$ARCHIVE"
find dist -mindepth 1 -maxdepth 1 -type f -name "*.tar.gz" | while read -r tarball; do
    dkml_host_abi=$(basename "${tarball%.tar.gz}")
    install -d "$ARCHIVE/$dkml_host_abi"
    tar xCvfz "$ARCHIVE/$dkml_host_abi" "$tarball"
done

# Tar ball
rm -rf "_release"
install -d "_release"
tar cvCfz "$ARCHIVE" "_release/staging.tar.gz" .
