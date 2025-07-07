---
title: 'Zap-It + Miniflux > Pocket'
date: 2025-07-07
---

Three weeks ago, Mozilla
[announced](https://support.mozilla.org/en-US/kb/what-is-pocket) that Pocket
will shut down tomorrow. The web received the news with disappointment: Pocket
was widely used and loved.

While many started evaluating alternatives, I won't need to. I have used Pocket
in the past, but two years ago I [switched]({% link _posts/2023-10-07-zap-it.md
%}) to a self-hosted solution rocking [Miniflux](https://miniflux.app) and
[Zap-It](https://github.com/aldur/zap-it), a thin Rust wrapper around an SQLite
DB that serves an RSS feed. Miniflux subscribes to the RSS feed, downloads the
full page content and makes it available for reading.

After "zapping" hundreds of articles, I am satisfied with the results.

The stack requires minimum maintenance, has a light footprint, and works
offline thanks to the [Reeder Classic app](https://reederapp.com/classic/).
Most importantly, I do not depend on any external service to consume
my reading list. 

The downsides of self-hosting are usually around maintenance and availability.
I monitor uptime of my setup through
[Uptime-Kuma](https://github.com/louislam/uptime-kuma) and have just checked
the numbers. Over the last year, Miniflux was up 99.9% of the time.
Not bad for a self-hosted instance with a single customer, myself.
