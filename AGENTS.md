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

# Current Implementation Status

## Done

- `publish.sh` — export + build + push orchestrator with draft guardrails
- `preview.sh` / `preview.bat` — live preview from vault (drafts included, nothing committed)
- `astro-blog/` — Astro 5.x static site, wired to content:
  - `src/content.config.ts` — `blog` collection via `glob()` loader; `CONTENT_DIR` env var controls source path
  - `src/pages/index.astro` — post listing with preview-mode draft visibility
  - `src/pages/[slug]/index.astro` — per-post page with rendered Markdown
  - `src/pages/[slug]/index.md.ts` — Markdown mirror endpoint (`/<slug>/index.md`)
  - `src/pages/tags/[tag]/index.astro` — per-tag index pages
  - `src/pages/rss.xml.ts` — RSS feed
  - `@astrojs/sitemap` — auto-generates `sitemap.xml` from static routes
  - `src/layouts/Layout.astro` — SEO head (meta, OG, canonical, robots, RSS autodiscovery)
- `llms.txt` — generated during publish

## Not Done Yet

- **Styling** — current styles are minimal/functional placeholders; no design system, no typography polish, no dark/light theming
- **Integrations** — no syntax highlighting (Shiki config), no reading time, no prev/next post nav
- Frontmatter validation script (pre-publish lint)
- Automated syndication to Hashnode
- Content linting (dead links, missing og images)
- `llms-full.txt` generation (recent posts only)
- Sitemap validation during publish
- Search index (static)
- No posts in `BLOG/` yet — vault frontmatter still being massaged

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
  - `preview.sh` (live preview from vault, drafts included)
  - `preview.bat` (Windows trigger for preview.sh)

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
- Files matching `Untitled*` are silently ignored by the content loader (covers Obsidian scratch files).

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

`PUBLIC_REPO_DIR` is derived from the location of `publish.sh` (`BASH_SOURCE[0]`), not `$PWD`. Can be overridden via env var.

## Guardrails

- Hard fail if `draft: true` exists in public repo after export.
- Warn (do not delete) if stale folders exist.
- Build failure blocks deploy.

Cloudflare deploys on push.

---

# Preview Flow

## Purpose

View any vault post — including drafts — rendered by Astro before committing anything.

## Trigger

`preview.bat` (Windows vault root) or directly:

```sh
VAULT_ROOT=/mnt/c/path/to/vault ~/blog-publish/preview.sh
# or
~/blog-publish/preview.sh /mnt/c/path/to/vault
```

## How it works

- Sets `CONTENT_DIR=$VAULT_ROOT/BLOG` — Astro reads directly from the live vault.
- Sets `ASTRO_PREVIEW=true` — disables draft filter; shows all posts with a visible draft banner.
- Runs `npm run dev` inside `astro-blog/`.
- Does NOT write to `BLOG/`, does NOT commit, does NOT push.

## Key env vars

| Variable | Where used | Purpose |
|---|---|---|
| `VAULT_ROOT` | `publish.sh`, `preview.sh` | Path to Obsidian vault root |
| `PUBLIC_REPO_DIR` | `publish.sh` | Path to this repo (defaults to script dir) |
| `CONTENT_DIR` | `astro-blog/src/content.config.ts` | Path to `BLOG/` directory fed to glob loader |
| `ASTRO_PREVIEW` | Astro pages | `"true"` enables draft visibility |

---

# Astro Design Principles

- `astro-blog/` contains the static site project.
- Node version: `22.x` (via nvm, `.nvmrc` at repo root).
- Output mode: static.
- No islands by default.
- No runtime backend.
- No server components.
- No unnecessary client-side JS.

Interactivity should only be added when clearly justified.

---

# Astro Site Structure

```
astro-blog/
  astro.config.mjs         # site URL, sitemap integration
  src/
    content.config.ts      # blog collection, CONTENT_DIR-aware glob loader
    layouts/
      Layout.astro         # SEO head, OG tags, canonical, RSS autodiscovery
    pages/
      index.astro          # post listing (respects ASTRO_PREVIEW draft filter)
      rss.xml.ts           # RSS feed
      [slug]/
        index.astro        # per-post page + draft banner in preview mode
        index.md.ts        # Markdown mirror endpoint (draft:false only)
      tags/
        [tag]/
          index.astro      # per-tag post listing
```

Content source path is controlled by `CONTENT_DIR` env var (default: `../BLOG` relative to `astro-blog/`). This is the only mechanism needed to switch between production content and live vault preview.

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
- Served via Astro endpoint (not a literal `.md` file) to avoid double-processing.
- Draft posts are never served at this endpoint.
- Should remain structurally stable.
- Must match HTML content semantically.

## RSS + Sitemap

- `rss.xml` for incremental discovery.
- `sitemap.xml` auto-generated by `@astrojs/sitemap` from all static routes.

These remain the primary discovery mechanisms.

---

# Non-Goals

- No CMS.
- No dynamic runtime.
- No server-side user state.
- No comments system (Hashnode may host discussion separately).
- No platform lock-in.

---

# Future Roadmap

- Styling / design pass (typography, spacing, code blocks, dark theme)
- Syntax highlighting configuration (Shiki themes)
- Frontmatter validation script (pre-publish lint, enforce schema)
- Content linting (dead links, missing og images)
- `llms-full.txt` generation (recent posts only)
- Sitemap validation during publish
- Automated syndication to Hashnode
- Optional static search index
- Reading time + prev/next post navigation

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
- Preview of any post (including drafts) is possible without touching the public repo.

---

# Human Factors

- Authoring must remain frictionless in Obsidian.
- Publishing should require deliberate intent (flip draft + run publish).
- Warnings must not silently delete content.
- Future-you must understand the structure in 2 years.
- Complexity should only increase when justified by real need.

---

End of file.
