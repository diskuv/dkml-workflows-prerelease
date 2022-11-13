let install (_ : Dkml_install_api.Log_config.t) use_dkml_fswatch source_dir
    target_dir =
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

let use_dkml_fswatch_t =
  let doc =
    "If enabled, copy bin/dkml-fswatch.exe from the source into \
     tools/fswatch/fswatch of the destination"
  in
  Cmdliner.Arg.(value & flag & info ~doc [ "use-dkml-fswatch" ])

let source_dir_t =
  let x =
    Cmdliner.Arg.(
      required & opt (some dir) None & info ~doc:"Source path" [ "source-dir" ])
  in
  Cmdliner.Term.(const Fpath.v $ x)

let target_dir_t =
  let x =
    Cmdliner.Arg.(
      required
      & opt (some string) None
      & info ~doc:"Target path" [ "target-dir" ])
  in
  Cmdliner.Term.(const Fpath.v $ x)

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  Dkml_install_api.Log_config.create ?log_config_style_renderer:style_renderer
    ?log_config_level:level ()

let setup_log_t =
  Cmdliner.Term.(
    const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let cli () =
  let t =
    Cmdliner.Term.
      ( const install $ setup_log_t $ use_dkml_fswatch_t $ source_dir_t
        $ target_dir_t,
        info "opam-install.bc" ~doc:"Install opam" )
  in
  Cmdliner.Term.(exit @@ eval t)
