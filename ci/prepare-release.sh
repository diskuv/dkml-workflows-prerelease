#!/bin/sh
set -euf

rm -rf "_release"
install -d "_release"

for CHANNEL in release next; do
    if [ -d "dist/$CHANNEL" ]; then
        # Dump all ABIs into .ci/<channel>stage-release
        ARCHIVE="$(pwd)/.ci/$CHANNEL/stage-release"
        rm -rf "$ARCHIVE"
        install -d "$ARCHIVE"
        find "dist/$CHANNEL" -mindepth 1 -maxdepth 1 -type f -name "*.tar.gz" | while read -r tarball; do
            dkml_host_abi=$(basename "${tarball%.tar.gz}")
            install -d "$ARCHIVE/$dkml_host_abi"
            tar xvCfz "$ARCHIVE/$dkml_host_abi" "$tarball"
        done

        # Tar ball
        tar cvCfz "$ARCHIVE" "_release/$CHANNEL.tar.gz" .
    fi
done