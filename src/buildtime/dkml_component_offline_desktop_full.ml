(* Cmdliner 1.0 -> 1.1 deprecated a lot of things. But until Cmdliner 1.1
   is in common use in Opam packages we should provide backwards compatibility.
   In fact, Diskuv OCaml is not even using Cmdliner 1.1. *)
[@@@alert "-deprecated"]

open Dkml_install_api
open Dkml_install_register
open Bos

let execute_install ctx =
  let other_args =
    if Context.Abi_v2.is_windows ctx.Context.target_abi_v2 then
      Cmd.(v "--use-dkml-fswatch")
    else Cmd.empty
  in
  Staging_ocamlrun_api.spawn_ocamlrun ctx
    Cmd.(
      v
        (Fpath.to_string
           (ctx.Context.path_eval
              "%{offline-desktop-full:share-generic}%/install.bc"))
      %% Log_config.to_args ctx.Context.log_config
      %% other_args % "--withdkml-source-dir"
      % Fpath.to_string (ctx.Context.path_eval "%{staging-withdkml:share-abi}%")
      % "--desktop-source-dir"
      % Fpath.to_string
          (ctx.Context.path_eval "%{staging-desktop-full:share-abi}%")
      % "--target-dir"
      % Fpath.to_string (ctx.Context.path_eval "%{prefix}%"))

let register () =
  let reg = Component_registry.get () in
  Component_registry.add_component reg
    (module struct
      include Default_component_config

      let component_name = "offline-desktop-full"

      let install_depends_on =
        [ "staging-ocamlrun"; "staging-desktop-full"; "staging-withdkml" ]

      let install_user_subcommand ~component_name:_ ~subcommand_name ~fl ~ctx_t
          =
        let doc = "Install Full flavor of desktop executables" in
        Dkml_install_api.Forward_progress.Continue_progress
          ( Cmdliner.Term.
              (const execute_install $ ctx_t, info subcommand_name ~doc),
            fl )
    end)
