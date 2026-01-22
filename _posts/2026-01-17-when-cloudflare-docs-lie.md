---
title: 'When Cloudflare docs lie'
excerpt: >
  Supporting all versions of a runtime or tool doesn't sound real, and it isn't.
---

Back in 2023, [I migrated this blog to the _very convenient_ Cloudflare
Pages]({% post_url 2023-10-15-migrating-to-cloudflare-pages %}). Its generous
free tier offers more than enough for this blog and, so far, it hasn't required
any maintenance at all. It allows me to focus on writing instead of
procrastinating ways to host this blog.

On the other side of that convenience there's Cloudflare's quasi-monopoly of
today's Internet. We are not here to talk about it today, although it has been
sitting in the back of my mind for some time. Instead, today we'll talk about
Cloudflare's docs.

First, some context. Pages is _also_ convenient because it integrates with
GitHub through a GitHub Application. Every time I `git push` to a branch,
Cloudflare clones the code, runs `jekyll build`, and hosts the resulting assets
under a subdomain of my Pages project. Cloudflare's Application takes care of
mutual authentication with GitHub, so that I avoid managing long-lived secrets in
CI. It works reliably, is secure enough, and is pretty neat.

Things become a bit rough if you need to customize _where_ Cloudflare runs
`jekyll build`. Both Jekyll and its plugins require Ruby and a few Gems
(dependencies, in Ruby's lingo). [`nix` deals with it for me locally]({%
post_url 2023-10-12-jekyll-nix %}) and prepares a developer environment that
has all I need. To pick which Ruby version to use, I can either pull a binary
of the latest version from `nixpkgs`' cache or compile an older version myself.

Compiling Ruby is relatively fast (for modern software), but still requires a
few minutes of heavy computation and a bit of energy on a "cold" machine. I
often use ephemeral environments; sometimes, on old, low-powered devices.
When I feel like writing, I want to remain in the flow and avoiding
distractions. That's why I want a frictionless writing environment, that is
quick to spin up and ready to use.

This means pulling a recent Ruby binary from Nix's cache. And, because I want
my environment to match production as much as possible, it also means
configuring Cloudflare to use the same Ruby version.

Is that even possible? Yes. According to [Cloudflare's docs][0], creating a
`.ruby-version` file in the root folder is enough. Which versions are
supported? _All of them_:

{:.text-align-center}
![A screenshot from Cloudflare Pages docs stating support for _any_ Ruby version]({% link /images/cloudflare-languages.webp %}){:.centered style="width: 80%; border-radius: 10px;"}
_A screenshot from Cloudflare Pages docs stating support for any Ruby version._

This, in particular, felt _too good to be true_. And, in fact, it isn't!

> Under Supported versions, "Any version" refers to support for all versions of
> the language or tool including versions newer than the Default version.

When I tried [bumping the default Ruby version][1], I found that Cloudflare
only supports Ruby up to version `3.4.4` today. To figure that out, I had to
manually try decreasing versions from `3.4.8` (latest), until I stopped getting
the following error:

```txt
08:24:04.528 Detected the following tools from environment: ruby@3.4.5
08:24:04.529 Installing ruby 3.4.5
08:24:04.743 Version not found
08:24:04.743
08:24:04.743 If this is a new Ruby version, you may need to update the plugin:
08:24:04.744 asdf plugin update ruby
08:24:04.751 Error: Exit with error code: 1
08:24:04.751     at ChildProcess.<anonymous> (/snapshot/dist/run-build.js)
08:24:04.751     at Object.onceWrapper (node:events:652:26)
08:24:04.751     at ChildProcess.emit (node:events:537:28)
08:24:04.751     at ChildProcess._handle.onexit (node:internal/child_process:291:12)
08:24:04.760 Failed: build command exited with code: 1
08:24:05.924 Failed: error occurred while running build command
```

I had a feeling that the docs were too good to be true because supporting _all_
versions of a runtime requires a lot of work and isn't realistic or cost
effective (especially for a free offering). Some versions are so old they are
no longer maintained (e.g., Python 2). Others have known vulnerabilities and
have been pulled from distribution. Even _new_ versions take [months][3] before
they become available in Pages: someone needs to notice the release and deploy
the necessary changes to production to make it available to customers.

Instead, I would have preferred the docs to clearly state which version is
available, encouraging users with other needs to build locally and [upload the
resulting assets directly][2].

I am not keen to go that route myself, because I don't want to add a Cloudflare
API key to CI, where it risks leaking and compromising this blog's integrity.
Instead, I allowed the _patch_ number of Ruby's version to differ between
Cloudflare and `nixpkgs`. This way, the development environment still _loosely_
matches production, but I can save minutes and power to prioritize a
frictionless writing experience.

[0]: https://developers.cloudflare.com/pages/configuration/build-image/#supported-languages-and-tools
[1]: https://github.com/aldur/aldur.github.io/pull/116
[2]: https://developers.cloudflare.com/pages/how-to/use-direct-upload-with-continuous-integration/
[3]: https://community.cloudflare.com/t/timeline-for-adding-ruby-3-3-1-support/651837
