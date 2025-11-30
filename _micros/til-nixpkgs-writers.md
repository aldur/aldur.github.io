---
title: 'TIL: nixpkgs.writers'
date: 2025-11-30
tags: [TIL]
---

TIL to use `nixpkgs.writers` to quickly:

1. Package scripts into executables with proper shebangs (e.g., Python).
1. Bundle any dependencies.
1. Perform checks/lints (e.g., through `flake8`)

I am using it in my [openrouter-provisioner][0] as follows:

```nix
server = pkgs.writers.writePython3Bin "openrouter-provisioner" {
  flakeIgnore = [
    "E501" # line too long
  ];
} (builtins.readFile ./openrouter.py);
```

When an LLM originally suggested this snippet, I thought it was _hallucinating_
because I couldn't find any reference in the [manual][2]. Then, when
challenged, the LLM returned the [source for the `writers` library][1]. LLMs
are obviously not suited for all tasks, but this is an example of something
they are excellent at: they will easily _discover_ and use less-known library
features by going through the source code when the documentation is lacking.

In this particular case, the `writers` library includes documentation comments
for most of the derivations, but none of them make it in the overall manual. I
was about to open an issue but then discovered that [there's already one][3]
dating back to 2020.

### The writers

In case it's useful, [this is the Markdown documentation that would be
generated][4] and below is a list of all the included writers (some are missing
from the docs):

<details markdown=1>
<summary markdown=span>Click to expand (LLM output of included writers)</summary>

#### Base

- **makeScriptWriter** - Base implementation for creating script writers
- **makeBinWriter** - Base implementation for compiled language writers

#### Shell

- **writeBash** - Bash script writer
- **writeBashBin** - Bash script writer (outputs to /bin)
- **writeDash** - Dash script writer
- **writeDashBin** - Dash script writer (outputs to /bin)
- **writeFish** - Fish shell script writer
- **writeFishBin** - Fish shell script writer (outputs to /bin)
- **writeNu** - Nushell script writer
- **writeNuBin** - Nushell script writer (outputs to /bin)

#### Interpreted languages

- **writeBabashka** - Babashka (Clojure) script writer
- **writeBabashkaBin** - Babashka script writer (outputs to /bin)
- **writeGuile** - Guile Scheme script writer
- **writeGuileBin** - Guile Scheme script writer (outputs to /bin)
- **writeRuby** - Ruby script writer
- **writeRubyBin** - Ruby script writer (outputs to /bin)
- **writeLua** - Lua script writer
- **writeLuaBin** - Lua script writer (outputs to /bin)
- **writePerl** - Perl script writer
- **writePerlBin** - Perl script writer (outputs to /bin)
- **writeJS** - JavaScript (Node.js) script writer
- **writeJSBin** - JavaScript script writer (outputs to /bin)

#### Python

- **writePython3** - Python 3 script writer
- **writePython3Bin** - Python 3 script writer (outputs to /bin)
- **writePyPy2** - PyPy2 script writer
- **writePyPy2Bin** - PyPy2 script writer (outputs to /bin)
- **writePyPy3** - PyPy3 script writer
- **writePyPy3Bin** - PyPy3 script writer (outputs to /bin)

#### Compiled Languages

- **writeHaskell** - Haskell compiled script writer
- **writeHaskellBin** - Haskell compiled script writer (outputs to /bin)
- **writeNim** - Nim compiled script writer
- **writeNimBin** - Nim compiled script writer (outputs to /bin)
- **writeRust** - Rust compiled script writer
- **writeRustBin** - Rust compiled script writer (outputs to /bin)
- **writeFSharp** - F# script writer
- **writeFSharpBin** - F# script writer (outputs to /bin)

#### Specialized Writers

- **writeNginxConfig** - Nginx configuration file writer

#### Data Writers

- **makeDataWriter** - Base transformer for writing data (deprecated)
- **writeText** - Plain text file writer
- **writeJSON** - JSON file writer
- **writeTOML** - TOML file writer
- **writeYAML** - YAML file writer

</details>

[0]: https://github.com/aldur/openrouter-provisioner/blob/0606ce7637856f4fc2138b473ed2831cd6dc2dcc/flake.nix#L17-L21
[1]: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/writers/scripts.nix
[2]: https://nixos.org/manual/nixpkgs/unstable/
[3]: https://github.com/NixOS/nixpkgs/issues/89759
[4]: https://gist.github.com/aldur/518cc92d30a897b226ed18f7f10926cb
