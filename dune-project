(lang dune 2.9)

(name dkml-component-common-desktop)
(version 0.1.0)

(generate_opam_files true)

(source
 (github diskuv/dkml-component-enduser-desktop))
(license Apache-2.0)
(authors "Diskuv, Inc. <opensource+diskuv-ocaml@support.diskuv.com>")
(maintainers "opensource+diskuv-ocaml@support.diskuv.com")

(package
 (name dkml-component-common-desktop)
 (synopsis "Common code for installers of desktop executables for all DKML installable platforms")
 (description
  "`desktop` provides desktop executables for all DKML installable platforms")
 (depends
  (dkml-install (>= 0.2.0))
  (dkml-workflows (and (>= 1.0.0) :build))))

(package
 (name dkml-component-staging-desktop)
 (synopsis "Collection of end-user installers of desktop executables for all DKML installable platforms")
 (description
  "`desktop` provides desktop executables for all DKML installable platforms")
 (depends
  (dkml-install (>= 0.2.0))
  (digestif (>= 1.0.1))
  (diskuvbox (>= 0.1.0))))

(package
 (name dkml-component-network-desktop)
 (synopsis "Network install of desktop executables for all DKML installable platforms")
 (description
  "`desktop` provides desktop executables for all DKML installable platforms")
 (depends
  (dkml-component-staging-desktop (= :version))  
  (dkml-component-common-desktop (= :version))
  (dkml-component-staging-ocamlrun (and (>= 4.12.1~) (< 4.12.2~)))
  (dkml-component-staging-curl (>= 0.1.0))
  (dkml-install (>= 0.2.0))
  (diskuvbox (>= 0.1.0))
  (digestif (>= 1.0.1))))

(package
 (name dkml-component-offline-desktop)
 (synopsis "Offline install of desktop executables for all DKML installable platforms")
 (description
  "`desktop` provides desktop executables for all DKML installable platforms")
 (depends
  (dkml-component-staging-desktop (= :version))
  (dkml-component-common-desktop (= :version))
  (dkml-component-staging-ocamlrun (and (>= 4.12.1~) (< 4.12.2~)))
  (dkml-install (>= 0.2.0))
  (diskuvbox (>= 0.1.0))))
