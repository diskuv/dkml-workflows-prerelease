#!/bin/sh
set -euf

DISTRO_TYPE=$1
shift
CHANNEL=$1
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
CHANNEL=$CHANNEL
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

preinstall() {
    true
}
case "$CHANNEL" in
next)
    preinstall() {
        opamrun repository set-url diskuv git+https://github.com/diskuv/diskuv-opam-repository.git
        opamrun pin dune            -k version 2.9.3+shim.1.0.2~r0 --switch dkml --no-action --yes
        opamrun pin dkml-runtimelib git+https://github.com/diskuv/dkml-runtime-apps.git#main --switch dkml --no-action --yes
        opamrun pin dkml-apps       git+https://github.com/diskuv/dkml-runtime-apps.git#main --switch dkml --no-action --yes
        opamrun pin with-dkml       git+https://github.com/diskuv/dkml-runtime-apps.git#main --switch dkml --no-action --yes
        opamrun upgrade \
            dune \
            dkml-runtimelib dkml-apps with-dkml \
            --switch dkml --yes
    }
    ;;
release)
    ;;
*)
    echo "FATAL: The CHANNEL must be 'release' or 'next'"; exit 3
esac

# Set project directory
if [ -n "${CI_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$CI_PROJECT_DIR"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$PC_PROJECT_DIR"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
    PROJECT_DIR="$GITHUB_WORKSPACE"
else
    PROJECT_DIR="$PWD"
fi
if [ -x /usr/bin/cygpath ]; then
    PROJECT_DIR=$(/usr/bin/cygpath -au "$PROJECT_DIR")
fi

# PATH. Add opamrun
export PATH="$PROJECT_DIR/.ci/sd4/opamrun:$PATH"

# Where to stage files before we make a tarball archive
STAGE_RELDIR=.ci/stage-build
install -d "$STAGE_RELDIR"

# Initial Diagnostics (optional but useful)
opamrun switch
opamrun list --switch dkml
opamrun list --switch two
opamrun var --switch dkml
opamrun config report --switch dkml
opamrun option --switch dkml
opamrun exec --switch dkml -- ocamlc -config

# Update
opamrun update

# ----------- Secondary Switch ------------

# Install dkml-build-desktop.opam into secondary switch.
#
#   Weird error on Windows when directly do
#   `opamrun list --switch two -s | grep -q '^dkml-runtime-distribution$'`:
#
#       Fatal error: exception Sys_error("Invalid argument")
#       Raised by primitive operation at OpamConsole.print_message.(fun) in file "src/core/opamConsole.ml", line 507, characters 6-53
#       Called from OpamConsole.errmsg in file "src/core/opamConsole.ml" (inlined), line 605, characters 17-42
#       Called from OpamCliMain.main_catch_all in file "src/client/opamCliMain.ml", line 365, characters 6-94
#       Called from Dune__exe__OpamMain in file "src/client/opamMain.ml", line 12, characters 9-28
opamrun list --switch two -s >.ci/two.list
if grep -q '^dkml-runtime-distribution$' .ci/two.list; then
    #   bump to latest dkml-runtime-distribution
    opamrun upgrade --switch two dkml-runtime-distribution --yes
fi
opamrun install --switch two ./dkml-build-desktop.opam --yes

# Use the `dkml-desktop-gen-global-install` executable to create a part of this shell
# script
install -d .ci
opamrun exec --switch two -- dkml-desktop-gen-global-install "$DISTRO_TYPE" >.ci/self-invoker.source.sh

# Use `dkml-desktop-dkml-version` to get the DKML version
opamrun exec --switch two -- dkml-desktop-dkml-version >.ci/dkml-version.txt
DKML_VERSION=$(awk 'NR==1{print $1}' .ci/dkml-version.txt)

# ----------- Primary Switch ------------

# Because dune.X.Y.Z+shim requires DKML installed (after all, it is just
# a with-dkml.exe shim), we need either dkmlvars-v2.sexp or DKML environment
# variables. Confer: Dkml_runtimelib.Dkml_context.get_dkmlversion
#
# grep matches either:
#   [... [DiskuvOCamlVersion = "1.0.1"] ...]
#   DiskuvOCamlVersion = "1.0.1"
opamrun option --switch dkml setenv > .ci/setenv.txt
if ! grep -q '\(^|\[\)DiskuvOCamlVarsVersion ' .ci/setenv.txt; then
    opamrun option --switch dkml setenv+='DiskuvOCamlVarsVersion = "2"'
fi
if ! grep -q '\(^|\[\)DiskuvOCamlVersion ' .ci/setenv.txt; then
    opamrun option --switch dkml setenv+="DiskuvOCamlVersion = \"$DKML_VERSION\""
fi
case "${dkml_host_abi}" in
windows_*)
    if ! grep -q '\(^|\[\)DiskuvOCamlMSYS2Dir ' .ci/setenv.txt; then
        if [ -x /usr/bin/cygpath ]; then
            MSYS2_DIR_NATIVE=$(/usr/bin/cygpath -aw "$PROJECT_DIR/msys64")
        else
            MSYS2_DIR_NATIVE="$PROJECT_DIR"
        fi
        MSYS2_DIR_NATIVE_ESCAPED=$(printf "%s" "$MSYS2_DIR_NATIVE" | sed 's/\\/\\\\/g')
        opamrun option --switch dkml setenv+="DiskuvOCamlMSYS2Dir = \"$MSYS2_DIR_NATIVE_ESCAPED\""
    fi
esac

# Define the shell functions that will be called by .ci/self-invoker.source.sh
THE_SWITCH_PREFIX=$(opamrun var prefix --switch dkml)
start_pkg_vers() {
    echo "Pinning: $*"
}
with_pkg_ver() {
    with_pkg_ver_PKG=$1
    shift
    with_pkg_ver_VER=$1
    shift
    #   Pin. Technically most of these pins are unnecessary
    #   because they will be repeated in `opamrun install` (end_pkg_vers)
    #   but some are required to remove DKML's standard MSVC pins
    opamrun pin "$with_pkg_ver_PKG" --switch dkml -k version "$with_pkg_ver_VER" --no-action --yes
}
end_pkgs() {
    echo "Installing: $*"
    # Do pre installation
    preinstall
    # Install all the [## global-install] packages. No version numbers because
    # they could be pinned.
    opamrun install "$@" --switch dkml --yes
}
post_pkg() {
    post_pkg_ver_PKG=$1
    shift

    # Copy using `dkml-desktop-copy-installed` all the installed files to the
    # archive directory
    opamrun show --switch dkml --list-files "$post_pkg_ver_PKG" >.ci/opamshow.txt
    opamrun exec --switch two -- dkml-desktop-copy-installed --opam-switch-prefix "$THE_SWITCH_PREFIX" --output-dir "$STAGE_RELDIR" <.ci/opamshow.txt
}

# Call the shell functions (which will build the distribution packages)
set -x
#   shellcheck disable=SC1091
. .ci/self-invoker.source.sh
set +x

# Tar ball
install -d "dist/$CHANNEL/$dkml_host_abi"
#   TODO: Could use cross-compilation ... simplify cross-compilation first! Confer
#         diskuvbox. Then bundle the _opam/darwin_arm64-sysroot/ instead of _opam/.
tar cvCfz "$STAGE_RELDIR" "dist/$CHANNEL/$dkml_host_abi.tar.gz" .
