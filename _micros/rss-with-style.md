---
title: 'RSS with style'
date: 2025-07-23
---

Clicking on any RSS feed link in this blog will now show a styled page, where
one article nicely lines up after the other. I quite like the result! It reads
like a newspaper and improves the UX: before, clicking on the same links would
either show you a blob of XML or ask you to open an RSS reader external to the
browser.

On a scale from "_I must absolutely ship this!_" to "_No one even knows what
RSS feeds are anyway_", I think to this like _tending_ of my digital garden 🪴.
Rather than something impactful, a relaxing pleasure I entertain while enjoying
a simple craft. Realizing that I could re-use the stylesheet of the main
website and keep things neat and tidy made it better.

You can take a look at the results yourself:

<p><svg class="svg-icon orange" viewbox="0 0 16 16">{% include social-icons/rss.svg.path %}</svg> <a href="{{ site.feed.path | default: 'feed.xml' | absolute_url }}" target="_blank" title="Open the main syndication feed">{{ site.title }}</a></p>
<p><svg class="svg-icon orange" viewbox="0 0 16 16">{% include social-icons/rss.svg.path %}</svg> <a href="{{ "/feed/micros.xml" | absolute_url }}" target="_blank" title="Open the micros syndication feed">µ</a></p>

Technically, the [`jekyll-feed`
plugin](https://github.com/jekyll/jekyll-feed) powering this blog's feeds
supports styling. I added a {% include github_link.html
url="https://github.com/aldur/aldur.github.io/pull/78/files"
text="`feed.xslt.xml` file" %} to the site root and it automatically picked it
up.
