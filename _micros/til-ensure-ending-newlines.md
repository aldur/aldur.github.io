---
title: 'TIL: Ensure ending newlines'
date: 2025-10-08
---

For two days in a row, a `git patch` wouldn't apply because it wasn't ending
with a newline.

Here's a quick shell trick to fix that:

```bash
awk 1 file.patch | git apply
```

This clever snippet (suggested by an LLM) uses `awk` to simply print each line
(`1` is a no-op). And `awk` is well-behaved and ensures that every "output
record" ends with a separator, the newline by default.

From its [manual](https://www.gnu.org/software/gawk/manual/gawk.html#Output-Separators-1):

> Thus, each print statement normally makes a separate line.
