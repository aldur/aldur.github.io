---
title: 'All Ruby versions in Cloudflare pages'
---

This post originally started as a rant: until late February, Cloudflare Pages'
documentation stated to support _any_ Ruby version (or Python, Node.js, etc.),
but [didn't really][0].

Although the problem was real, my post felt overly negative, not constructive,
and _wrong_. Instead of publishing it, I just opened an [issue in
`cloudflare-docs`][1].

The maintainers have now kindly fixed the issue. Anyone can use _any_ Ruby
version in a Cloudflare Pages build. If the worker doesn't have that version
available, it will automatically download it and compile it (in which case, the
build might take a bit longer).

As for me, this means I can pin my `.ruby_version` to one that is cached in
`nixpkgs` so that I can quickly start writing on low-powered devices.

[0]: https://github.com/aldur/aldur.github.io/pull/116
[1]: https://github.com/cloudflare/cloudflare-docs/issues/27779#event-23112259622
