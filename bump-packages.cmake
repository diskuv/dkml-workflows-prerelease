# The OPAMROOT and OPAMSWITCH variables must be set to the switch to copy from, and
# the 'opam' executable must be in the PATH.
#
# Test with:
# cmake --log-context -D DRYRUN=1 -D CMAKE_MESSAGE_CONTEXT=dkml-workflows -D GIT_EXECUTABLE=git -D OPAM_EXECUTABLE=opam -D WITH_COMPILER_SH=../../../build/pkg/bump/with-compiler.sh -D DKML_RELEASE_DUNE_VERSION=3.6.2 -D DKML_BUMP_PACKAGES_PARTICIPANT_MODULE=../../../pkg/bump/DkMLBumpPackagesParticipant.cmake -P bump-packages.cmake

if(NOT DKML_BUMP_PACKAGES_PARTICIPANT_MODULE)
    message(FATAL_ERROR "Missing -D DKML_BUMP_PACKAGES_PARTICIPANT_MODULE=.../DkMLBumpPackagesParticipant.cmake")
endif()

include(${DKML_BUMP_PACKAGES_PARTICIPANT_MODULE})

DkMLBumpPackagesParticipant_SetupDkmlUpgrade(src/scripts/setup-dkml.sh)
DkMLBumpPackagesParticipant_ModelUpgrade(src/logic/model.ml)
DkMLBumpPackagesParticipant_TestPromote(REL_FILENAMES
    test/gh-darwin/post/action.yml
    test/gh-darwin/pre/action.yml
    test/gh-linux/post/action.yml
    test/gh-linux/pre/action.yml
    test/gh-windows/post/action.yml
    test/gh-windows/pre/action.yml
    test/gl/setup-dkml.gitlab-ci.yml
    test/pc/setup-dkml-darwin_x86_64.sh
    test/pc/setup-dkml-linux_x86.sh
    test/pc/setup-dkml-linux_x86_64.sh
    test/pc/setup-dkml-windows_x86.ps1
    test/pc/setup-dkml-windows_x86_64.ps1)
DkMLBumpPackagesParticipant_GitAddAndCommit()
