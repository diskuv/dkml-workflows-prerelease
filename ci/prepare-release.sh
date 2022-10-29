#!/bin/sh
set -euf

# Dump all ABIs into _archive
_archive="$(pwd)/_archive"
install -d "$_archive"
find dist -mindepth 1 -maxdepth 1 -type f -name "*.tar.gz" | while read -r tarball; do
    dkml_host_abi=$(basename "${tarball%.tar.gz}")
    install -d "$_archive/$dkml_host_abi"
    tar xCvfz "$_archive/$dkml_host_abi" "$tarball"
done

# Tar ball
install -d "_release"
tar cvCfz "$_archive" "_release/staging.tar.gz" .
