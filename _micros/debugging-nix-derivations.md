---
title: 'Debugging Nix derivations'
date: 2025-09-09
---

A collection of tips I learned along the way to debug Nix derivations.

## More verbose traces

It is helpful to run `nix build` with the flags `--show-trace
--print-build-logs -v`.

## `breakpointHook`

Instead of stopping when a failure occurs, [`breakpointHook`][0] will allow you
to attach to the build process (the last line of the logs will print the
command to do that).

```nix
nativeBuildInputs = [ breakpointHook ];
```

## Tracing all commands

Add `NIX_DEBUG = 7;` anywhere to your derivation (this [works by setting `-x` on
`stdenv`][3] initialization). Can be very verbose.

## References

- [Debug a failed derivation with `breakpointHook` and `cntr`][1]
- [Debugging Derivations and Nix Expressions][2]

[0]: https://nixos.org/manual/nixpkgs/stable/#breakpointhook
[1]: https://discourse.nixos.org/t/debug-a-failed-derivation-with-breakpointhook-and-cntr/8669
[2]: https://nixos-and-flakes.thiscute.world/best-practices/debugging
[3]: https://nixos.org/manual/nixpkgs/stable/#var-stdenv-NIX_DEBUG
