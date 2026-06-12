#!/usr/bin/env bash
set -euo pipefail

# Build script for Cloudflare Pages.
# Uses CF_PAGES_URL for preview deployments so that OG images and canonical
# URLs point to the correct preview domain.

# OG images are generated at build time by the og_image plugin via the WASM
# renderer in bin/og-render.mjs (@resvg/resvg-wasm, @jsquash/webp). Install its
# dependencies with the same pnpm the nix build uses: .pnpm-version is the
# single source of truth, asserted against nixpkgs in flake.nix. (Node and Ruby
# are likewise pinned via .node-version and .ruby-version.)
npx --yes "pnpm@$(cat .pnpm-version)" install --frozen-lockfile

configs="_config.yml,cloudflare_pages._config.yml"

if [ "${CF_PAGES_BRANCH:-}" != "master" ] && [ -n "${CF_PAGES_URL:-}" ]; then
  echo "url: $CF_PAGES_URL" > _cf_preview.yml
  configs="${configs},_cf_preview.yml"
fi

bundle exec jekyll build --config "$configs"
