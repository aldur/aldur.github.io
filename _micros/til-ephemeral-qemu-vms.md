---
title: 'TIL: Ephemeral QEMU VMs'
date: 2025-11-04
tags: [TIL]
---

TIL to use the `-snapshot` QEMU option to make VM disk images read only,
effectively making any change ephemeral. 

I find this particularly useful for running ephemeral NixOS VM guests, instead
of having to configure something like [impermanence][1]. You can set the following
in your configuration to make it happen:

```nix
virtualization.qemu.options = [ "-snapshot" ];
```


From [QEMU's manual][0]:

> If you use the option `-snapshot`, all disk images are considered as read only.
  When sectors in written, they are written in a temporary file created in
  /tmp. You can however force the write back to the raw disk images by using
  the commit monitor command (or <kbd>Ctrl+a s</kbd> in the serial console).

[0]: https://qemu-project.gitlab.io/qemu/system/images.html#snapshot-mode
[1]: https://github.com/nix-community/impermanence
