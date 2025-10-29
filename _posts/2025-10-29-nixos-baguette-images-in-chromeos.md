---
title: 'NixOS images in ChromeOS Baguette'
excerpt: >
  Running NixOS VMs in ChromeOS, without LXC.
tags: [ChromeOS]
---

<div class="hint" markdown="1">

  This post extends the [one about NixOS containers in ChromeOS]({% post_url
  2025-06-19-nixos-in-crostini %}) to build Baguette images. I updated the {%
  include github_link.html url="https://github.com/aldur/nixos-crostini"
  text="`nixos-crostini`" %} repository with experimental Baguette support.
  Give it a try and let me know how it works for you!

</div>

The ChromiumOS team is experimenting with a way (codename _Baguette_ 🥖) for
Chromebooks to run VM images directly instead of going through LXC containers.

The {% include github_link.html url="https://github.com/aldur/nixos-crostini"
text="`nixos-crostini`" %} repository provides a NixOS module to build LXC
container images for Crostini (the established way to run arbitrary Linux
guests in ChromeOS). When [someone asked][0] if it would be possible to support
Baguette as well, I started taking a look at what it would take. This post 
describes the results.

### ChromeOS VMs

Under the hood, ChromeOS runs VMs through [`crosvm`][1], a hardened virtual
machine monitor. We already met it when [investigating FIDO2 support in Linux
ChromeOS guests]({% link _micros/fido2-almost-works-in-linux-on-chromeos.md
%}).

Crostini uses `crosvm` to run a stripped-down VM called [`termina`][2] that
boots quickly and runs the user's containers. It also does a few more things:

1. It mounts [`crosvm-tools`][5], made available by the host through `crosvm`,
   into a guest directory (and later into containers as well).
1. It runs [`vshd`][3], allowing the host to get a shell on the guest.
1. It handles the lifecycle of the VM and of its processes through
   [`maitred`][4].

The [default Baguette image][7] is based on Debian and replicates all this. In
addition, it also configures the VM to run `garcon` and `sommelier` directly
(while in Crostini they [run within the container]({% post_url
2025-06-19-nixos-in-crostini %}#nixos-containers)). Together, they provide URI
handling, file browsing, and X/Wayland forwarding: all the things that make
Crostini container very pleasant to use.

### Baguette NixOS images

Our NixOS Baguette image will need to replicate the Debian image setup.

Typically, NixOS cannot run [non-Nix executables][8] due to the lack of
[FHS][9] and of a global library path. Luckily, we won't have to worry about
that: `crosvm-tools` include their own libraries and dynamic linker, so they
run without issues in NixOS.

Back when preparing NixOS LXC images for Crostini, we already figured out how
to run `garcon` and `sommelier` when the user logs in, so that part is solved.
Mounting `crosvm-tools` and adding `systemd` units for `vshd` and `maitred` was
straightforward as well.

Next, I had to figure out how to correctly build an image of the format
Baguette expects from the NixOS configuration: a BTRFS image [built from][10] a
RootFS tarball. To build the tarball, I took a page from the [`lxc-container`
NixOS module][11]. Then, to package it: 

- I initially re-used the Debian Python script, which depends on
  `libguestfs-appliance` and is not available for `aarch64-linux` in Nix[^arm].
- I later switched to a QEMU-based approach that works with Nix and supports
  ARM[^kvm].

[^arm]: I was running all experiments on the ARM-based Chromebook that I use for couch-computing.
[^kvm]: Because I wanted the build scripts to run within the default `penguin` image, I also [overrode the derivation][12] so that, when `/dev/kvm` is missing, it will fallback to [emulation][13].

After transferring the image to the Chromebook "Downloads" directory I figured
out how to run it from `crosh`:

```bash
vmc start --vm-type BAGUETTE \
  --rootfs /home/chronos/user/MyFiles/Downloads/baguette_rootfs_raw.img \
  --writable-rootfs \
  baguette
```


<div class="todo" markdown="1">

  Why such a weird CLI invocation? Because `vmc create` doesn't recognize yet (as
  of ChromeOS 140) the option `--vm-type`, described [in the `baguette_image`
  README][14]. That flag was added to the source [in August][15] and it will
  probably need a bit more time before making it to production.

</div>

<div class="hint" markdown="1">

  You might have heard about the [`#crostini-containerless` flag][16]. If you
  are trying this at home, you can run `vmc start --vm-type BAGUETTE` even
  without _setting_ it. It only affects what happens when you use the ChromeOS
  UI to launch a Linux guest and, this way, you can try Baguette without
  losing your Crostini containers.

</div>

In order to correctly land to a shell, I symlinked the `usermod` executable
under `/usr/bin` and made sure that a few Unix groups existed, in addition to
the user `chronos` (the default in `termina`). _Within_ the VM, I configured
the DNS to rely on the host and a few environment variables required by the
`crosvm-tools`.

The last piece of the puzzle was how to enable X/Wayland forwarding, which was
failing. By diving into the source code I discovered that the `/dev/wl0` device
was missing read/write permissions for non-root users. A quick `udev` rule
fixed that.

With that fixed as well, we are ready to shine! The {% include github_link.html
url="https://github.com/aldur/nixos-crostini/blob/main/baguette.nix"
text="`baguette.nix`" %} file includes all the configuration in details, if you
are curious. Here is the final result: a `baguette-nixos` VM correctly
forwarding a Wayland session to ChromeOS.

{:.text-align-center}
![A screenshot showing the `baguette-nixos` VM running Featherpad]({% link images/baguette.webp %}){:.centered}
_Wayland forwarding working in a Baguette VM._

### What's next?

The {% include github_link.html url="https://github.com/aldur/nixos-crostini/"
text="`nixos-crostini` repository" %} now includes _experimental_ Baguette
support. If you give it a try, let me know how it goes, I want to hear from
you! You can reach me through any of the links in the footer.

I have marked it as experimental because of a few small issues. On ChromeOS
140, `vmc` cannot yet correctly import Baguette images. For this, we need to
make the rootfs in the Chromebook's Download folder as writable. In addition,
`vsh` (used by `vmc start`) will always spawn a shell using the `chronos` user
(which is then required to exist), even when instructed to do otherwise. I
tried a few configurations (CLI flags for `vmc` or for `vshd`), but nothing
seems to make it. 

None of this should be a deal-breaker, especially if LXD was not giving you
enough flexibility, performance, or control over the underlying (virtualized)
hardware. Meanwhile, I will keep hacking to iron out these last details,
integrate NixOS Baguette into the UI, and allow ourselves to pick the usernames
we like the best.

Thanks for reading, and 'til next time! 👋

#### Footnotes


[0]: https://github.com/aldur/nixos-crostini/issues/1
[1]: https://crosvm.dev/book/devices/virtual_u2f.html
[2]: https://chromium.googlesource.com/chromiumos/overlays/board-overlays/+/HEAD/project-termina/
[3]: https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/vm_tools/vsh
[4]: https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/vm_tools/docs/init.md
[5]: https://chromium.googlesource.com/chromiumos/containers/cros-container-guest-tools/+/refs/heads/main
[6]: https://source.chromium.org/chromiumos/chromiumos/codesearch/+/main:src/platform2/vm_tools/baguette_image/
[7]: https://source.chromium.org/chromiumos/chromiumos/codesearch/+/main:src/platform2/vm_tools/baguette_image/src/setup_in_guest.sh
[8]: https://nix.dev/guides/faq.html#how-to-run-non-nix-executables
[9]: https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
[10]: https://source.chromium.org/chromiumos/chromiumos/codesearch/+/main:src/platform2/vm_tools/baguette_image/src/generate_disk_image.py
[11]: https://github.com/aldur/nixpkgs/blob/7271a39b1cd7d9b6799399dc2fbf1d5a6f16edea/nixos/modules/virtualisation/lxc-container.nix#L67
[12]: https://github.com/aldur/nixos-crostini/blob/2e3318ec0f72d775a22c35929887f93f1f17dbd7/baguette.nix#L236-L237
[13]: https://www.qemu.org/docs/master/devel/index-tcg.html
[14]: https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/vm_tools/baguette_image?autodive=0
[15]: https://chromium.googlesource.com/chromiumos/platform2/+/9a972c766c7
[16]: https://chromium.googlesource.com/chromium/src/+/0d439926c092142a02d96d38cfbb6a68044f2382
