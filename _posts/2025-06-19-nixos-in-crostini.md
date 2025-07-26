---
title: "NixOS containers in ChromeOS"
excerpt: >
  Bring your own keys, here's the shell. How to turn a Chromebook
  into a secure, productive environment.
modified_date: 2025-07-26
---

Chromebooks have a reputation of being _little, secure_ devices:

- _Verified Boot_ ties the integrity of the OS to the underlying hardware:
Google's marketing material describes it as "a read-only operating system".
- Then, _defense in depth_ increases its robustness: The Chrome sandbox, the OS
userspace, the kernel, the firmware, and lastly the hardware.

In other words: the system should be clean at boot and remain clean while
running. As a user, this means I can get a Chromebook and _powerwash_ it (lingo
for a deep but fast wipe) to start from a _reasonably trustworthy_ computing
base. Compromising it should be relatively hard (thanks to defense in depth).
And, worst case, a reboot shall return it to a clean state.

On paper, this is awesome! It makes Chromebooks the go-to for most
security-sensitive tasks. However, turning a powerwashed device into a
productive environment requires an initial setup process, logging into each
required online service, setting up all tools, and finally getting to work.

Ideally, instead, I would like to skip all configuration and be productive as
quickly as possible. That way, I could periodically throw away any persisted
state and restart from scratch. I could spin up segregated environments (e.g.,
one for personal life, one for work, or even one for each project), and even
quickly get them running on multiple machines.

This post describes my approach to this goal: reproducible, throwaway
containers running securely under ChromeOS.

<!-- prettier-ignore-start -->

- Table of Contents
{:toc}
<!-- prettier-ignore-end -->

## The requirements

I don't need much to be productive: a web browser and a shell. The browser is
my gateway to most apps and services. Even when there are alternatives (e.g.
native or Electron apps), I prefer to rely on the browser to add defense in
depth. The shell usually provides everything else I need, including an editor
and access to other hosts.

A productive shell should come as ready as possible: for instance, `git` should
know who I am and how I prefer to fetch branches. It should be easy to
configure, audit, and (re)build from scratch. Deploying it to a clean device
should be fast (minutes). Importantly, it should _not_ bundle any secret (e.g.,
passwords or cryptographic keys) or confidential information, nor should it
have access to any long-lived credential either.

The lack of secrets and credentials is important for safety: if the environment
is compromised while at rest, there is nothing to exfiltrate. Plus, we do not
need to worry about _how_ we deliver the container image, _where_ we store it,
_if_ it leaks, and _when_ to dispose it. If, instead, if the compromise happens
at runtime (e.g., through a malicious executable), then the attacker should not
be able to access any long-lived credential (e.g., an SSH key).

## The solution

My solution largely relies on:

1. Hardware keys, holding login credentials and cryptographic keys.
1. NixOS containers, running under ChromeOS' Crostini.

### Hardware keys

Hardware keys create a security boundary between the secrets and the
environment. They allow me to securely "bring" secrets, while ensuring that
they never leave the hardware device and are never exposed directly to the
environment.

Through hardware keys I can:

1. Login to online services (thanks to WebAuthn and passkeys).
2. Prove second factors ("something I have").
3. Authenticate to other hosts (through SSH) and sign messages.

Some online services now allow passwordless login through passkeys. This means
that I don't need to type my username or password: I just visit their website
through Chrome, unlock the hardware key through its PIN, and login.

In some cases, a hardware key can only be used as a second factor (in the
browser). When that happens, I can still leverage it to decrypt the password
from a vault (e.g. using [`passage`](https://github.com/FiloSottile/passage) in
the shell, or authenticating to a password manager with a passkey). As more
services embrace passkeys, the need for passwords will hopefully become less
frequent.

Lastly, the hardware key holds SSH keys used both for authentication (`ssh`)
and signing (e.g., `git commit`) while in the shell.

### NixOS containers

One of the killer features of Chromebooks is that they have good support for
running Linux without compromising on security. Technically, a system called
Crostini runs a Linux VM (booting a hardened kernel), which in turn runs `lxc`
containers. By default, ChromeOS ships a `debian` container.

What makes Crostini great (e.g., when compared to SSH into a remote system) is
that it has first-class integration with ChromeOS. You can run Linux GUI apps
and they will show up alongside all other Chrome apps; you can open a URL in
the Linux container and it will open in Chrome; you can copy to clipboard in
Linux and it will populate ChromeOS' clipboard; ChromeOS will even forward most
ports from `localhost` to the container.

The default `debian` container ships a few services that make that magic
happen. Here are the two I have found the most useful:

- `garcon` enables bidirectional communication between ChromeOS and the
container. This allows using the Terminal to get to a container console,
handling URLs, browsing container files through the Files app, etc.
- `sommelier` allows the container to run GUI applications (and clipboard
management).

The obvious downside of the `debian` container is that it is "vanilla" and it
requires heavy customization. That's where NixOS makes a difference: it makes
it easy to build a container that ships required tools (think `git`, `ssh`, but
even the AWS CLI) and all their required configuration (`.dotfiles`, profiles,
etc.).

To get NixOS running under Crostini:

1. I first prepared a custom NixOS image that included my dotfiles and the
   tools I usually need to be productive.
2. I then added `garcon` and `sommelier`, to make it play nicely with ChromeOS.
3. Lastly, I figured out how to ship it to the Chromebook and run it.

#### How-to: Preparing the image

There are a few ways to prepare a `lxc` image shipping your NixOS
configuration. I won't go into details here, since Nix itself is a pretty deep rabbit
hole and it would take more than one blog post to do a good job at explaining
it.

In my case, I applied
[`nixos-generators`](https://github.com/nix-community/nixos-generators) to my
Nix configuration to build the `lxc` RootFS and its associated metadata (both
are `.tar.xz`) files.

Then, I prepared a `crostini.nix` module to provide `garcon` and `sommelier`
through `systemd`. The ChromeOS source code and the
`cros-container-guest-tools-git` [AUR
package](https://aur.archlinux.org/packages/cros-container-guest-tools-git)
were invaluable in making this happen.

<details markdown=1>
  <summary markdown=span>Click to toggle the source for the Crostini NixOS module.</summary>

```nix
{
  modulesPath,
  lib,
  pkgs,
  ...
}:

let
  cros-container-guest-tools-src-version = "4ef17fb17e0617dff3f6e713c79ce89fee4e60f7";

  cros-container-guest-tools-src = pkgs.fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/containers/cros-container-guest-tools";
    rev = cros-container-guest-tools-src-version;
    outputHash = "sha256-Loilew0gJykvOtV9gC231VCc0WyVYFXYDSVFWLN06Rw=";
  };

  cros-container-guest-tools = pkgs.stdenv.mkDerivation {
    pname = "cros-container-guest-tools";
    version = cros-container-guest-tools-src-version;

    src = cros-container-guest-tools-src;
    installPhase = ''
      mkdir -p $out/{bin,share/applications}

      install -m755 -D $src/cros-garcon/garcon-url-handler $out/bin/garcon-url-handler
      install -m755 -D $src/cros-garcon/garcon-terminal-handler $out/bin/garcon-terminal-handler
      install -m644 -D $src/cros-garcon/garcon_host_browser.desktop $out/share/applications/garcon_host_browser.desktop
    '';
  };

in
{
  imports = [
    # Load defaults for running in an lxc container.
    # This is explained in: https://github.com/nix-community/nixos-generators/issues/79
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  # The eth0 interface in this container can only be accessed from the host.
  networking.firewall.trustedInterfaces = [ "eth0" ];

  # Disabling IPv6 makes the boot a bit faster (DHCPD)
  networking.enableIPv6 = false;
  networking.dhcpcd.IPv6rs = false;
  networking.dhcpcd.wait = "background";

  # `boot.isContainer` implies NIX_REMOTE = "daemon"
  # (with the comment "Use the host's nix-daemon")
  # We don't want to use the host's nix-daemon.
  environment.variables.NIX_REMOTE = lib.mkForce "";

  # Suppress daemons which will vomit to the log about their unhappiness
  systemd.services."console-getty".enable = false;
  systemd.services."getty@".enable = false;

  # Disable nixos documentation because it is annoying to build.
  documentation.nixos.enable = lib.mkForce false;

  # Make sure documentation for NixOS programs are installed.
  # This is disabled by lxc-container.nix in imports.
  documentation.enable = lib.mkForce true;

  environment.systemPackages = [
    cros-container-guest-tools

    pkgs.wl-clipboard # wl-copy / wl-paste
    pkgs.xdg-utils # xdg-open
  ];

  environment.etc = {
    # Required because `tremplin` will look for it.
    # Without it, `vmc start termina <container>` will fail.
    "gshadow" = {
      mode = "0640";
      text = "";
      group = "shadow";
    };

    # TODO: Even empty, this will stop `sommelier` from erroring out.
    "sommelierrc" = {
      mode = "0644";
      text = ''
        exit 0
      '';
    };
  };

  system.activationScripts = {
    # Activating sommelier-x will rely the bind-mount Xwailand executable. As
    # far as I could debug, this path can't be controlled through env and would
    # require re-compiling Xwayland (which is also dynamically loaded by the
    # sommelier executable).
    #
    # Same for the `sftp-server` launched by `garcon`.
    #
    # These are ugly HACKs, but they work
    xkb = "ln -sf ${pkgs.xkeyboard_config}/share/X11/ /usr/share/";
    sftp-server = ''
      mkdir -p /usr/lib/openssh/
      ln -sf ${pkgs.openssh}/libexec/sftp-server /usr/lib/openssh/sftp-server
    '';
  };

  # Load the environment populated from `sommelier`, e.g. `DISPLAY`.
  environment.shellInit = builtins.readFile "${cros-container-guest-tools-src}/cros-sommelier/sommelier.sh";

  # Taken from https://aur.archlinux.org/packages/cros-container-guest-tools-git
  xdg.mime.defaultApplications = {
    "text/html" = "garcon_host_browser.desktop";
    "x-scheme-handler/http" = "garcon_host_browser.desktop";
    "x-scheme-handler/https" = "garcon_host_browser.desktop";
    "x-scheme-handler/about" = "garcon_host_browser.desktop";
    "x-scheme-handler/unknown" = "garcon_host_browser.desktop";
  };

  systemd.user.services.garcon = {
    # TODO: In the original service definition this only starts _after_ sommelier.
    description = "Chromium OS Garcon Bridge";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "/opt/google/cros-containers/bin/garcon --server";
      Type = "simple";
      ExecStopPost = "/opt/google/cros-containers/bin/guest_service_failure_notifier cros-garcon";
      Restart = "always";
    };
    environment = {
      BROWSER = (lib.getExe' cros-container-guest-tools "garcon-url-handler");
      NCURSES_NO_UTF8_ACS = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_QPA_PLATFORMTHEME = "gtk2";
      XCURSOR_THEME = "Adwaita";
      XDG_CONFIG_HOME = "%h/.config";
      XDG_CURRENT_DESKTOP = "X-Generic";
      XDG_SESSION_TYPE = "wayland";
      # FIXME: These paths do not work under nixos
      XDG_DATA_DIRS = "%h/.local/share:%h/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share";
      # PATH = "/usr/local/sbin:/usr/local/bin:/usr/local/games:/usr/sbin:/usr/bin:/usr/games:/sbin:/bin";
    };
  };

  systemd.user.services."sommelier@" = {
    description = "Parent sommelier listening on socket wayland-%i";
    wantedBy = [ "default.target" ];
    path = with pkgs; [
      systemd # systemctl
      bash # sh
    ];
    serviceConfig = {
      Type = "notify";
      ExecStart = ''
        /opt/google/cros-containers/bin/sommelier \
                      --parent \
                      --sd-notify="READY=1" \
                      --socket=wayland-%i \
                      --stable-scaling \
                      --enable-linux-dmabuf \
                      sh -c \
                          "systemctl --user set-environment ''${WAYLAND_DISPLAY_VAR}=$''${WAYLAND_DISPLAY}; \
                           systemctl --user import-environment SOMMELIER_VERSION"
      '';
      ExecStopPost = "/opt/google/cros-containers/bin/guest_service_failure_notifier sommelier";
    };
    environment = {
      WAYLAND_DISPLAY_VAR = "WAYLAND_DISPLAY";
      SOMMELIER_SCALE = "1.0";
    };
  };

  systemd.user.services."sommelier-x@" = {
    description = "Parent sommelier listening on socket wayland-%i";
    wantedBy = [ "default.target" ];
    path = with pkgs; [
      systemd # systemctl
      bash # sh
      xorg.xauth
      tinyxxd
    ];
    serviceConfig = {
      Type = "notify";
      ExecStart = ''
        /opt/google/cros-containers/bin/sommelier \
          -X \
          --x-display=%i \
          --sd-notify="READY=1" \
          --no-exit-with-child \
          --x-auth="''${HOME}/.Xauthority" \
          --stable-scaling \
          --enable-xshape \
          --enable-linux-dmabuf \
          sh -c \
              "systemctl --user set-environment ''${DISPLAY_VAR}=$''${DISPLAY}; \
               systemctl --user set-environment ''${XCURSOR_SIZE_VAR}=$''${XCURSOR_SIZE}; \
               systemctl --user import-environment SOMMELIER_VERSION; \
               touch ''${HOME}/.Xauthority; \
               xauth -f ''${HOME}/.Xauthority add :%i . $(xxd -l 16 -p /dev/urandom); \
               . /etc/sommelierrc"
      '';
      ExecStopPost = "/opt/google/cros-containers/bin/guest_service_failure_notifier sommelier-x";
    };
    environment = {
      # TODO: Set `SOMMELIER_XFONT_PATH`
      DISPLAY_VAR = "DISPLAY";
      XCURSOR_SIZE_VAR = "XCURSOR_SIZE";
      SOMMELIER_SCALE = "1.0";
    };
  };

  systemd.user.targets.default.wants = [
    "sommelier@0.service"
    "sommelier@1.service"
    "sommelier-x@0.service"
    "sommelier-x@1.service"
  ];
}
```

</details><br/>

After rebuilding the image to include this module, we need to upload it
somewhere so that we can later fetch it from the Chromebook. I have considered
[different solutions]({% link
_micros/more-ways-to-bootstrap-nixos-containers.md %}) and the simplest I have
found is hosting an [LXD image
server](https://ubuntu.com/tutorials/create-custom-lxd-images#6-making-images-public)
[behind Tailscale]({% link
_micros/more-ways-to-bootstrap-nixos-containers.md %}/#from-an-lxd-image-server-behind-tailscale).

On a NixOS server, enable `lxd`:

```nix
virtualisation.lxd.enable = true;
```

Then, enable the image server as follows:

```bash
# `lxd` can't be configured declaratively in NixOS, go figure!
sudo lxc config set core.https_address :8443
```

You can now import the image with and get it ready for the Chromebook.

```bash
# Replace `lxc-metadata` and `lxc` with the directories where you built the metadata and the RootFS.
lxc image import --public --alias lxc-nixos ${lxc-metadata}/tarball/*.tar.xz ${lxc}/tarball/*.tar.xz
```

#### How-to: Deploying the image

If you haven't done it yet, [configure
Linux](https://support.google.com/chromebook/answer/9145439?hl=en). When asked,
choose the same username you will use within the container. I usually use 32GB
of storage.

Now open `crosh` (<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd>), then:

```sh
# Not strictly required, but better start clean.
vmc destroy termina
vmc start termina
```

Connect to Tailscale (install the app from the Play Store, use the hardware key
to authenticate). Then, from inside `termina`:

```bash
# Assuming `tropic` is the hostname of the `lxd` server we have configured before.
lxc remote add tropic https://tropic:8443 --public

# Ensure you can see the image listed.
lxc image list tropic:

# Download the image and setup the container.
# NOTE: Transfer speed into `termina` depends on the Chromebook.
# I try to keep the image small so that this is fast.
lxc init tropic:lxc-nixos lxc-nixos --config security.nesting=true
```

<div class="warning" markdown="1">

I have seen a few guides recommending `--config security.privileged=true`.

Don't do it! If you do, you will spend a couple hours (as I did) trying
to figure out why USB devices correctly show up in `lsusb` but then error with
"permission denied" when you try accessing them. In my experience, there is
no need for that flag.

The `security.nesting=true`, instead, is required to run `nix` in the
container. It is part of the default configuration that Crostini uses to init
containers, and it is the right choice.

</div>

You can now start the container and, after a few seconds, it should get an IP
through DHCP:

```bash
lxc start lxc-nixos

# Peek at the console logs, if you want
lxc console --show-log lxc-nixos

# Wait until `lxc list` shows an IP.
lxc list
```

At this point you can `exec` into the container and play around with it:

```bash
lxc exec lxc-nixos bash
```

We are not done yet, though! First, we don't need to be logging in as root.
Second, `garcon` will not work yet, because it is missing a required file:
`/dev/.container_token`. As far as I can tell, to get `.container_token` we
need to start the container from `crosh`. So:

```bash
# From Termina (ctrl-d if you are still in `lxc-nixos`)
lxc stop --force lxc-nixos

# From crosh (ctrl-d from `termina`)
# This will ensure `/dev/.container_token` exists within the container
vmc container termina lxc-nixos
```

This will error out telling you that the container cannot be found. Fear not!
The container has started in the background and you'll get a shell (by
re-running the same command) once it gets an IP. Now you should be able to see
`garcon` and `sommelier` running correctly.

```bash
vmc container termina lxc-nixos

# Now, in `lxc-nixos`
systemctl --user status garcon.service
systemctl --user status sommelier@0.service
systemctl --user status sommelier-x@0.service
```

We can also make a couple of tests:

```bash
# This should populate your ChromeOS clipboard (you can check it with launcher-v or by pasting somewhere).
# Under the hood, it uses `sommelier` through the Wayland protocol.
echo "Clipboard works!" | wl-copy

# This should have a pair of goggly eyes pop on your screen and is testing X proxying through `sommelier-x`
nix run nixpkgs#xorg.xeyes
```

#### How-to: USB forwarding

In order to use hardware keys within the container, we will also need to set up
USB forwarding.

Every time you plug a USB device in, ChromeOS should prompt you whether you
want to connect it to Android or Linux. That has never worked for me, so I just
went the CLI way.

Insert the device and then navigate to `chrome://usb-internals`. In the
`devices` tab, note the Bus number and Port number of your device.
`dmesg` in `crosh` will provide the same information, if you prefer.

Now open a new `crosh` shell and attach the USB to the container:

```bash
# Replace <bus> and <port> with the Bus and Port number from above.
vmc usb-attach termina <bus>:<port> lxc-nixos
```

In the container, `lsusb` should show the device as ready for use.

<div class="warning" markdown="1">

The container name at the end of the `usb-attach` command is _fundamental_!
Without it, the security key will show up in the container but you will not be
able to use it.

</div>

Occasionally, I could see the device in `lsusb` but the hardware key would not
work. If that happens, try restarting the `pcscd` service and trying again.
If that fails, try rebooting the `termina` VM.

#### How-to: Add the container to ChromeOS

ChromeOS ships an experimental UI for creating and managing multiple Crostini
containers. When enabled, it significantly improves UX! It allows to:

- Launch our container by clicking on its name in the terminal, instead of
  going through `crosh`. If the VM is off, it will launch it as well.
- Mount folders into the container from the Files application.
- Browse the container user home directory through Files.

To enable it, navigate to: `chrome://flags/#crostini-multi-container`, switch
the drop-down to "Enabled" and then restart.

Now, navigate to: Settings → Linux → Manage extra containers → Create. Fill in
the "Container name" and click on Create (importantly, do this _after_ you have
created the container from `crosh`). If the container was previously running,
stop it with `lxc stop`. You can now start it from Terminal.

{:.text-align-center}
![A screenshot showing the `lxc-nixos` container available in the Terminal application.]({% link images/chromeos-terminal-lxc-nixos.webp %}){:.centered}
_The experimental UI makes it seamless to start and access the container from
Terminal._

{:.text-align-center}
![A screenshot showing the `lxc-nixos` container available in the Files application.]({% link images/chromeos-files-lxc-nixos.webp %}){:.centered}
_Use Files to browse the container home and mount directories into it._

#### How-to: SSH into the container

If your container ships an SSH server, you can use the built-in Terminal
application to SSH into it. This is useful to leave the USB hardware key usable
from Chrome and use agent forwarding to authenticate from the container.

Open the Terminal application and configure a new SSH connection. Fill in
`<username>@lxc-nixos.termina.linux.test` as the command. Add the following SSH
relay server options to enable authentication through the hardware key:

```txt
--ssh-agent=gsc --ssh-client-version=pnacl
```

Connecting should trigger a prompt for your hardware key PIN. Insert it and touch
the key if you need it to get in.

I have noticed this to be hit-or-miss. Sometimes it fails to authenticate
transiently and I have to try re-connecting. Other times, it won't show the PIN
prompt. Disconnecting and re-connecting the hardware key sometimes helps
(sigh!).

#### How-to: Root login

SSH or `lxc exec` make it easy and safe. See [this post]({% link
_posts/2025-06-27-yubikey-root-login.md %}).

## Conclusion

Software-wise, my `crostini.nix` module does most of the heavy lifting for the
things I actually need to work. I haven't tested hardware acceleration, audio,
and there's probably a few more things that do not work yet (when compared to
`debian`). But I can always add those things when the need arises. Clipboard
sharing between Chrome and Crostini is probably the feature I am using the
most, in addition to opening URLs in Chrome from the container through
`garcon`.

Hardware-wise, I feel that Chromebooks are great "couch-computing" or travel
devices. They are underpowered with respect to other machines (e.g., an M4
MacBook). But they are lighter, cheaper, and their battery is OK considering
they are "Linux" devices (I can probably do 6 hours on mine). I wish
the display was a bit brighter, especially under direct light.

Overall, after using this setup for a few weeks I am satisfied with it -- I
even wrote this blog post on a Chromebook! It does most of what I was looking
for, strikes a good security posture, and I like being able to go from _zero_
to a productive environment in a couple minutes. Once the container boots, I
immediately feel at home. I can quickly get ahead and write my thoughts,
hack on a new project, or put off the occasional fire at work. Having a full
system bottled-in and ready to go also gives me confidence I could somehow
recover in case of disaster (think fire, natural disaster, theft, etc.),
ensuring that I do not rely on a single point of failure. Lastly, this setup is
trivial to deploy to a different system: I have had some fun playing with AI
agents in a `qemu` VM built using the same tools.

Thanks for reading, and 'til next time!

<div class="hint" markdown="1">
The ChromiumOS team is experimenting with a way (codename `baguette`) to run
  containers without a KVM. If that happens and this guide becomes outdated,
  reach out! We will figure out how to make it work there as well.
</div>

## References

- [ChromeOS Security Whitepaper](https://www.chromium.org/chromium-os/developer-library/reference/security/security-whitepaper/#hardware-root-of-trust-and-verified-boot.md)
- [Crostini Developer Guide](https://www.chromium.org/chromium-os/developer-library/guides/containers/crostini-developer-guide/)
- [Running Custom Containers Under ChromeOS](https://www.chromium.org/chromium-os/developer-library/guides/containers/containers-and-vms/)
- [Port forwarding and tunneling in ChromeOS](https://www.chromium.org/chromium-os/developer-library/reference/security/port-forwarding/)
- [Crosh -- The ChromiumOS shell](https://www.chromium.org/chromium-os/developer-library/reference/device/crosh/)
- [ArchLinux wiki: ChromeOS Devices](https://wiki.archlinux.org/title/Chrome_OS_devices/Crostini.md)
- [NixOS wiki: Installing Nix on Crostini](https://wiki.nixos.org/wiki/Installing_Nix_on_Crostini.md)
- [Chrome internals: DNS](chrome://net-internals/#dns)
