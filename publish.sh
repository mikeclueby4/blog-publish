# publish.sh (place in ~/blog-publish in WSL)
#!/usr/bin/env bash
set -euo pipefail

# ---------- Configuration ----------
# Assumptions:
# - publish.bat is executed from the Obsidian vault root on Windows.
# - `wsl --cd "%~dp0"` makes $PWD inside WSL equal to the vault root mounted under /mnt/*.
# - The vault contains BLOG/<slug>/<slug>.md plus sibling images.
# - Drafts MUST NEVER be copied into this (public) repo.

# Vault paths (derive from where WSL started)
VAULT_ROOT="${VAULT_ROOT:-$PWD}"
VAULT_BLOG_DIR="${VAULT_ROOT}/BLOG"
VAULT_TAGS_MD="${VAULT_ROOT}/tags.md"

# Public repo paths (this repo)
PUBLIC_REPO_DIR="$(pwd)"
PUBLIC_BLOG_DIR="${PUBLIC_REPO_DIR}/BLOG"
PUBLIC_TAGS_MD="${PUBLIC_REPO_DIR}/tags.md"

# Which file extensions to copy along with the post markdown
# (Keep this conservative; add more if needed.)
ASSET_EXTS_REGEX='\.(png|jpg|jpeg|webp|gif|svg|avif|pdf)$'

# Optional: set to 1 to also copy "og" images even if draft:false check passes.
# (By default we copy all sibling assets in the post folder.)
COPY_ALL_SIBLINGS=1

# ---------- Helpers ----------
err() { echo "ERROR: $*" >&2; }
warn() { echo "WARN: $*" >&2; }
info() { echo "INFO: $*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Missing required command: $1"; exit 1; }
}

# Return 0 if the file contains frontmatter with a line exactly: draft: false
is_publishable_md() {
  local md="$1"
  awk '
    NR==1 && $0!="---" { exit 2 }                # no frontmatter
    NR==1 { in=1; next }
    in==1 && $0=="---" { exit found?0:1 }         # end frontmatter
    in==1 && $0 ~ /^draft:[[:space:]]*false([[:space:]]*#.*)?$/ { found=1 }
  ' "$md" >/dev/null 2>&1
}

# Return 0 if the file contains frontmatter with a line exactly: draft: true
# (Used as a paranoia check.)
contains_draft_true() {
  local md="$1"
  awk '
    NR==1 && $0!="---" { exit 1 }
    NR==1 { in=1; next }
    in==1 && $0=="---" { exit 1 }
    in==1 && $0 ~ /^draft:[[:space:]]*true([[:space:]]*#.*)?$/ { exit 0 }
  ' "$md" >/dev/null 2>&1
}

# Sync one post folder: BLOG/<slug>/... into public BLOG/<slug>/...
# Only called for publishable posts.
sync_post_dir() {
  local slug_dir="$1"  # absolute path to vault BLOG/<slug>
  local slug
  slug="$(basename "$slug_dir")"

  mkdir -p "${PUBLIC_BLOG_DIR}/${slug}"

  if [[ "$COPY_ALL_SIBLINGS" == "1" ]]; then
    # Copy everything in the post folder (md + images + any other sibling assets)
    rsync -a --exclude ".DS_Store" --exclude "Thumbs.db" \
      "${slug_dir}/" "${PUBLIC_BLOG_DIR}/${slug}/"
  else
    # Copy only the main md and asset extensions
    rsync -a --exclude "*" --include "${slug}.md" --include "*" --exclude ".DS_Store" --exclude "Thumbs.db" \
      "${slug_dir}/" "${PUBLIC_BLOG_DIR}/${slug}/"
    # Then copy asset extensions
    find "${slug_dir}" -maxdepth 1 -type f -regextype posix-extended -regex ".*${ASSET_EXTS_REGEX}" -print0 \
      | while IFS= read -r -d '' f; do
          cp -f "$f" "${PUBLIC_BLOG_DIR}/${slug}/"
        done
  fi
}

# ---------- Pre-flight ----------
require_cmd awk
require_cmd find
require_cmd rsync
require_cmd npm
require_cmd git

[[ -d "$VAULT_BLOG_DIR" ]] || { err "Vault BLOG dir not found: $VAULT_BLOG_DIR"; exit 1; }

mkdir -p "$PUBLIC_BLOG_DIR"

# Copy tags.md if present
if [[ -f "$VAULT_TAGS_MD" ]]; then
  cp -f "$VAULT_TAGS_MD" "$PUBLIC_TAGS_MD"
else
  warn "tags.md not found at: $VAULT_TAGS_MD (continuing)"
fi

# ---------- Export publishable posts ----------
# We only consider files that match BLOG/<slug>/<slug>.md convention.
# Publishable criteria: frontmatter contains 'draft: false'.

publishable_slugs=()
skipped_drafts=()
skipped_no_frontmatter=()

while IFS= read -r -d '' md; do
  slug_dir="$(dirname "$md")"
  slug="$(basename "$slug_dir")"

  # Only consider the canonical file BLOG/<slug>/<slug>.md
  if [[ "$(basename "$md")" != "${slug}.md" ]]; then
    continue
  fi

  # Never export drafts
  if is_publishable_md "$md"; then
    publishable_slugs+=("$slug")
    sync_post_dir "$slug_dir"
  else
    # Track why (best effort)
    if contains_draft_true "$md"; then
      skipped_drafts+=("$slug")
    else
      # Either missing frontmatter or draft:false not set
      skipped_no_frontmatter+=("$slug")
    fi
  fi

done < <(find "$VAULT_BLOG_DIR" -mindepth 2 -maxdepth 2 -type f -name "*.md" -print0)

# ---------- Guardrails ----------
# Hard stop if any 'draft: true' exists in the public repo after export.
if grep -R --line-number -E '^draft:[[:space:]]*true([[:space:]]*#.*)?$' "$PUBLIC_BLOG_DIR" >/dev/null 2>&1; then
  err "draft:true found in public repo BLOG/. Aborting."
  exit 1
fi

# Warn about stale folders: present in public repo but not currently publishable in vault.
# (We do NOT delete automatically.)
stale=()
for d in "$PUBLIC_BLOG_DIR"/*; do
  [[ -d "$d" ]] || continue
  s="$(basename "$d")"
  keep=false
  for ps in "${publishable_slugs[@]}"; do
    if [[ "$ps" == "$s" ]]; then keep=true; break; fi
  done
  if [[ "$keep" == "false" ]]; then
    stale+=("$s")
  fi
done

# ---------- Build & push ----------
# Your package.json should make build fail if validations fail.
info "Running build (this will gate Cloudflare deploys too)..."
npm run build

# Summaries before git operations
info "Export summary:"
info "  Published exported: ${#publishable_slugs[@]}"
if (( ${#publishable_slugs[@]} > 0 )); then
  printf '    - %s\n' "${publishable_slugs[@]}"
fi

if (( ${#skipped_drafts[@]} > 0 )); then
  warn "Skipped drafts (draft:true): ${#skipped_drafts[@]}"
  printf '    - %s\n' "${skipped_drafts[@]}" >&2
fi

if (( ${#skipped_no_frontmatter[@]} > 0 )); then
  warn "Skipped (not publishable: missing frontmatter or no draft:false): ${#skipped_no_frontmatter[@]}"
  printf '    - %s\n' "${skipped_no_frontmatter[@]}" >&2
fi

if (( ${#stale[@]} > 0 )); then
  warn "Public repo contains folders not currently publishable from vault (not deleting): ${#stale[@]}"
  printf '    - %s\n' "${stale[@]}" >&2
fi

# Commit/push (optional; comment out if you prefer manual)
info "Committing & pushing public repo..."
git add -A
# Don't fail if there are no changes
if git diff --cached --quiet; then
  info "No changes to commit."
else
  git commit -m "Publish $(date -u +%Y-%m-%dT%H:%M:%SZ)"
fi

git push
info "Done."


# llms.txt (place at site root; served as /llms.txt)
# Spec reference: https://llmstxt.org/
# Assumptions:
# - Canonical HTML post URL: /<slug>/
# - Markdown mirror URL: /<slug>/index.md

cat > llms.txt <<'LLMSTXT'
# Privileged Contexts Blog

> Personal technical blog focused on security, detection/response, and secure use of AI/agentic tooling. Canonical content lives at blog.clueby4.dev.

Each post is published as:
- HTML: https://blog.clueby4.dev/<slug>/
- Markdown mirror: https://blog.clueby4.dev/<slug>/index.md

Use the Markdown mirror when you want a clean, content-first representation for ingestion/quoting.

## Entry points

- [Posts index](https://blog.clueby4.dev/): Landing page / list of posts.
- [RSS feed](https://blog.clueby4.dev/rss.xml): New posts in feed form (useful for “recent”).
- [Sitemap](https://blog.clueby4.dev/sitemap.xml): Full list of pages (HTML URLs).

## Topics

- [Security](https://blog.clueby4.dev/tags/security/): Posts tagged security.
- [AI security](https://blog.clueby4.dev/tags/ai-security/): LLM/agent security topics (prompt injection, RAG, evals).
- [Detection engineering](https://blog.clueby4.dev/tags/detection-engineering/): Detections, hunting, telemetry pipelines.
- [KQL](https://blog.clueby4.dev/tags/kql/): KQL notes, patterns, pitfalls.

## Optional

- [About](https://blog.clueby4.dev/about/): Author, scope, and contact.
- [All tags](https://blog.clueby4.dev/tags/): Tag index.
LLMSTXT


# Recommended frontmatter template for NEW posts (vault-side)
# Tags format is a YAML list; default umbrella tag is "security".
# Publish gate: draft must be set to false AND date must be set before export.
#
# ---
# title:
# seo_title:
# description:
# slug: "<slug>"
# canonical: "https://blog.clueby4.dev/<slug>/"
# og_image: "/<slug>/og.jpg"
# tags:
#   - security
# noindex: false
# draft: true
# date:
# updated:
# ---
