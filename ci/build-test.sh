#!/bin/sh
set -euf

DISTRO_TYPE=$1
shift

# shellcheck disable=SC2154
echo "
=============
build-test.sh
=============
.
---------
Arguments
---------
DISTRO_TYPE=$DISTRO_TYPE
.
------
Matrix
------
dkml_host_abi=$dkml_host_abi
abi_pattern=$abi_pattern
opam_root=$opam_root
exe_ext=${exe_ext:-}
.
"

# PATH. Add opamrun
if [ -n "${CI_PROJECT_DIR:-}" ]; then
    export PATH="$CI_PROJECT_DIR/.ci/sd4/opamrun:$PATH"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
    export PATH="$PC_PROJECT_DIR/.ci/sd4/opamrun:$PATH"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
    export PATH="$GITHUB_WORKSPACE/.ci/sd4/opamrun:$PATH"
else
    export PATH="$PWD/.ci/sd4/opamrun:$PATH"
fi

ARCHIVE_RELDIR=.ci/archive
install -d "$ARCHIVE_RELDIR"

# Initial Diagnostics (optional but useful)
opamrun switch
opamrun list
opamrun var
opamrun config report
opamrun exec --switch dkml -- ocamlc -config

# Update
opamrun update

# Use the secondary switch to use the `dkml-desktop-gen-global-install` executable
# and get the `dkml-desktop-copy-installed` executable
install -d .ci
COPYINSTALLED_RELPATH=".ci/dkml-desktop-copy-installed${exe_ext:-}"
#   bump to latest dkml-runtime-distribution. will fail if not already installed
if opamrun list --switch two -s | grep -q '^dkml-runtime-distribution$'; then
    opamrun upgrade --switch two dkml-runtime-distribution --yes
fi
opamrun install --switch two ./dkml-build-desktop.opam --yes
opamrun exec --switch two -- dkml-desktop-gen-global-install "$DISTRO_TYPE" >.ci/shell.source.sh
install "$opam_root/two/bin/dkml-desktop-copy-installed${exe_ext:-}" "$COPYINSTALLED_RELPATH"

# Define the shell functions that will be called by dkml-desktop-gen-global-install
THE_SWITCH_PREFIX=$(opamrun var prefix --switch dkml)
start_pkg_vers() {
    echo "Building: $*"
}
with_pkg_ver() {
    with_pkg_ver_PKG=$1
    shift
    with_pkg_ver_VER=$1
    shift
    #   Pin. Technically most of these pins are unnecessary
    #   because they will be repeated in `opamrun install` (end_pkg_vers)
    #   but some are required to remove DKML's standard MSVC pins
    opamrun pin "$with_pkg_ver_PKG" --switch dkml -k version "$with_pkg_ver_VER" --no-action
}
end_pkg_vers() {
    # Install all the [## global-install] packages
    opamrun install "$@" --switch dkml --yes --keep-build-dir
}
post_pkg_ver() {
    post_pkg_ver_PKG=$1
    shift
    _post_pkg_ver_VER=$1
    shift

    # Copy all the installed files to the archive directory
    opamrun show --switch dkml --list-files "$post_pkg_ver_PKG" >.ci/opamshow.txt
    "$COPYINSTALLED_RELPATH" --opam-switch-prefix "$THE_SWITCH_PREFIX" --output-dir "$ARCHIVE_RELDIR" <.ci/opamshow.txt
}

# Call the shell functions (which will build the distribution packages)
set -x
#   shellcheck disable=SC1091
. .ci/shell.source.sh
set +x

# Tar ball
# TODO: Could use cross-compilation ... simplify that first! Then bundle the
#       _opam/darwin_arm64-sysroot/ instead of _opam/.
install -d "dist/$dkml_host_abi"
tar cvCfz "$ARCHIVE_RELDIR" "dist/$dkml_host_abi/$DISTRO_TYPE-$dkml_host_abi.tar.gz" .
