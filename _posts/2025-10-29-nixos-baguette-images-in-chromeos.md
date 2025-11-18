---
title: 'NixOS Baguette images in ChromeOS'
excerpt: >
  Running containerless NixOS VMs in ChromeOS.
tags: [ChromeOS]
modified_date: 2025-11-16
redirect_from:
  - /nixos-baguette
---

<div class="hint" markdown="1">

  This post extends [the one about NixOS containers in ChromeOS]({% post_url
  2025-06-19-nixos-in-crostini %}) to build Baguette images. Give Baguette a
  try and let me know how it works for you!

</div>

The ChromiumOS team is experimenting with _Baguette_ 🥖, a way to run
_containerless_ VM images in ChromeOS. By not running through LXC, Baguette
gives users more freedom (e.g., to run Kubernetes without KVM or access the
GPU).

The {% include github_link.html url="https://github.com/aldur/nixos-crostini"
text="`nixos-crostini`" %} repository already provided the magic glue to build
NixOS containers that fully integrate with Crostini. When [someone asked][0] if
it would be possible to support Baguette as well, I started taking a look at
what that would take. This post describes the results:

<!-- prettier-ignore-start -->

- Table of Contents
{:toc}
<!-- prettier-ignore-end -->

<div class="todo" markdown="1">

  _tl;dr_: You can build both LXC containers and Baguette images to run your
  NixOS configuration in Crostini. They provide the same features and
  UX (e.g., clipboard sharing, Wayland/port forwarding, file browsing from
  ChromeOS).

</div>

## Background: ChromeOS VMs

Under the hood, ChromeOS runs VMs through [`crosvm`][1], a hardened virtual
machine monitor. We already met it when [investigating FIDO2 support in Linux
ChromeOS guests]({% link _micros/fido2-almost-works-in-linux-on-chromeos.md
%}).

Crostini uses `crosvm` to run a stripped-down VM called [`termina`][2] that
boots quickly to run the user's containers. It also does a few more things:

1. It mounts [`crosvm-tools`][5], made available by the host through `crosvm`,
   into a guest directory (and later into containers as well).
1. It runs [`vshd`][3], allowing the host to get a shell on the guest.
1. It handles the lifecycle of the VM and of its processes through
   [`maitred`][4].

The [default Baguette image][7] is Debian-based and replicates all this. In
addition, it configures the VM to run `garcon` and `sommelier` directly (while
in Crostini they [run within the container]({% post_url
2025-06-19-nixos-in-crostini %}#nixos-containers)). Together, they provide URI
handling, file browsing, and X/Wayland forwarding: all the things that make
Crostini container very pleasant to use.

## Baguette NixOS images

Our NixOS Baguette image will need to replicate the Debian image setup. This
could turn out to be tricky, because NixOS cannot run [non-Nix executables][8]
due to the lack of [FHS][9] and of a global library path. Luckily, we won't
need to worry about that: `crosvm-tools` include their own libraries and
dynamic linker, so they run without issues in NixOS.

When we prepared NixOS LXC images for Crostini, we already figured out how to
run `garcon` and `sommelier` at user log in. Mounting `crosvm-tools` and
starting `vshd` and `maitred` was straightforward and simply required adding
their `systemd` unit definitions.

A Baguette image is a compressed BTRFS image [built from a RootFS tarball][10].
To build the tarball from the NixOS, I took a page from the [`lxc-container`
NixOS module][11]. Then, to package it:

- I initially tried the Python script used by Google, but it depends on
  `libguestfs-appliance` and is not available for `aarch64-linux` in
  `nixpkgs`[^arm].
- I later switched to a QEMU-based approach that works with Nix and supports
  ARM[^kvm].

[^arm]: I was experimenting with all this on the ARM-based Chromebook that
    I use for couch-computing.

[^kvm]: Because I wanted the build scripts to run within the default `penguin`
    image, I also [overrode the derivation][12] so that it falls back to
    [emulation][13] when `/dev/kvm` is missing.

After transferring the compressed image to the Chromebook "Downloads" directory
we can run it from `crosh`:

```bash
vmc create --vm-type BAGUETTE \
  --size 15G \
  --source /home/chronos/user/MyFiles/Downloads/baguette_rootfs.img.zst \
  baguette

vmc start --vm-type BAGUETTE baguette
```

<div class="hint" markdown="1">

  You might have heard about the [`#crostini-containerless` flag][16]: you can
  actually run `vmc start --vm-type BAGUETTE` even _without setting_ it. It
  only affects what happens when you "Configure Linux" in ChromeOS or use the
  "Terminal" app to launch a Linux guest.

  This way, you can try Baguette without losing your Crostini containers.

</div>

At boot, `maitred` relies on `/usr/sbin/usermod` to configure users and groups.
The `usermod` lives under a different path in NixOS, but I symlinked it to
`/usr/sbin/` to solve the issue and correctly get to a shell. _Within_ the VM,
I configured the DNS to rely on the host and set the environment variables
required by `crosvm-tools`.

X/Wayland and port forwarding were the last pieces of the puzzle. By diving
into the source code and the logs, I discovered that the `/dev/wl0` device was
missing read/write permissions for non-root users. By fixing it with a quick
`udev` rule, clipboard sharing and GUI apps started to work. I also created a
`systemd` unit to start `cros-port-listener` and enable automated
port-forwarding from Baguette to ChromeOS (very handy when writing this blog to
preview its HTML in Chrome).

With our image prepared and all issues fixed, Baguette is ready to shine! The {%
include github_link.html
url="https://github.com/aldur/nixos-crostini/blob/main/baguette.nix"
text="`baguette.nix`" %} file includes all the configuration in details, if you
are curious. Here is the result, showing a `baguette-nixos` VM correctly
forwarding a Wayland session to ChromeOS.

{:.text-align-center}
![A screenshot showing the `baguette-nixos` VM running Featherpad]({% link images/baguette.webp %}){:.centered}
_Wayland forwarding working in a Baguette VM._

### How-to: Make it yours

{% include github_link.html url="https://github.com/aldur/nixos-crostini/"
text="`nixos-crostini`" %} can now build both Baguette images and LXC
containers. If you give it a try, let me know how it goes through any of the
contacts in the footer.

<div class="todo" markdown="1">

  _tip_: {% include github_link.html
  url="https://github.com/aldur/nixos-crostini/" text="`nixos-crostini`" %}
  builds NixOS Baguette images in CI and uploads them as GitHub workflow
  artifacts. Download them to quickly boot Baguette and then re-build NixOS
  from your customized configuration.

  If you want to change the default username, fork the repository and edit the
  configuration. The CI will re-build the image for you.

</div>

### How-to: Additional shell sessions

To get additional shell sessions from new `crosh` tabs, use:

```bash
vsh baguette penguin
```

We don't really need the `penguin` argument, but without it we will get the
following error:

> if attempting to connect to a containerless guest please use `vsh termina
  penguin`.

### How-to: USB forwarding

<div class="hint" markdown="1">

 With Baguette, you can easily configure USB devices from Settings → Linux →
 _Manage USB devices_:

 1. Click on: _Enable persistent USB device sharing with guests_.
 2. Enable any USB device you'd like available to Baguette.

Selected devices will automatically be forwarded to Baguette once plugged in.

</div>

If you want to enable USB forwarding through `crosh`, Baguette [simplifies the
LXC approach]({% link _posts/2025-06-19-nixos-in-crostini.md
%}#how-to-usb-forwarding) because it doesn't need a container name.

Insert the device and then navigate to `chrome://usb-internals`. In the
`devices` tab, note the Bus number and Port number of your device.
`dmesg` in `crosh` will provide the same information, if you prefer.

Now open a `crosh` shell and attach the USB to the VM:

```bash
# Replace <bus> and <port> with the Bus and Port number from above.
vmc usb-attach baguette <bus>:<port>
```

### How-to: Launch NixOS from "Terminal"

<div class="hint" markdown="1">

  This _does require_ setting the
  [`#crostini-containerless` flag][17].

</div>

The Terminal application will default to launching a VM named `termina`. To
launch our VM, we will need to destroy and replace the default one. From
`crosh`:

```bash
vmc stop termina
vmc stop baguette

# Optional: backup `termina`
vmc export termina /home/chronos/user/MyFiles/Downloads/termina.img

# WARNING: This will destroy your existing `termina` VM and any data it contains.
vmc destroy termina

vmc export baguette /home/chronos/user/MyFiles/Downloads/baguette-nixos.img

vmc create --vm-type BAGUETTE \
  --size 15G \
  --source /home/chronos/user/MyFiles/Downloads/baguette-nixos.img \
  termina

# Optional: destroy the other `baguette` VM
vmc destroy baguette

vmc start --vm-type BAGUETTE termina
```

<div class="warning" markdown="1">

  Using Baguette in "Terminal" is a bit [wonky][19] and shows that it is
  currently under development. The ChromeOS team will not consider it stable
  until Chrome 143.

  In my experiments, I noticed that `congierce` will request `maitred` to
  configure the VM using a _default_ username (the one displayed when
  "Configuring Linux" from the settings). Trying to use a custom username seems
  to be hit or miss.

  I typically rename the VM to `termina` and then ditch "Terminal" and just
  [use `crosh`](#how-to-additional-shell-sessions).

</div>

### How-to: Root login

The Debian image allows passwordless `sudo`. The default NixOS configuration in
`nixos-crostini` replicates the approach, so that you can use escalate
privileges to rebuild your configuration from within the VM.

In my configuration, I [prefer to SSH as `root`]({% link
_posts/2025-06-27-yubikey-root-login.md %}) to passwordless `sudo`. This way, I
can use a hardware key to prove my physical presence and login as `root`, but
an attacker cannot automatically escalate privileges.

## Conclusion

Getting Baguette and NixOS to work together required a bit of trial and error
to build the image in the right format, figure out a few quirks, and adapt to
ChromeOS' CLI updates. I am now satisfied with the result: I wrote this blog
post from Baguette and I couldn't tell the difference from LXC.

I don't run Kubernetes (which seems to be one of the biggest pain point for LXC
users), but Baguette improves a few things for me as well:

1. In addition to being able to automatically forward USB devices, Baguette
   does [not hold an exclusive lock]({% link
   _micros/fido2-almost-works-in-linux-on-chromeos.md %}) on USB hardware keys.
   So I can use them _both_ in Baguette and in ChromeOS (as a passkey) at the
   same time without having to fiddle with `crosh`.
1. A containerless VM has better access to the underlying hardware and better
   control of its `init`. This might make it easier to implement [ephemeral
   storage][18] and seems to fix an issue with [`pcscd`][20] that would make it
   fail reading from Yubikeys after some time, until restarted.
1. Using `crosh` + `vsh` makes it easy to attach/detach USB devices and manage
   the VM itself without breaking _flow_ when switching from "Terminal". I
   could have done the same with LXC containers, but I didn't know about the
   `vsh` command.

Thanks for reading, and 'til next time! 👋

---

[0]: https://github.com/aldur/nixos-crostini/issues/1
[1]: https://crosvm.dev/book/devices/virtual_u2f.html
[2]: https://chromium.googlesource.com/chromiumos/overlays/board-overlays/+/HEAD/project-termina/
[3]: https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/vm_tools/vsh
[4]: https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/vm_tools/docs/init.md
[5]: https://chromium.googlesource.com/chromiumos/containers/cros-container-guest-tools/+/refs/heads/main
[7]: https://source.chromium.org/chromiumos/chromiumos/codesearch/+/main:src/platform2/vm_tools/baguette_image/src/setup_in_guest.sh
[8]: https://nix.dev/guides/faq.html#how-to-run-non-nix-executables
[9]: https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
[10]: https://source.chromium.org/chromiumos/chromiumos/codesearch/+/main:src/platform2/vm_tools/baguette_image/src/generate_disk_image.py
[11]: https://github.com/aldur/nixpkgs/blob/7271a39b1cd7d9b6799399dc2fbf1d5a6f16edea/nixos/modules/virtualisation/lxc-container.nix#L67
[12]: https://github.com/aldur/nixos-crostini/blob/2e3318ec0f72d775a22c35929887f93f1f17dbd7/baguette.nix#L236-L237
[13]: https://www.qemu.org/docs/master/devel/index-tcg.html
[16]: https://chromium.googlesource.com/chromium/src/+/0d439926c092142a02d96d38cfbb6a68044f2382
[17]: chrome://flags/#crostini-containerless
[18]: https://github.com/nix-community/impermanence
[19]: https://issues.chromium.org/issues/458443474#comment3
[20]: https://linux.die.net/man/8/pcscd
