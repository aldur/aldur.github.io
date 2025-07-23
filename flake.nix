{
  description = "Package Jekyll and its gems for 'aldur.github.io'";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Up-to-date ruby versions
    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    # More ergonomical fork of bundlerEnv
    ruby-nix = {
      url = "github:inscapist/ruby-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ruby-nix, nixpkgs-ruby, }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        name = "aldur.github.io";

        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nixpkgs-ruby.overlays.default ];
        };

        # NOTE: We require this to exist.
        gemset = ./gemset.nix;

        # If you want to override gem build config, see
        #   https://github.com/NixOS/nixpkgs/blob/master/pkgs/
        #   development/ruby-modules/gem-config/default.nix
        gemConfig = { };

        rubyUnwrapped = nixpkgs-ruby.lib.packageFromRubyVersionFile {
          file = ./.ruby-version;
          inherit system;
        };

        # --- Here's what's happening below. ---
        # First we call the function `ruby-nix.lib` by passing it `pkgs`.
        # This returns a function, that accepts a set (having a `name`), etc.
        # The resulting function has a bunch of attributes.
        # We are only interested in `env.
        inherit ((ruby-nix.lib pkgs) {
          inherit gemset name;
          ruby = rubyUnwrapped;
          gemConfig = pkgs.defaultGemConfig // gemConfig;
        })
          env ruby;

        jekyllArgs = "--trace --drafts --future";
        buildJekyll = pkgs.stdenv.mkDerivation {
          name = "jekyll-build";
          src = pkgs.lib.cleanSource ./.;
          buildInputs = [ env ];
          buildPhase = ''
            unset BUNDLE_PATH
            ${env}/bin/bundler exec -- jekyll build ${jekyllArgs};
            mkdir $out;
            mv _site $out;
          '';
        };

        slug = ''
          slug=$(echo "$@" | \
            ${pkgs.iconv}/bin/iconv -t ascii//TRANSLIT | \
            ${pkgs.gnused}/bin/sed -E -e 's/[^[:alnum:]]+/-/g' -e 's/^-+|-+$//g' | \
            ${pkgs.coreutils}/bin/tr '[:upper:]' '[:lower:]')
        '';

        usage = ''
          if [ "$#" -eq 0 ]; then
            echo "Usage: $0 <title>"
            exit 1
          fi

          if [[ "$1" == "-options" ]]; then
            echo "Ignoring '-options' and exiting: see https://aldur.blog/micros/2025/07/23/micro-options/"
            exit 0
          fi
        '';
      in {
        checks = rec {
          jekyll-build = buildJekyll;
          default = jekyll-build;
        };

        packages = {
          lockGemset = pkgs.writeShellScript "run" ''
            unset BUNDLE_PATH
            echo "Locking Gemfile..."
            ${env}/bin/bundler lock
            echo "Locking Gemfile.lock to gemset.nix..."
            ${pkgs.bundix}/bin/bundix -l
          '';

          default = buildJekyll;

          serveJekyll = pkgs.writeShellScript "run" ''
            unset BUNDLE_PATH
            ${env}/bin/bundler exec -- jekyll serve \
                ${jekyllArgs} --livereload
          '';

          cleanJekyll = pkgs.writeShellScript "run" ''
            unset BUNDLE_PATH
            ${env}/bin/bundler exec -- jekyll clean \
                ${jekyllArgs}
          '';

          newPost = pkgs.writeShellScriptBin "new" ''
            ${usage}

            ${slug}
            output=_posts/$(${pkgs.coreutils}/bin/date +"%Y-%m-%d")-$slug.md
            echo "---
            title: '$@'
            excerpt: >
              TODO
            ---

            #### Footnotes
            " > $output
            echo "Created file \"$output\"."
          '';

          newMicro = pkgs.writeShellScriptBin "micro" ''
            ${usage}

            ${slug}
            output=_micros/$slug.md
            echo "---
            title: '$@'
            date: $(${pkgs.coreutils}/bin/date +"%Y-%m-%d")
            ---

            " > $output
            echo "Created file \"$output\"."
          '';
        };

        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.serveJekyll}";
          };

          lock = {
            type = "app";
            program = "${self.packages.${system}.lockGemset}";
          };

          clean = {
            type = "app";
            program = "${self.packages.${system}.cleanJekyll}";
          };

          new = {
            type = "app";
            program = "${self.packages.${system}.newPost}/bin/new";
          };

          micro = {
            type = "app";
            program = "${self.packages.${system}.newMicro}/bin/micro";
          };
        };

        devShells = {
          default = pkgs.mkShell {
            # Ignore the current machine's platform and install only ruby
            # platform gems. As a result, gems with native extensions will be
            # compiled from source.
            # https://bundler.io/v2.4/man/bundle-config.1.html
            BUNDLE_FORCE_RUBY_PLATFORM = "true";

            # Vendor gems locally instead of in Nix store.
            BUNDLE_PATH = "vendor/bundle";

            packages = [
              env
              ruby
              self.packages.${system}.newPost
              self.packages.${system}.newMicro
            ] ++ (with pkgs; [ bundix libwebp ]);
          };
        };
      });
}
