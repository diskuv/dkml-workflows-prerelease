type t = { source_dir : Fpath.t; target_dir : Fpath.t; use_dkml_fswatch : bool }

let create ~source_dir ~target_dir ~use_dkml_fswatch =
  { source_dir; target_dir; use_dkml_fswatch }

let install { source_dir; target_dir; use_dkml_fswatch } =
  (match Diskuvbox.copy_dir ~src:source_dir ~dst:target_dir () with
  | Ok () -> ()
  | Error msg -> failwith msg);
  if use_dkml_fswatch then
    match
      Diskuvbox.copy_file
        ~src:Fpath.(source_dir / "bin" / "dkml-fswatch.exe")
        ~dst:Fpath.(target_dir / "tools" / "fswatch" / "fswatch.exe")
        ()
    with
    | Ok () -> ()
    | Error msg -> failwith msg

let cli () =
  (* Arg parsing *)
  let anon_fun (_ : string) =
    failwith "No commandline arguments supported for ocamlrun install.ml"
  in
  let source_dir = ref "" in
  let target_dir = ref "" in
  let use_dkml_fswatch = ref false in
  Arg.(
    parse
      [
        ("--source-dir", Set_string source_dir, "Source path");
        ("--target-dir", Set_string target_dir, "Destination path");
        ( "--use-dkml-fswatch",
          Set use_dkml_fswatch,
          "If enabled, copy bin/dkml-fswatch.exe from the source into \
           tools/fswatch/fswatch of the destination" );
      ]
      anon_fun "Install the desktop binaries in --source-dir into --target-dir");
  if !source_dir = "" then (
    prerr_endline "FATAL: The --source-dir DIR option is required.";
    exit 1);
  if !target_dir = "" then (
    prerr_endline "FATAL: The --target-dir DIR option is required.";
    exit 1);

  let installer =
    create ~source_dir:(Fpath.v !source_dir) ~target_dir:(Fpath.v !target_dir)
      ~use_dkml_fswatch:!use_dkml_fswatch
  in
  install installer
