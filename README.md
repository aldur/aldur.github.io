# Universal Bits

Personal blog, powered by [Jekyll][0] and the [Minima][4] theme.

## Making changes

- `new "Post Title"` creates a new post.
- `micro "Micro Title"` creates a new micro post.

Both commands will set the current date and a _slugify_ the filename.

## Building it

Install [Nix][1] and enable [flakes][2]. Then, run `nix run`. 

### Developing

- `nix develop` (or `direnv allow`) will prepare and enter an environment with
  everything you need.
- `bundler update` will update your Gems. `bundler` is configured to use the
  `vendor` directory, so that it won't try installing it under `nix` store.
- `nix run '.#lock'` will generates the `gemset.nix` file from `Gemfile.lock`.
- `nix flake check` will test the build and run linters.

## Features

### Tags and indexes

Tag posts in their frontmatter with `tags: [tag1, tag2]`. Tags only appear on
posts if there exists a corresponding tag index page. Create one at
`_tag_indexes/<tagname>.md` with:

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
scrolling.

### Viewing posts as Markdown

View the markdown source of any post by changing its URL to end with `.md`:

- `page.html` → `page.md`
- `page/` → `page.md`
- `page` → `page.md`

### Custom redirects

Use [`jekyll-redict-from`][3] to add multiple URLs for a page.

```yaml
redirect_from:
  - /short-link
```

### Theme

[Minima's][4] default color follows the user's system preference (light/dark).
The toggle icon overrides it.

[0]: https://jekyllrb.com
[1]: https://nixos.org
[2]: https://nixos.wiki/wiki/Flakes
[3]: https://github.com/jekyll/jekyll-redirect-from
[4]: https://github.com/jekyll/minima
