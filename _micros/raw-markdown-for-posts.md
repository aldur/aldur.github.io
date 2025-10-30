---
title: 'View posts as Markdown'
date: 2025-10-30
---

I have just added a small Jekyll plugin to this blog that allows viewing posts
in Markdown (rather than HTML). To see it in action, add an `.md` extension to
any post link to fetch the raw Markdwon. This is how it looks for [this
post]({{ page.url | replace: ".html", ".md" | relative_url }}).

The Markdown layout is useful for LLMs (that can parse it while being more
token-efficient), but also for those that want to consume content their own way
(for instance, this now allows to quickly read posts through `curl`):

```bash
curl {{ page.url | replace: ".html", ".md" | absolute_url }}
```

I haven't done it yet, but it should also be pretty straightforward to add a
Markdown-based sitemap, similarly to what [`llms.txt`][0] proposes.

[0]: https://llmstxt.org
