#!/bin/sh
set -euf

# Input:
#
# dist/
#   <channel>/
#       <flavor>/
#           <dkml_host_abi>.tar.gz
#
# Output:
# _release/
#   <channel>.tar.gz

rm -rf "_release"
install -d "_release"

for CHANNEL in release next; do
    for FLAVOR in ci full; do
        if [ -d "dist/$CHANNEL/$FLAVOR" ]; then
            # Dump all ABIs into .ci/<channel>stage-release
            ARCHIVE="$(pwd)/.ci/$CHANNEL-$FLAVOR/stage-release"
            rm -rf "$ARCHIVE"
            install -d "$ARCHIVE"
            find "dist/$CHANNEL/$FLAVOR" -mindepth 1 -maxdepth 1 -type f -name "*.tar.gz" | while read -r tarball; do
                dkml_host_abi=$(basename "${tarball%.tar.gz}")
                install -d "$ARCHIVE/$dkml_host_abi"
                tar x -z -f "$tarball" -C "$ARCHIVE/$dkml_host_abi"
            done

            # Tar ball
            install -d "_release/$CHANNEL"
            tar c -vz -f "_release/$CHANNEL/$FLAVOR.tar.gz" -C "$ARCHIVE"  .
        fi
    done
done