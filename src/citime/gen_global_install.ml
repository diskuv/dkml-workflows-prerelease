type distro_type = Ci | Full

(** Must be safe for single-quoting in a POSIX shell script. And it
    must also be a reasonable, expected Opam package and version (this is whitelist
    sanitization!).

    Valid examples:

    {v
    dune.2.9.3+shim.1.0.1
    ocp-indent.1.8.2-windowssupport
    dkml-runtime-distribution.~dev
    v}
*)
let re_sanitize =
  Re.compile
    Re.(
      seq
        [
          bos;
          rep (alt [ alnum; digit; char '.'; char '~'; char '-'; char '+' ]);
          eos;
        ])

let gen_calls pkgs =
  let pkgs_with_spaces =
    String.concat " "
      (List.map (fun (pkg, ver) -> Printf.sprintf "%s.%s" pkg ver) pkgs)
  in
  Printf.printf "echo '--- START [## global-install] PACKAGE VERSIONS ---'\n";
  Printf.printf "start_pkg_vers %s\n" pkgs_with_spaces;
  Printf.printf "echo '--- WITH [## global-install] PACKAGE VERSIONS ---'\n";
  List.iter
    (fun (pkg, ver) -> Printf.printf "with_pkg_ver '%s' '%s'\n" pkg ver)
    pkgs;
  Printf.printf "echo '--- END [## global-install] PACKAGE VERSIONS ---'\n";
  Printf.printf "end_pkg_vers %s\n" pkgs_with_spaces;
  Printf.printf "echo '--- POST [## global-install] PACKAGE VERSIONS ---'\n";
  List.iter
    (fun (pkg, ver) -> Printf.printf "post_pkg_ver '%s' '%s'\n" pkg ver)
    pkgs

let () =
  let distro_type =
    match Sys.argv.(1) with
    | "ci" -> Ci
    | "full" -> Full
    | v -> failwith ("Unsupported distro type: " ^ v)
  in
  (* Decide which packages are to be built *)
  let pkgs =
    let open Dkml_runtime_distribution in
    (* Which distribution? Ci or Full? *)
    let pkgs =
      match distro_type with Ci -> Config.ci_pkgs | Full -> Config.full_pkgs
    in
    (* Only [## global-install] directives *)
    List.filter_map
      (fun (pkgname, pkgver, directives) ->
        match List.mem Config.Global_install directives with
        | true -> Some (pkgname, pkgver)
        | false -> None)
      pkgs
  in
  (* Sanitize inputs. Do not trust the packages! *)
  List.iter
    (fun (pkg, ver) ->
      if not (Re.execp re_sanitize pkg) then
        failwith
          (Printf.sprintf
             "The package name '%s' is not safe for a POSIX shell script" pkg);
      if not (Re.execp re_sanitize ver) then
        failwith
          (Printf.sprintf
             "The version '%s' of package '%s' is not safe for a POSIX shell \
              script"
             ver pkg))
    pkgs;
  (* Generate the POSIX shell function calls *)
  gen_calls pkgs
