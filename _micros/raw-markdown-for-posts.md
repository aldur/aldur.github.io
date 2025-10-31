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

{%- comment -%}Sorry, Liquid doesn't support regex replacements.{%- endcomment -%}
{% assign last_char = page.url | slice: -1 %}
{% if page.url contains ".html" %}
  {% assign md_url = page.url | replace: ".html", ".md" %}
{% elsif last_char == "/" %}
  {% assign url_length = page.url | size | minus: 1 %}
  {% assign md_url = page.url | slice: 0, url_length | append: ".md" %}
{% else %}
  {% assign md_url = page.url | append: ".md" %}
{% endif %}
```bash
curl {{ md_url | absolute_url }}
```

I haven't done it yet, but it should also be pretty straightforward to add a
Markdown-based sitemap, similarly to what [`llms.txt`][0] proposes.

[0]: https://llmstxt.org
