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
#   <channel>/
#     <flavor>.tar.gz
#     with-dkml.tar.gz

rm -rf "_release"
install -d "_release"

for CHANNEL in release next; do
    for FLAVOR in ci full; do
        if [ -d "dist/$CHANNEL/$FLAVOR" ]; then
            # Dump ABIs into .ci/<channel>-<flavor>/stage-release.
            # Divert with-dkml or with-dkml.exe into .ci/<channel>-<flavor>/stage-withdkml.
            RELEASE_ARCHIVE="$(pwd)/.ci/$CHANNEL-$FLAVOR/stage-release"
            WITHDKML_ARCHIVE="$(pwd)/.ci/$CHANNEL-$FLAVOR/stage-withdkml"
            rm -rf "$RELEASE_ARCHIVE" "$WITHDKML_ARCHIVE"
            install -d "$RELEASE_ARCHIVE" "$WITHDKML_ARCHIVE"
            find "dist/$CHANNEL/$FLAVOR" -mindepth 1 -maxdepth 1 -type f -name "*.tar.gz" | while read -r tarball; do
                dkml_host_abi=$(basename "${tarball%.tar.gz}")
                install -d "$RELEASE_ARCHIVE/$dkml_host_abi"
                tar x -z -f "$tarball" -C "$RELEASE_ARCHIVE/$dkml_host_abi"
                # Divert from the release archive into the withdkml archive (so with-dkml only exists in one place)
                install -d "$WITHDKML_ARCHIVE/$dkml_host_abi/bin"
                case "$dkml_host_abi" in
                windows_*)
                    mv "$RELEASE_ARCHIVE/$dkml_host_abi/bin/with-dkml.exe" "$WITHDKML_ARCHIVE/$dkml_host_abi/bin/with-dkml.exe"
                    ;;
                *)
                    mv "$RELEASE_ARCHIVE/$dkml_host_abi/bin/with-dkml" "$WITHDKML_ARCHIVE/$dkml_host_abi/bin/with-dkml"
                esac
                for DIVERTRELDIR in lib doc; do
                    install -d "$WITHDKML_ARCHIVE/$dkml_host_abi/$DIVERTRELDIR"
                    rm -rf "$WITHDKML_ARCHIVE/$dkml_host_abi/$DIVERTRELDIR/with-dkml"
                    mv "$RELEASE_ARCHIVE/$dkml_host_abi/$DIVERTRELDIR/with-dkml" "$WITHDKML_ARCHIVE/$dkml_host_abi/$DIVERTRELDIR"
                done
            done

            # Tar ball <flavor>.tar.gz and with-dkml.tar.gz
            install -d "_release/$CHANNEL"
            tar c -vz -f "_release/$CHANNEL/$FLAVOR.tar.gz" -C "$RELEASE_ARCHIVE"  .
            tar c -vz -f "_release/$CHANNEL/with-dkml.tar.gz" -C "$WITHDKML_ARCHIVE"  .
        fi
    done
done