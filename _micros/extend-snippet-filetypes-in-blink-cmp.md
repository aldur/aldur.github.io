---
title: 'Extend snippet filetypes in blink.cmp'
date: 2025-07-28
---

[`blink.cmp`](https://github.com/Saghen/blink.cmp) is a completion plugin for
Neovim. It ships with [lazyvim](https://www.lazyvim.org) and is pretty nice.

Among its many sources, it completes
[snipepts](https://cmp.saghen.dev/configuration/snippets.html), by default
from the [`friendly-snippets`](https://github.com/rafamadriz/friendly-snippets)
repository, which provides snippets by language (e.g., `markdown`) and by
framework (e.g., `jekyll`).

Framework support is disabled by default and needs to be explicitly enabled.
There was no documentation on how to do that for `blink.cmp`, but the code had
built-in support for it through the [`extended_filetypes` configuration
option](https://github.com/Saghen/blink.cmp/blob/aeba0f03985c7590d13606ea8ceb9a05c4995d38/lua/blink/cmp/sources/snippets/default/init.lua#L5).
It was there all along, just a bit undocumented!

```lua
--- @field extended_filetypes? table<string, string[]>
```

I figured this out by doing a quick code dive. Then, I updated my configuration
to enable extended Markdown snippets in Jekyll and {% include github_link.html
url="<https://github.com/Saghen/blink.cmp/pull/2041>" text="submitted a PR" %}
to improve the docs.

Here is how to extend filetypes in [`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
return {
 {
  "saghen/blink.cmp",
  opts = {
   sources = {
    providers = {
     snippets = {
      opts = {
       extended_filetypes = { markdown = { "jekyll" } },
      },
     },
    },
   },
  },
 },
}
```
