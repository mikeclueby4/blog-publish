# AGENTS.md

## Purpose

This repository contains the **public build system and deployable site** for `blog.clueby4.dev`.

> **Note:** `blog.clueby4.dev` is currently live on **Hashnode** while this Astro build is being developed and styled. The domain will be cut over to Cloudflare Pages (serving this repo's output) once it is ready. Agents and tools seeing content on the live domain should be aware it does not yet reflect this repo's output.

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
- `astro-blog/` — Astro 5.x static site based on **AstroPaper** theme (v5.5.1) — see `AstroPaper-upstream-instructions.md` for the full delta and upgrade procedure:
  - **Theme**: AstroPaper — Tailwind CSS v4, dark/light mode (auto + toggle), accessible, responsive
  - **Syntax highlighting**: Shiki with `min-light` / `night-owl` themes, diff/highlight/filename transformers
  - **Prev/Next post navigation**: built into `PostDetails.astro`
  - **Pagefind** static search (postbuild step, no runtime server)
  - **Sticky ToC sidebar**: two-column layout on post pages (h2/h3 headings, collapses on mobile)
  - `src/content.config.ts` — `blog` collection via `glob()` loader; `CONTENT_DIR` env var controls source path
  - `src/pages/index.astro` — post listing with preview-mode draft visibility
  - `src/pages/[slug]/index.astro` — per-post page (flat URL, not `/posts/[slug]/`)
  - `src/pages/[slug]/index.md.ts` — Markdown mirror endpoint (`/<slug>/index.md`)
  - `src/pages/tags/[tag]/[...page].astro` — per-tag index pages with pagination
  - `src/pages/posts/[...page].astro` — paginated post listing
  - `src/pages/archives/index.astro` — chronological archive
  - `src/pages/rss.xml.ts` — RSS feed
  - `@astrojs/sitemap` — auto-generates `sitemap.xml` from static routes
  - `src/layouts/Layout.astro` — SEO head (meta, OG, canonical, robots, RSS autodiscovery, JSON-LD structured data)
  - `src/layouts/PostDetails.astro` — post layout with ToC, prev/next, share links, progress bar
- `llms.txt` — generated during publish

## Not Done Yet

- Frontmatter validation script (pre-publish lint)
- Automated syndication to Hashnode
- Content linting (dead links, missing og images)
- `llms-full.txt` generation (recent posts only)
- Sitemap validation during publish
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
- Sets `BLOG_PREVIEW=true` — disables draft filter; shows all posts with a visible draft banner.
- Runs `npm run dev` inside `astro-blog/`.
- Does NOT write to `BLOG/`, does NOT commit, does NOT push.

## Key env vars

| Variable | Where used | Purpose |
|---|---|---|
| `VAULT_ROOT` | `publish.sh`, `preview.sh` | Path to Obsidian vault root |
| `PUBLIC_REPO_DIR` | `publish.sh` | Path to this repo (defaults to script dir) |
| `CONTENT_DIR` | `astro-blog/src/content.config.ts` | Path to `BLOG/` directory fed to glob loader |
| `BLOG_PREVIEW` | Astro pages | `"true"` enables draft visibility |

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

Based on **AstroPaper** theme (github.com/satnaing/astro-paper), customised for this site.

```
astro-blog/
  astro.config.ts          # site URL, sitemap, Shiki, Tailwind v4
  src/
    config.ts              # SITE config (title, author, OG, theme toggle, etc.)
    constants.ts           # social links
    content.config.ts      # blog collection, CONTENT_DIR-aware glob loader
    layouts/
      Layout.astro         # SEO head, OG, canonical, JSON-LD, RSS autodiscovery, theme
      PostDetails.astro    # post layout: ToC sidebar, prev/next, share, progress bar
      Main.astro           # generic page layout wrapper
      AboutLayout.astro    # about page layout
    pages/
      index.astro          # home page (respects BLOG_PREVIEW draft filter)
      about.md             # about page
      search.astro         # Pagefind search UI
      rss.xml.ts           # RSS feed
      robots.txt.ts        # robots.txt
      [slug]/
        index.astro        # per-post page + draft banner in preview mode
        index.md.ts        # Markdown mirror endpoint (draft:false only)
      posts/
        [...page].astro    # paginated post listing
      tags/
        [tag]/
          [...page].astro  # per-tag post listing with pagination
      archives/
        index.astro         # chronological archive
    components/             # Header, Footer, Card, Datetime, Tag, Pagination, etc.
    utils/                  # getPath, getSortedPosts, postFilter, slugify, etc.
    styles/
      global.css            # Tailwind v4 theme (CSS custom properties for light/dark)
      typography.css        # prose/typography styles
    scripts/
      theme.ts              # dark/light mode logic
```

Content source path is controlled by `CONTENT_DIR` env var (default: `../../BLOG` relative to `src/`). This is the only mechanism needed to switch between production content and live vault preview.

## Key Customisations from Stock AstroPaper

- **URL routing**: Posts at `/<slug>/` (not `/posts/<slug>/`)
- **Frontmatter schema**: Uses vault schema (`date`/`updated`/`slug`/`canonical`/`og_image`/`seo_title`/`noindex`) instead of AstroPaper's (`pubDatetime`/`modDatetime`/`canonicalURL`/etc.)
- **Content source**: `CONTENT_DIR` env var + vault-aware glob pattern (`*/*.md`)
- **Draft handling**: `BLOG_PREVIEW` env var for preview mode with visible draft banners
- **Markdown mirror**: `/<slug>/index.md` endpoint for agent/LLM ingestion
- **Sticky ToC sidebar**: Two-column CSS grid layout on post pages
- **Dynamic OG disabled**: Uses explicit `og_image` frontmatter field
- **Edit post disabled**: No public GitHub source for posts

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

- Frontmatter validation script (pre-publish lint, enforce schema)
- Content linting (dead links, missing og images)
- `llms-full.txt` generation (recent posts only)
- Sitemap validation during publish
- Automated syndication to Hashnode
- Reading time display
- Colour scheme customisation (current: AstroPaper defaults)
- Integration with "AI index" platforms (e.g. https://www.pinecone.io/ai-indexing/, cloudflare's AI search, etc.) without compromising the static site output or content model

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
- Fallback to basic MD->HTML generation and hosting on any static platform ALWAYS HAS TO REMAIN possible.

---

# Human Factors

- Authoring must remain frictionless in Obsidian.
- Publishing should require deliberate intent (flip draft + run publish).
- Warnings must not silently delete content.
- Future-you must understand the structure in 2 years.
- Complexity should only increase when justified by real need.

---

End of file.
