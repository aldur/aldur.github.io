---
title: 'Short-lived OpenRouter API keys'
date: 2025-11-30 20:30
---

I have recently started playing with [`simonw/llm`][0] to [query OpenRouter
models][1] and do quick CLI queries without breaking _flow_.

I generally don't like having long-lived API keys somewhere on-disk, because
a rogue executable (or an LLM falling for prompt injection) could easily leak
them. This is the main reason why I don't use the popular `gh` CLI application,
which relies (by default) on a very privileged access token stored on disk.

To avoid this issue altogether, I often work inside throwaway VMs. The downside
is that, each time, I will need to re-authenticate to those services requiring
local credentials (including `llm-openrouter`).

Luckily, OpenRouter allows to [programmatically provision API keys][2], which
makes re-authentication fast and easy. I wrote and host a simple {% include
github_link.html url="https://github.com/aldur/openrouter-provisioner"
text="openrouter-provisioner" %} on one of my nodes, where it is only
accessible through Tailscale (configured on the host, not the guest VM). By
default, it will provision and return API keys expiring after 24h.

With that in place, I can quickly get things running on a new VM:

```bash
llm keys set openrouter --value \
  $(curl -s -X POST https://openrouter | jq -r '.api_key')
```

[0]: https://github.com/simonw/llm
[1]: https://github.com/simonw/llm-openrouter
[2]: https://openrouter.ai/docs/guides/overview/auth/provisioning-api-keys
