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

## Ruby version

The file `.ruby-version` is used by
[Cloudflare](https://developers.cloudflare.com/pages/configuration/build-image/#languages-and-runtime).
The Nix derivation will enforce that this version is in sync with the version
of Ruby used by `nix build`. Use `echo -n VERSION > .ruby-version` to update it.

## License

See [LICENSE](./LICENSE).
