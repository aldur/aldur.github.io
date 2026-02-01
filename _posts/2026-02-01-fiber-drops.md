---
title: 'fiber-drops'
excerpt: >
  TODO
---

I recently upgraded my home network to gigabit internet provided by O2, the
low-cost brand of Movistar Spain. They run fiber to the home ([FTTH][0]) and
lease consumers their routers to convert the optical signal into an electric
one.

In my case, I got a Mitrastar HGU (`GPT-2742GX4X5 v6`) router. ISP routers give
me security and privacy concerns and, where possible, I prefer to replace them
with something I can control, like my own router running OpenWRT.

Because my OpenWRT router doesn't have an [ONT][1], I cannot connect it
directly to fiber. Instead, I configured the HGU in _bridge_ network mode and
connected a LAN port to the WAN on my router. Then, in OpenWRT, I configured
the required PPoE credentials and created a VLAN. I got online, made a few
speed measurements, and ensured that everything was working great. After a few
minutes I noticed that the connection dropped, but I brushed it off as the
network stabilizing. When that happened a couple more times, though, I started
noticing a pattern:

[Picture of connection dropping exactly every two hours.]

[`rddtool` in OpenWRT][2] showed that the connection was dropping exactly every
two hours. After ensuring that the issue wasn't on OpenWRT's side, I turned the
investigation to the HGU router: Mitrastar firmware have a [history][3] of bugs
and it is also likely that bridge mode isn't battletested (few users need it).

ISP routers are usually a mixed bag in terms of debug access. This one is a bit
weirder than usual:

1. Default user `1234` can `ssh` with a password printed on the router.
1. Which, by default, drops the user into a restricted shell.
1. Unless using `ssh 1234@192.168.1.1 /bin/sh` to get a better shell.

```bash
$ ssh 1234@192.168.1.1
1234@192.168.1.1's password:
>ls
Can't find command: [ls]. Type '?' for usage
>?
>?
<c-d>
$ ssh 1234@192.168.1.1 /bin/sh
1234@192.168.1.1's password:
ls
rom-t
busybox
BusyBox v1.26.2 (2025-06-19 15:12:31 CST) multi-call binary.
...
```

User `1234` is technically `root`. The shell is based on `busybox` and
half-broken (there are no prompts and `ls` doesn't show the full directory
listing). However, after a lot of digging, I discovered that the router holds
its configuration in memory at `/tmp/var/pdm/config.xml`. The configuration
refers to a watchdog:

```xml
<X_TELEFONICA_COM_Watchdog>
  <Enable PARAMETER="configured" TYPE="boolean">1</Enable>
  <PPP>
    <LookupDomain PARAMETER="configured" TYPE="string">hgu.rima-tde.net</LookupDomain>
    <MaxReset PARAMETER="configured" TYPE="uint32">1</MaxReset>
    <AlertAfter PARAMETER="configured" TYPE="uint32">2</AlertAfter>
    <WD_CheckChange PARAMETER="configured" TYPE="uint32">900</WD_CheckChange>
  </PPP>
  <Info>
    <Process PARAMETER="configured" TYPE="string">pppd;ztr69;zebra;ripd;zywifid;igmpproxy;voiceApp;tefdog</Process>
  </Info>
</X_TELEFONICA_COM_Watchdog>
```

The watchdog itself should be `tefdog`. My guess was that, when running in
bridge mode, some health checks would fail and restart the connection. `pppd`,
in particular, doesn't even run in bridge mode but remains one of the monitored
processes.

To test the hypothesis of a badly configured watchdog I first tried to `kill`
it and wait. That did not work, because PID `1` would restart it after a few
minutes. Becuse the file-system on the router is read-only, I couldn't edit the
executable directly. But I could use a bind mount _over_ it:

```bash
echo '#!/bin/sh' > /tmp/tefdog_fake
echo 'exit 0' >> /tmp/tefdog_fake
chmod +x /tmp/tefdog_fake
mount --bind /tmp/tefdog_fake /usr/bin/tefdog
```

At this point, I killed it again, ensured it would not restart, and waited for
a few hours to see if the connection would drop. When it didn't, I knew I had
found the issue!

The bind mount hack, however, wouldn't survive a reboot. After a power loss,
the router would restart and the watchdog would resume killing the connection
every two hours. I kept poking around for ways to persist the change or to
overwrite the router configuration, until I remembered that, usually, a
router's web interface allows backing up and re-uploading the configuration. In
some cases, uploading a modified configuration would also unlock further
functionalities or modify settings not available through the web interface.

I went ahead, exported the configuration, and quickly discovered that it is
encrypted:

```bash
$ file romfile.cfg
romfile.cfg: openssl enc'd data with salted password
```

I mentioned that this router is a bit _weird_, didn't I? `ssh` provides `root`
access, but only if you know which process to launch. You can read the
configuration, but the export is encrypted. After a bit more digging,
I found out where the configuration is decrypted:

```bash
/usr/bin/ccc_preload.sh: openssl aes-256-cbc -md MD5 -k $2 -d \
  -in /usr/etc/smt.cfg -out /var/pdm/config.xml
# NOTE: I added the line break for readability.
```

Later on, I found the encryption password to be a `base64` encoding of 24
(random?) bytes:

```bash
$ grep ENCRYPT /etc/MLD_Config.sh
MLD_APPS_ENABLE_ENCRYPT_CONF_FILE_KEY=zRUqIM1VCqPBrlYbf6CXiOZoZwiIAMHJ
# NOTE: this isn't my encryption key, but a similar-looking one.
```

I don't have another router to check whether this password is hardcoded into
the firmware or generated depending on the hardware (e.g., the MAC address).
Out of abundance of caution I haven't shared the exact key I found on my
router, but feel free to [reach out](mailto:{{ site.author.email }}) if you are
interested in it.

After testing the decryption key, I modified the configuration by disabling the
watchdog.

#### Footnotes

[0]: https://en.wikipedia.org/wiki/Fiber_to_the_x
[1]: https://en.wikipedia.org/wiki/Network_interface_device#Optical_network_terminals
[2]: https://openwrt.org/docs/guide-user/luci/luci_app_statistics
[3]: https://forocoches.com/foro/showthread.php?t=7024832
