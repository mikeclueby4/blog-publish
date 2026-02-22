#!/usr/bin/env bash
# preview.sh — starts Astro dev server pointing at the live vault BLOG/ directory.
# Shows ALL posts including draft: true for visual review before publishing.
# Does NOT export to public repo, commit, or push anything.
set -euo pipefail

# ---------- nvm setup ----------
source ~/.nvm/nvm.sh
nvm use

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve vault root: env var > positional arg > fail
VAULT_ROOT="${VAULT_ROOT:-${1:-}}"

if [[ -z "$VAULT_ROOT" ]]; then
  echo "ERROR: VAULT_ROOT is not set." >&2
  echo "  Usage: VAULT_ROOT=/mnt/c/path/to/vault $0" >&2
  echo "  Or:    $0 /mnt/c/path/to/vault" >&2
  exit 1
fi

VAULT_BLOG_DIR="${VAULT_ROOT}/BLOG"

if [[ ! -d "$VAULT_BLOG_DIR" ]]; then
  echo "ERROR: Vault BLOG directory not found: $VAULT_BLOG_DIR" >&2
  exit 1
fi

echo "INFO: Preview mode"
echo "INFO: Content source: $VAULT_BLOG_DIR"
echo "INFO: All posts including drafts are visible."
echo "INFO: Nothing will be committed or pushed."
echo ""

export CONTENT_DIR="$VAULT_BLOG_DIR"
export BLOG_PREVIEW="true"

cd "$SCRIPT_DIR/astro-blog"
npm run dev
