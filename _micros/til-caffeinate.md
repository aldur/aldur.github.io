---
title: 'TIL: Caffeinate keeps macOS awake'
date: 2025-10-24
tags: [TIL]
---

I am probably pretty late to this one, but on macOS you can use `caffeinate` to
prevent the system from sleeping.

I often use `-d` to keep the display awake:

```bash
caffeinate -d
```

Use `man caffeinate` for all options.

For years, I used a [custom Hammerspoon integration][0] that also displays a
nice menubar icon while "caffeinating" (under the hood it uses the same APIs). 
Since I often use "vanilla" macOS instances, it's great to know there's a native
alternative.

[0]: https://github.com/aldur/dotfiles/blob/f8241f985d969acd5bc871220fd0382ce8cfa979/osx/hammerspoon/seal_plugins/seal_hammerspoon.lua#L50-L64
