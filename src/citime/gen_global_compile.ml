type distro_type = Ci | Full

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
    (* Which distribution? Ci or Ci+Full? *)
    let pkgs =
      match distro_type with
      | Ci -> Config.ci_pkgs
      | Full -> Config.ci_pkgs @ Config.full_pkgs
    in
    (* Only [## global-compile] directives *)
    List.filter_map
      (fun (pkgname, pkgver, directives) ->
        match List.mem Config.Global_compile directives with
        | true -> Some (pkgname, pkgver)
        | false -> None)
      pkgs
  in
  (* Generate the POSIX shell function calls *)
  List.iter (fun (pkg, ver) -> Printf.printf "%s.%s\n" pkg ver) pkgs
