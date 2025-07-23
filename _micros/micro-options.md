---
title: 'options.md'
date: 2025-07-23
---

Friction hinders actions. This is especially true for actions, like writing,
that are "hard" for me to start.

Knowing all this, I try to remove as much friction as I can. For this blog, I
coded a few simple helpers to quickly create the boilerplate for new posts.
One, called `micro`, does this:

```bash
$ micro "This is a new micro blog post!"
Created file "_micros/this-is-a-new-micro-blog-post.md".
```

It "sluggifies" the title and uses it as a filename, creates a new file for the
post, and sets date and title in the frontmatter. Simple! Here is the result:

```txt
# _micros/this-is-a-new-micro-blog-post.md 
---
title: 'This is a new micro blog post!'
date: 2025-07-23
---


```

Until today, calling `micro` would sometime leave me a bit puzzled. It worked,
but in addition to that file I just showed you, it also created _another_ file:
`_micros/options.md`. By looking at the file contents, I could guess it was the
result of an invocation of `micro -options` or something similar. But I never
made that invocation, nor it showed up in the shell history, nor I could find
anything obviously making it by grepping around for `-options`.

To _thicken the plot_, the `options.md` file was not being created reliably
every time, just _some times_. It seemed to appear only whenever I invoked
`micro` with a new title – later on, this turned out to be a wrong assumption.

Today, while on a long flight where I am writing this I decided I had enough
and set off to investigate:

1. At first, I looked at the code for `micro`, but nothing was standing out
   there.
1. Then, I tried `set -x` in `fish` (my shell of choice) to display what the
   helper was doing line by line. Again, nothing.
1. I then tried `bash` and, interestingly, I could not get `options.md` to
   appear. This suggested that the behaviour might be related to `fish` and
   pointed me to the right direction.
1. Somehow, I intuitively associated `-options` to shell completions, thinking
   that maybe the shell would probe for completion candidates _the first time
   the user tried executing something_ by passing `-options` to the executable.

Obviously, this was a wild guess (what if executables are not idempotent?), but
brought me closer to the solution:

```bash
# cd to the `share` folder of the fish Nix derivation
$ cd (dirname (readlink -f /run/current-system/sw/bin/fish))/../share
$ rg " \-options"
fish/completions/vbc.fish
89:complete -c vbc -o optionstrict- -d "Disable -optionstrict"

fish/completions/micro.fish
8:for option in (micro -options | string replace -f -r '^-(\S+)\s.*' '$1')

fish/completions/openssl.fish
5:        openssl list -options $cmd[2] | string replace -r -- '^(\S*)\s*.*' '-$1'
```

Do you see it? There's a built-in `fish` completion for an executable called
`micro`!

`fish` does in fact populate completion candidates for the executable, the
first time it sees it, by calling it with `-options` – but it is a special case
for `micro`, not general behaviour. Had I named my helper differently, I would
have probably never encountered this bug.

With this mystery solved, I'll have one less chance to procrastinate instead of
writing. I have not thought how to solve it yet. I quite like the name `micro`,
so I might just keep it as it, see if I can overwrite that completion function,
or just have the helper handle command line flags better.
