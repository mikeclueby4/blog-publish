# Upstream Tracking: AstroPaper

## Snapshot

- **Source**: `npm create astro@latest -- --template satnaing/astro-paper`
- **Captured**: 2026-02-22
- **AstroPaper version**: v5.5.1 (from `package.json` at scaffold time)
- **Astro**: 5.x, Tailwind CSS v4

When AstroPaper releases updates worth pulling in, use the procedures at the bottom of this file.

Do NOT attempt a git merge against upstream. The file structure and frontmatter schema have diverged intentionally. Cherry-pick specific component improvements manually.

---

## What to watch for in AstroPaper releases

Check these for improvements worth pulling in:
- `src/components/` — a11y fixes, new UI components (generally safe to copy across)
- `src/styles/global.css` — colour scheme / Tailwind token updates
- `src/layouts/Layout.astro` — SEO/OG/structured data improvements
- `src/scripts/theme.ts` — dark/light mode logic
- `astro.config.ts` — new integrations or Shiki config improvements
- `package.json` — dependency version bumps

These files are **ours** — do not overwrite from upstream without re-applying the delta:

| File | Why it's modified |
|---|---|
| `src/content.config.ts` | Vault frontmatter schema, `CONTENT_DIR` env var |
| `src/config.ts` | Site identity, `editPost` disabled, `dynamicOgImage` off |
| `src/layouts/PostDetails.astro` | Frontmatter fields, sticky ToC sidebar, draft banner |
| `src/pages/[slug]/index.astro` | Flat URL routing, `BLOG_PREVIEW` support |
| `src/pages/[slug]/index.md.ts` | Markdown mirror endpoint (not in AstroPaper at all) |
| `src/pages/index.astro` | `BLOG_PREVIEW` draft visibility, site copy |
| `src/pages/rss.xml.ts` | Uses `date` not `pubDatetime`, flat post URLs |
| `src/utils/postFilter.ts` | Uses `date`, `BLOG_PREVIEW` for preview mode |
| `src/utils/getSortedPosts.ts` | Sort key is `date` not `pubDatetime` |
| `src/components/Card.astro` | Uses `slug`-based hrefs, `date`/`updated` fields |
| `src/components/Datetime.astro` | Props renamed `date`/`updated` |
| `src/layouts/Layout.astro` | `noindex` prop, canonical passed from frontmatter, two `<Font>` preload tags |
| `astro.config.ts` | `experimental.fonts`: Google Sans Flex + Geist Mono (not stock IBM Plex Mono) |
| `src/styles/global.css` | `--font-app`, `--font-mono` variables; `body` font-size: 1.125rem; dark mode palette |
| `src/styles/typography.css` | fonts, letter-spacing, line-height, blockquote quotes, code overflow |

---

## Delta: all changes from stock AstroPaper v5.5.1

### 1. `src/config.ts`
- `website` → `https://blog.clueby4.dev`
- `title` → `Privileged Contexts`
- `author`, `profile`, `desc`, `ogImage` set for this site
- `editPost.enabled` → `false`
- `dynamicOgImage` → `false` (we use explicit `og_image` frontmatter instead of Satori)
- `lightAndDarkMode` → `true`
- `postPerIndex` → `6`, `postPerPage` → `8`
- `timezone` → `America/New_York`

### 2. `src/content.config.ts` — full rewrite

Stock AstroPaper schema replaced with vault frontmatter schema. `BLOG_PATH` constant removed; replaced with `CONTENT_DIR` env var logic.

Vault glob pattern: `*/*.md` (matches `<slug>/<slug>.md` folder structure). Files matching `Untitled*` excluded.

**Field mapping:**

| Vault field | AstroPaper field | Notes |
|---|---|---|
| `title` | `title` | same |
| `seo_title` | — | optional string, falls back to `title` in layout |
| `description` | `description` | now optional |
| `slug` | derived from filename | explicit frontmatter field, used for URL routing |
| `canonical` | `canonicalURL` | passed directly to Layout |
| `og_image` | `ogImage` | string path only (no image() transform) |
| `tags` | `tags` | same, default `["security"]` |
| `noindex` | — | boolean, default false |
| `draft` | `draft` | same semantics |
| `date` | `pubDatetime` | coerced date, optional |
| `updated` | `modDatetime` | coerced date, optional |

Removed AstroPaper-only fields: `author`, `featured`, `hideEditPost`, `timezone`.

### 3. URL routing: `/posts/[slug]/` → `/[slug]/`

- **Deleted**: `src/pages/posts/[...slug]/` (AstroPaper's per-post route)
- **Created**: `src/pages/[slug]/index.astro` — uses `post.data.slug` as the route param
- **Created**: `src/pages/[slug]/index.md.ts` — Markdown mirror endpoint (not in AstroPaper)
- `src/pages/posts/[...page].astro` — kept unchanged as paginated post listing

### 4. `src/utils/getPath.ts` — full rewrite

AstroPaper's `getPath(id, filePath, includeBase)` filesystem-based path builder replaced with:

```typescript
export function getPostSlug(post: CollectionEntry<"blog">): string
export function getPath(post: CollectionEntry<"blog">): string  // returns `/${slug}/`
```

All call sites updated to pass the full post object instead of `(id, filePath)`.

### 5. `src/utils/postFilter.ts`
- `pubDatetime` → `date`
- Added: `if (!data.date) return false` guard
- Added: `BLOG_PREVIEW` env var check — when `"true"`, draft posts pass the filter in dev/preview

### 6. `src/utils/getSortedPosts.ts`
- Sort key: `updated ?? date` (was `modDatetime ?? pubDatetime`)

### 7. `src/components/Card.astro`
- Post href: `getPath(post)` using full post object (was `getPath(id, filePath)`)
- Passes full post as prop to `Datetime` (date/updated fields flow through)

### 8. `src/components/Datetime.astro`
- Props renamed: `pubDatetime` → `date`, `modDatetime` → `updated`
- `date` is optional; displays "No date" if absent

### 9. `src/layouts/PostDetails.astro` — heavily modified

Frontmatter destructuring updated throughout. Key additions:

**Fixed-position ToC sidebar (left gutter):**
- ToC reads `headings` from `render()`, filters `depth <= 3`
- Article (`post-main`) is independently centered with `margin-inline: auto; max-width: 48rem` — aligns with the site header, no grid involved
- ToC is `position: fixed` in the viewport left gutter, only shown at ≥1280px where gutter is wide enough (≥256px for a 200px ToC + 2rem gap)
- `left: max(1rem, calc((100vw - 48rem) / 2 - 200px - 2rem))` — tracks article left edge at any viewport width
- Scrolls independently with `max-height: calc(100vh - 6rem); overflow-y: auto`

**Draft banner:**
- When `BLOG_PREVIEW === "true"` and `post.data.draft === true`, renders a purple banner above the article
- `noindex` set on draft posts in preview

**Layout props:**
- Title: `seo_title ?? title` passed to `<Layout>`
- OG: uses `og_image` string directly (no Satori dynamic image generation)
- `canonical` passed from frontmatter

### 10. `src/pages/rss.xml.ts`
- `pubDatetime` → `date`
- Post link: `/${data.slug}/` (was `getPath(id, filePath)`)

### 11. `src/pages/index.astro`
- `BLOG_PREVIEW` env var gates draft post inclusion
- Preview banner shown when in preview mode
- Removed: featured posts section, social links section (Socials component)
- Kept: recent posts list, RSS icon, "All Posts" link

### 12. `src/layouts/Layout.astro`
- Added `noindex` prop → `<meta name="robots" content="noindex,nofollow">`
- `canonical` prop now explicitly accepted from PostDetails (not only derived from URL)

### 13. Sample content removed
- `src/data/blog/` sample posts deleted (content comes from `BLOG/` via `CONTENT_DIR`)

### 14. `src/pages/about.md`
- Content replaced for this site

### 15. `src/constants.ts`
- Social links updated/cleared for this site

### 16. Typography / fonts

AstroPaper ships with a single `IBM Plex Mono` font applied globally. We replaced the entire font setup to match the live Hashnode site's rendering:

**`astro.config.ts`** — `experimental.fonts` array replaced:
- `IBM Plex Mono` (stock) → removed
- Added `Google Sans Flex` → `cssVariable: --font-google-sans-flex`, provider: Google, sans-serif fallback — used for body, headings, and UI chrome
- Added `Geist Mono` → `cssVariable: --font-geist-mono`, provider: Google, monospace fallback — used exclusively for code fences and inline code

**`src/layouts/Layout.astro`** — Two `<Font>` preload tags (one per face) replacing the single original.

**`src/styles/global.css`**:
- `--font-app` CSS variable now points to `--font-google-sans-flex` (was `--font-google-sans-code`)
- New `--font-mono` variable added pointing to `--font-geist-mono`
- `body` gets `font-size: 1.125rem` (scales with browser/device root; ≈18px at default settings)

**`src/styles/typography.css`**:
- Inline `code` rule gains `font-family: var(--font-mono); font-size: 0.875em`
- `.astro-code` (fenced code blocks) gains the same rules plus `overflow-x: auto` (prevents wide code fences from breaking the page layout)
- Font size expressed as `em` so it scales proportionally if surrounding prose size changes

When pulling a future AstroPaper update, do **not** overwrite the fonts array in `astro.config.ts` or the font variable names in `global.css` / `typography.css`.

### 17. Dark mode colour palette

**`src/styles/global.css`** — `html[data-theme="dark"]` block replaced to match the live Hashnode site:

| Variable | Value | Note |
|---|---|---|
| `--background` | `#020617` | slate-950 |
| `--foreground` | `#f8fafc` | slate-50 |
| `--accent` | `#70a29e` | muted teal |
| `--muted` | `#0f172a` | slate-900, box backgrounds |
| `--border` | `#1e293b` | slate-800, box borders |

Light mode colours are untouched (to be revisited separately).

### 18. Prose typography refinements

**`src/styles/typography.css`** — inside `.app-prose`:

- `letter-spacing: -0.011em` (mobile) / `-0.014em` at `≥640px` — matches Hashnode's compiled prose CSS
- Headings `h1–h4`: `letter-spacing: -0.02em`
- `line-height: 1.618` (golden ratio; Hashnode default, tighter than Tailwind Typography's 1.75)
- Blockquotes: `quotes: none` + `p::before, p::after { content: none }` — removes Tailwind Typography's decorative smartquotes

---

## Procedure: cherry-picking a specific improvement

Example: AstroPaper ships an improved `Card.astro` with a new hover animation.

1. View the diff on GitHub: `github.com/satnaing/astro-paper/commits/main/src/components/Card.astro`
2. Check if the change touches any of our modified lines (see Delta above)
3. If **not** — copy the file across, done
4. If **yes** — apply the structural change manually, preserving our field names and href pattern
5. `npm run build && npm run postbuild` — confirm no type errors

---

## Procedure: pulling in a major AstroPaper version

```sh
# 1. Scaffold a fresh copy
export PATH="$HOME/.nvm/versions/node/v22.22.0/bin:$PATH"
cd ~/blog-publish
npm create astro@latest -- --template satnaing/astro-paper --no-git --no-install astro-blog-upstream
cd astro-blog-upstream && npm install

# 2. Apply the delta (work through the table above, file by file)
#    Copy safe files from upstream, manually patch the modified ones.

# 3. Copy across our custom files that have no upstream equivalent
cp ../astro-blog/src/pages/\[slug\]/index.md.ts src/pages/\[slug\]/

# 4. Build and preview
npm run build
BLOG_PREVIEW=true CONTENT_DIR=/mnt/c/path/to/vault/BLOG npm run dev

# 5. Swap
cd ..
mv astro-blog astro-blog-old
mv astro-blog-upstream astro-blog

# 6. Update this file: new snapshot date and AstroPaper version
```

After swapping, update the **Snapshot** section at the top of this file with the new date and version.
