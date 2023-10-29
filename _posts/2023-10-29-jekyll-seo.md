---
layout: post
title: 'Bare-minimum Google indexing for Jekyll'
categories: articles
---

Searching for this blog on Google with `site:aldur.pages.dev` right now does not
return any results. Let's fix that.

If you think about it, it makes sense. If there are no links pointing to this
blog Google cannot follow them to find it and index it[^analytics]. Luckily we
can gently _welcome_ Google's crawlers here by:

1. Adding a new "property" for this blog to the "Google Search Console".
1. Verifying we own the "property".
1. Ensuring that Google crawlers will find all articles by populating
   `sitemap.xml` and `robots.txt` files.

#### Adding and verifying a new property

[This Google support
page](https://support.google.com/webmasters/answer/34592?hl=en#zippy=%2Cdomain-property-examplecom)
shows how add the property. We are using a [Cloudflare Pages']({% post_url
2023-10-15-migrating-to-cloudflare-pages %}) domain, so we don't control DNS. We
will need to create a URL-prefix property.

To verify the URL-prefix we need to add the following snippet to the `<head>` of
our index:

```html
<meta name="google-site-verification" content="<verification-token-provided-by-Google>" />
```

I first considered doing this by hand, but then found out that the
[jekyll-seo-tag](https://github.com/jekyll/jekyll-seo-tag/) plugin[^seo-tag]
supports this. Adding a `google_site_verification` entry to the {% include
github_link.html url="https://github.com/aldur/aldur.github.io/pull/15"
text="site configuration" -%} marked the verification as complete.

#### Indexing content

Next, we want web crawlers to index all articles. In _theory_ (based on
"how-Google-works-101"), crawlers will follow links as they find them, and
having all articles listed in the blog index should be enough. But who knows
what really goes on behind the scenes?

A [sitemap](https://www.sitemaps.org) provides a more robust solution, listing
all entries in an XML document (similar to an RSS feed). The
[jekyll-sitemap](https://github.com/jekyll/jekyll-sitemap) plugin takes care of
populating it and updating it with new articles.

<div class="warning" markdown="1">
The behaviour of the sitemap plugin depend on the index at which we add it to
Jekyll's `plugins` array in the site configuration.
</div>

<div class="tip" markdown="1">
In my case, I just added it last -- it "knows" _not_ add my RSS feed to the sitemap and I want it to index the rest of the content.
</div>

Last, we [add a `robots.txt`
file](https://developers.google.com/search/docs/crawling-indexing/robots/create-robots-txt)
to inform bots about the sitemap:

```txt
User-agent: *
Sitemap: https://aldur.pages.dev/sitemap.xml
```

Jekyll exposes a `url` configuration entry, which defaults to `localhost` in
development. When deploying on Cloudflare Pages, I override it in a separate
configuration file. We can use Liquid to inject the correct URL using `{{
site.url }}/sitemap.xml`
([credits](https://medium.com/@vilcins/optimize-your-jekyll-powered-website-with-these-simple-steps-b2a24d66a629)).

#### Results

I prepared and merged the {% include github_link.html
url="https://github.com/aldur/aldur.github.io/pull/16" text="changes" -%}. Then,
I refreshed Google's `robots.txt` cache (see
[here](https://developers.google.com/search/docs/crawling-indexing/robots/submit-updated-robots-txt)).

The Search Console tells me it will take a couple of days to index everything.
I will see how that works out and update this article if I find out there's
anything else I need to do.

If you ended up through a Google search: It worked!

#### Footnotes

[^analytics]:
    Unless you use Google Analytics. In that case, I expect that the analytics
    scripts take care of indexing, so you won't need the steps described
    here.

[^seo-tag]:
    The plugin also makes social information and title/excerpts of posts
    available to search crawlers. The default configuration of the [`minima`
    theme](https://github.com/jekyll/minima) [I am using]({% post_url
    2023-10-07-reboot %}) includes it as a suggested dependency.
