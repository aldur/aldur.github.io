---
title: "Recovering camera credentials from Synology's Surveillance Station"
date: 2026-07-01
---

Surveillance Station allows managing cameras, recordings, alerts, etc. on
Synology NAS.

I recently noticed that I had lost RTSP credentials for one of my IP cameras.
They weren't in my password manager nor anywhere else I could think of, but the
camera was currently configured and streaming in Surveillance Station. If it
was streaming, then Surveillance Station must have had credentials stored
somewhere.

With a bit of trial and error and some LLM assistance, I recovered the
credentials as follows (Synology 7.3.2, your `volume` might change):

```bash
sqlite3 --readonly /volume1/@appstore/SurveillanceStation/system.db \
  "SELECT name, hostname, port, username, password FROM camera;"
```

The password is prefixed with a `$` and is then (inexplicably) encoded _twice_
in base 64.
