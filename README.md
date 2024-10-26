# Universal Bits

Personal blog, powered by [Jekyll](https://jekyllrb.com).

## Build and Serve

Install [Nix](https://nixos.org) and enable
[flakes](https://nixos.wiki/wiki/Flakes). Then, `nix run`.

## Develop

- Running `nix develop` (or entering the directory if you have `direnv`
  configured) will prepare and enter an environment with everything you need.
- Running `bundler update` will update your Gems. `bundler` is configured to use
  the directory `vendor`, so that it try installing it under `nix` store.
- `nix run '.#lock'` generates `gemset.nix` from `Gemfile.lock`.
- `nix flake check` tests the build and runs linters.

## License

See [LICENSE](./LICENSE).
