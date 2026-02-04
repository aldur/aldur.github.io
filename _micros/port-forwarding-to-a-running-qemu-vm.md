---
title: 'Port forwarding to a running QEMU VM'
date: 2026-02-04
---

If you are running a QEMU VM with `-qmp` ([QEMU Machine Protocol][0]), then you
can add port-forwarding to it while running as follows:

```bash
echo '{ "execute": "qmp_capabilities" }
  { "execute": "human-monitor-command", "arguments": { "command-line": "hostfwd_add tcp::2222-:22" } }' | socat - UNIX-CONNECT:/path/to/qmp.sock
```

[0]: https://wiki.qemu.org/Documentation/QMP
