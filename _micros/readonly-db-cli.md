---
title: "Read-only sqlite DBs from the CLI"
date: 2025-06-20
---

Honoring the [principle of least
privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege), I
prefer to open `sqlite` DBs in read-only mode when peeking at the data through
the CLI, to avoid unexpected modifications.

The CLI provides a `-readonly` flag:

```bash
sqlite3 --help |& grep readonly
   -readonly            open the database read-only
```

Also TIL about `|&` to pipe both std-out and std-err, tested in `fish` and `bash`.
