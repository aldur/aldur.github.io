---
title: 'TIL: Ensure ending newlines'
date: 2025-10-09
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

> The output from an entire print statement is called an output record. Each
> print statement outputs one output record, and then outputs a string called
> the output record separator (or ORS). The initial value of ORS is the string
> "\n" (i.e., a newline character). Thus, each print statement normally makes a
> separate line.

This includes the last line, so that it will terminate with a newline
character.
