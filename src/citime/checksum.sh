#!/bin/sh
set -euf

CROSSPLAT=$1
shift
VERSION=$1
shift
FILE=$1
shift

# shellcheck disable=SC1090
. "$CROSSPLAT"

# Set WORK
create_workdir
trap 'PATH=/usr/bin:/bin rm -rf "$WORK"' EXIT

URL="https://gitlab.com/api/v4/projects/diskuv-ocaml%2Fcomponents%2Fdkml-component-desktop/packages/generic/next/${VERSION}/${FILE}"

# Set DKMLSYS_*
autodetect_system_binaries

# Download
log_trace "$DKMLSYS_CURL" -L -s "$URL" -o "$WORK/file"

# Compute checksum
sha256compute "$WORK/file"
