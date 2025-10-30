# Universal Bits

Personal blog, powered by [Jekyll][0] and the [Minima][4] theme.

## Features

### Tags

Tag posts in their frontmatter with `tags: [tag1, tag2]`. Tags only appear on
posts if there exists a corresponding tag index page. Create one at
`tag_indexes/<tagname>.md` with:

```yaml
---
tag: tagname
---
```

The tag layout filters all posts with that tag. 

### Excerpts

Configure whether excerpts show (by order of priority):

1. Per post (with `show_excerpt: ` in the frontmatter).
1. Per collection (in `_config.yml`, under `collections:`).
1. Default: the value of `show_excerpts: ` in `_config.yml` under `minima:`.

### RSS Feeds

RSS feeds are styled to mimic the main blog style and read through continuous
scrolling. The stylesheet is at `feed.xslt.xml`.

### View post as `.md`

View the markdown source of any post by:

- Swapping `.html` for `.md` in the URL
- Adding `.md` if there's no extension

### Custom redirects

Use [`jekyll-redict-from`][3] to add multiple URLs for a page.

```yaml
redirect_from:
  - /short-link
```

### Theme

[Minima's][4] default color follows the user's system preference (light/dark).
The toggle icon overrides it.

## Making changes

- `new "Post Title"` creates a new post.
- `micro "Micro Title"` creates a new micro post.

Both commands will set the current date and a _slugify_ the filename.

## Building it

Install [Nix][1] and enable [flakes][2]. Then, `nix run`. Optionally, enable
`direnv allow`.

### Developing

- Running `nix develop` (or entering the directory with `direnv`) will prepare
  and enter an environment with everything you need.
- Running `bundler update` will update your Gems. `bundler` is configured to
  use the directory `vendor`, so that it try installing it under `nix` store.
- `nix run '.#lock'` generates `gemset.nix` from `Gemfile.lock`.
- `nix flake check` tests the build and runs linters.

[0]: https://jekyllrb.com
[1]: https://nixos.org
[2]: https://nixos.wiki/wiki/Flakes
[3]: https://github.com/jekyll/jekyll-redirect-from
[4]: https://github.com/jekyll/minima
