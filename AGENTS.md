# AGENTS.md

## Purpose

This repository contains the **public build system and deployable site** for `blog.clueby4.dev`.

It is intentionally separate from the private Obsidian vault.

Design goals:

- Keep authoring friction low.
- Keep deployment deterministic and boring.
- Prevent accidental publication of drafts.
- Remain compatible with AI/agent-based discovery without depending on any single vendor feature.
- Prefer static output over runtime complexity.

---

# High-Level Architecture

## Repositories

### 1. Private Vault (Windows)
- Contains full Obsidian vault.
- Posts live under: `BLOG/<slug>/<slug>.md`
- Images/assets live alongside the post Markdown.
- Drafts allowed.
- Never exposed directly to Cloudflare.

### 2. Public Repo (This Repo, WSL)
- Located at: `~/blog-publish/`
- Contains:
  - `astro-blog/` (Astro site project)
  - `BLOG/` (exported, publishable posts only)
  - `llms.txt` (generated during publish)
  - `publish.sh` (export + build + push orchestrator)

Cloudflare Pages builds from this repo.

---

# Content Model

## Canonical URL Structure

Each post:

- HTML: `https://blog.clueby4.dev/<slug>/`
- Markdown mirror: `https://blog.clueby4.dev/<slug>/index.md`

The HTML page is canonical.
The Markdown mirror exists for agent/LLM-friendly ingestion.

---

# Frontmatter Standard (Canonical)

YAML frontmatter is required.

Example:

```yaml
---
title:
seo_title:
description:
slug: "example-post"
canonical: "https://blog.clueby4.dev/example-post/"
og_image: "/example-post/og.jpg"
tags:
  - security
noindex: false
draft: true
date:
updated:
---
```

## Rules

- `draft: true` → NEVER exported to public repo.
- `draft: false` + `date:` set → eligible for export.
- `tags` must be a YAML list (block format).
- Default umbrella tag: `security`.
- `slug` must match folder name.
- `canonical` must match final URL.

---

# Publish Flow

## Trigger

`publish.bat` (Windows vault root):

- Starts WSL in vault root.
- Exports `VAULT_ROOT`.
- Calls `~/blog-publish/publish.sh`.

## publish.sh Responsibilities

1. Read vault content from `$VAULT_ROOT/BLOG`.
2. Export only posts where `draft: false`.
3. Copy sibling assets.
4. Generate `llms.txt`.
5. Run `npm run build` inside `astro-blog/`.
6. Commit and push changes.

## Guardrails

- Hard fail if `draft: true` exists in public repo.
- Warn (do not delete) if stale folders exist.
- Build failure blocks deploy.

Cloudflare deploys on push.

---

# Astro Design Principles

- `astro-blog/` contains the static site project.
- Output mode: static.
- No islands by default.
- No runtime backend.
- No server components.
- No unnecessary client-side JS.

Interactivity should only be added when clearly justified.

---

# AI / Agent Considerations

This site is designed to be agent-compatible without depending on vendor-specific features.

## llms.txt

Generated during publish.

Includes:
- Canonical mapping
- Markdown mirror rule
- Entry points (index, RSS, sitemap)

Spec reference: https://llmstxt.org/

## Markdown Mirrors

Each post has:

```
/<slug>/index.md
```

These:
- May contain minimal frontmatter.
- Should remain structurally stable.
- Must match HTML content semantically.

## RSS + Sitemap

- `rss.xml` for incremental discovery.
- `sitemap.xml` for full URL enumeration.

These remain the primary discovery mechanisms.

Cloudflare AI Index or similar features may be enabled later but are not assumed.

---

# Non-Goals

- No CMS.
- No dynamic runtime.
- No server-side user state.
- No comments system (Hashnode may host discussion separately).
- No platform lock-in.

---

# Future Roadmap

Potential additions:

- RSS auto-generation from frontmatter.
- Sitemap validation during publish.
- Validation script to enforce frontmatter schema.
- Minimal metadata stripping for Markdown mirrors.
- Automated syndication to Hashnode.
- Optional search index (static).
- Content linting (dead links, missing og images).
- `llms-full.txt` generation (recent posts only).

---

# Operational Principles

- Prefer explicit over implicit.
- Prefer static over dynamic.
- Prefer reproducible builds.
- Prefer failure over silent corruption.
- Never publish drafts accidentally.

---

# Success Criteria (Inferred)

- Drafts cannot reach production.
- One command performs export + build + push.
- Cloudflare builds succeed consistently under pinned Node version.
- HTML and Markdown mirrors remain in sync.
- Agents can discover content via llms.txt, RSS, and sitemap.
- Vault and public repo remain cleanly separated.

---

# Human Factors

- Authoring must remain frictionless in Obsidian.
- Publishing should require deliberate intent (flip draft + run publish).
- Warnings must not silently delete content.
- Future-you must understand the structure in 2 years.
- Complexity should only increase when justified by real need.

---

End of file.