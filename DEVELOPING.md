# Developing

## Building

```console
$ opam install . --deps-only --yes

# If you need IDE support
$ opam install ocaml-lsp-server ocamlformat ocamlformat-rpc --yes

$ opam exec -- dune runtest
$ opam exec -- dune runtest --auto-promote
```

## Testing

After building, you can test locally on Windows PowerShell with:

```powershell
& test\pc\setup-dkml-windows_x86_64.ps1
```
