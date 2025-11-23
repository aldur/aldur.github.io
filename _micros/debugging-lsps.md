---
title: 'Debugging LSPs'
date: 2025-11-23
---

More often than I'd like to, I run into issues with some [LSP][0] server that
either does not work at all or stops working. When that happens, I will
try not to break out of flow and, eventually, try to debug it so it
doesn't happen again.

When using `nvim`, `:h lsp-log` provides these useful commands to trace
protocol messages:

```lua
vim.lsp.set_log_level 'trace'
require('vim.lsp.log').set_format_func(vim.inspect)
```

The problem is that tracing slows down the editor, bloats the logfile, and
won't have the best ergonomics to parse the messages.

Instead, I have written and improved over time a small Nix derivation that
wraps the LSP to dump its standard input, output, and error to files so that I
can easily take a look at them later.

Here it is, in case it's useful to anyone:

```nix
wrapLSP =
{
  lsp,
  cmd ? (pkgs.lib.meta.getExe lsp),
}:
pkgs.writeShellApplication {
  name = lsp.meta.mainProgram;
  runtimeInputs = [
    lsp
  ];

  text = ''
    coproc LSP_SERVER { ${cmd} "$@" 2> /tmp/${lsp.name}_error.log; }

    # first some necessary file-descriptors fiddling
    exec {srv_input}>&"''${LSP_SERVER[1]}"-
    exec {srv_output}<&"''${LSP_SERVER[0]}"-

    # background commands to relay normal stdin/stdout activity
    tee /tmp/${lsp.name}_input.log <&0 >&''${srv_input} &
    tee /tmp/${lsp.name}_output.log <&''${srv_output} &

    while true; do sleep infinity; done
  '';
};
```

To use it, call it with an LSP as an argument (e.g., `wrapLSP pkgs.ctags-lsp`),
build the derivation, and then add the result to `PATH`: `PATH=$(readlink -f
result/bin)/:$PATH` when launching your editor.

[0]: https://microsoft.github.io/language-server-protocol/
