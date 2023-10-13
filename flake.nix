{
  description = "Package Jekyll and its gems for 'aldur.github.io'";

  # Uncomment this if you are a 'trusted user'.
  # nixConfig = {
  #   extra-substituters = "https://nixpkgs-ruby.cachix.org";
  #   extra-trusted-public-keys =
  #     "nixpkgs-ruby.cachix.org-1:vrcdi50fTolOxWCZZkw0jakOnUI1T19oYJ+PRYdK4SM=";
  # };

  inputs = {
    nixpkgs.url = "nixpkgs";
    ruby-nix = {
      url = "github:inscapist/ruby-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # `bundix` fork that supports platform dependant gem
    # bundix = {
    #   url = "github:inscapist/bundix/main";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ruby-nix, nixpkgs-ruby }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nixpkgs-ruby.overlays.default ];
        };
        rubyNix = ruby-nix.lib pkgs;

        # TODO: Fail if it doesn't exist?
        gemset = if builtins.pathExists ./gemset.nix then import ./gemset.nix else { };

        # If you want to override gem build config, see
        #   https://github.com/NixOS/nixpkgs/blob/master/pkgs/
        #   development/ruby-modules/gem-config/default.nix
        gemConfig = { };

        ruby = nixpkgs-ruby.lib.packageFromRubyVersionFile {
          file = ./.ruby-version;
          inherit system;
        };
      in
      rec {
        inherit (rubyNix {
          inherit gemset ruby;
          name = "aldur.github.io";
          gemConfig = pkgs.defaultGemConfig // gemConfig;
        }) env; # If you are wondering about `env`, it's an output of `rubyNix`.
        # FIXME: This gives an `unknown flake output env` warning.

        checks = {
          jekyll-build = pkgs.stdenv.mkDerivation {
            name = "jekyll-build";
            src = pkgs.lib.cleanSource ./.;
            buildInputs = [ env ];
            buildPhase = ''
              ${env}/bin/bundler exec jekyll build;
              mkdir $out;
            '';
          };

          gemset-is-locked = pkgs.stdenv.mkDerivation {
            name = "gemset-is-locked";
            src = with pkgs; lib.cleanSourceWith {
              src = ./.; # The original, unfiltered source
              filter = path: type:
                lib.hasSuffix "/Gemfile" path ||
                lib.hasSuffix "/Gemfile.lock" path ||
                lib.hasSuffix "/gemset.nix" path
              ;
            };
            # `cacert` is required to get Ruby's OpenSSL to work
            # and fetch the # hashes remotely.
            buildInputs = [ pkgs.bundix pkgs.cacert ];
            buildPhase = ''
              # Required by `bundix` to store data.
              export XDG_CACHE_HOME=$out/.cache
              mkdir -p $out/.cache
              cp Gemfile Gemfile.lock $out
              pushd $out
              ${pkgs.bundix}/bin/bundix -l
              popd
              diff gemset.nix $out/gemset.nix
            '';
          };
        };

        packages = {
          lockGemset = pkgs.writeScriptBin "run" ''
            echo "Locking Gemfile..."
            ${env}/bin/bundler lock
            echo "Locking Gemfile.lock to gemset.nix..."
            ${pkgs.bundix}/bin/bundix -l
          '';

          serveJekyll = pkgs.writeScriptBin "run" ''
            ${env}/bin/bundler exec -- jekyll serve --trace --livereload
          '';
        };

        apps =
          {
            lock = {
              type = "app";
              program = "${self.packages.${system}.lockGemset}/bin/run";
            };

            default = {
              type = "app";
              program = "${self.packages.${system}.serveJekyll}/bin/run";
            };
          };

        devShells = rec {
          default = dev;

          dev = pkgs.mkShell {
            # Ignore the current machine's platform and install only ruby
            # platform gems. As a result, gems with native extensions will be
            # compiled from source.
            # https://bundler.io/v2.4/man/bundle-config.1.html
            BUNDLE_FORCE_RUBY_PLATFORM = "true";

            buildInputs = [ env ]
              ++ (with pkgs; [ bundix ]);
          };
        };
      }
    );
}
