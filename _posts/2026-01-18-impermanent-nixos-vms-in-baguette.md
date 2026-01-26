---
title: 'Impermanent NixOS VMs in ChromeOS'
excerpt: >
  Automatically erasing /home in NixOS VMs.
tags: [ChromeOS]
---

We have [talked about]({% link _tag_indexes/ChromeOS.md %}) using NixOS to run VMs under ChromeOS. The VM image
doesn't include any secret and relies on hardware keys for authentication and
signatures (e.g., to push and sign commits on GitHub). This way, even if the VM
was compromised, the hardware-backed credentials would remain safe.

In practice, though, the VM slowly accumulates other (possibly) confidential
information: source code, [authentication tokens]({% link
_micros/short-lived-openrouter-api-keys.md %}), LLM sessions, and even shell
history. To clean things up, a user would need to periodically destroy and
recreate the VM. But users (me) get sloppy, for instance when overworked.
Worse, being in a VM might give them a wrong sense of confidence that there is
nothing to leak!

### What is impermanence

Good safety systems should not rely on user behavior to maintain their safety
properties. And neither should VMs when meant to be ephemeral working
environments. Luckily NixOS can help us remediate that.

Due to its reproducibility, NixOS can boot by exclusively relying on a `/init`
file and the `/nix` store[^baguette]. Everything else can be re-created at
runtime (typically, by symlinking files and directories to the appropriate path
in the store). We can _abuse_ that to achieve _impermanence_ and ensure a clean
system after each reboot.

[^baguette]: Pretty much what happens when the [Baguette NixOS image]({%
  post_url 2025-10-29-nixos-baguette-images-in-chromeos %}) starts.

The Nix community has contributed a few ways to achieve impermanence.
Typically, they all require to configure the system to erase itself at boot
while maintaining a whitelist of files and directories that will survive
reboots (for instance SSH host keys on a remote server, which would otherwise
result in a different remote fingerprint at each reboot).

### Erasing `/home`

For the NixOS VMs I use under ChromeOS, I chose to configure impermanence as
follows:

- `/home` mounts through `tmpfs`. This way, anything I don't explicitly
  whitelist will live be gone at power down. I don't have to worry about
  automating its deletion, but I need to cap `/home` size to (a portion of) the
  available memory.
- The [`preservation`][0] module takes care of safe-keeping a few required
  files and directories under `/home` (for instance known SSH hosts or source
  code I explicitly want to keep across reboots).
- The rest of the filesystem is _not_ impermament, for simplicity and to save
  RAM. My VM user cannot become `root`, so (assuming correct permissions)
  should not be able to modify system files anyways.

### Settings things up

A minimal Nix module to achieve impermanence looks as follows:

```nix
{inputs, ...}:
let username = "aldur"; in {
  imports = [
    # Impermanence: import the preservation module
    inputs.preservation.nixosModules.preservation
  ];

  # Impermanence: tmpfs home with preservation
  fileSystems."/home" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=4G"
      "mode=755"
    ];
  };

  # Impermanence: whitelist to preserve
  # See `preservation` docs for more configuration options.
  preservation = {
    enable = true;

    preserveAt."/persist".users.${username}.directories = {
      "Documents/"

      {
        directory = ".ssh";
        mode = "0700";
      }
    };
  };
}
```

### Playing nicely with `home-manager`

While settings things up and testing the result, the VM would occasionally fail
to correctly load `home-manager`'s configuration (which, importantly,
configures the `fish` shell).

After quite some debugging, I figured out that `home-manager` was _racing_
against `garcon`, a service that automatically starts and spwans a shell when a
Baguette VM starts from ChromeOS through `vmc start`. When `garcon` won the
race and executed before `home-manager`, it would launch `fish` without any
customization.

The fix is to delay `garcon` (a user service) until after `home-manager` is done:

```nix
_:
let username = "aldur"; in {
  services."user@" = {
    overrideStrategy = "asDropin";
    after = [ "home-manager-${username}.service" ];
    wants = [ "home-manager-${username}.service" ];

    # In case something goes wrong
    serviceConfig.TimeoutStartSec = "90";
  };
}
```

### Wrapping up

I have been running with impermanence for a few weeks now. So far, I haven't
had any issue. On systems with 16GB of RAM, I typically size `/home` to 4GB. I
suspect that this could create issues if compiling artifact-heavy or memory
intensive builds, e.g. Rust workspaces or numeric Python projects (which pull a
lot of packages from PyPi). If that happens, I should be able to configure the
build tools to store assets in `/tmp`. Similarly, I could run into issues if a
project's cache is wiped on reboot, preventing offline rebuilds (e.g., while on
a flight). To avoid that, I typically rely on `nix develop` for local
development shells, caching anything required in the `nix` store.

I can also see a few security limitations of the approach. For instance,
sophisticated malware could persist by escalating privileges and infecting the
system configuration, or by storing copies of itself into the `nix` store (to
which my user has append access). Although it isn't a silver bullet,
impermanence for `/home` still adds to defense in depth. It should thwart _some
classes_ of attacks (e.g., supply chain compromises) from harvesting
credentials that accumulated over time. For the remaining ones (and because
it's fun!) I will continue hardening the VM image: I would love to do that
through mandatory access control policies, but using them in NixOS seems
like a deep rabbit hole to explore.

👋 Thank you for reading so far! [Shoot me an email](mailto:{{ site.author.email
}}) if you'd like to comment, discuss, or just say hi. Until next time!

#### Footnotes

[0]: https://github.com/nix-community/preservation
