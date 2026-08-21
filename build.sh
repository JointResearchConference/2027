#!/usr/bin/env bash
# =============================================================================
# build.sh — JRC 2027 site build script
#
# Converts all *.org source files to HTML using Pandoc, placing the output
# in _site/. The directory layout in _site/ uses clean URL directories so
# that, e.g., program.org becomes _site/program/index.html (URL: /program/).
#
# Usage:
#   bash build.sh          # build everything
#   bash build.sh --serve  # build and serve locally with Python
# =============================================================================
set -euo pipefail

TEMPLATE="templates/page.html"
OUTDIR="_site"
ASSETS_SRC="assets"

# Pandoc base options shared by every page
# --shift-heading-level-by=1 turns org's "* Heading" into <h2>,
# which is correct because each page's <h1> comes from the template
# (hero on home, page-banner on inner pages).
PANDOC_COMMON=(
  --template="$TEMPLATE"
  --from=org
  --to=html5
  --standalone
  --shift-heading-level-by=1
)

# ── Helpers ──────────────────────────────────────────────────────────────────
info()  { echo "  ✔  $*"; }
error() { echo "  ✘  $*" >&2; exit 1; }

require_pandoc() {
  if ! command -v pandoc &>/dev/null; then
    error "pandoc is not installed. Install it from https://pandoc.org/installing.html"
  fi
  local ver
  ver=$(pandoc --version | head -1 | awk '{print $2}')
  echo "Using Pandoc $ver"
}

# ── Build ─────────────────────────────────────────────────────────────────────
build() {
  require_pandoc

  echo ""
  echo "Building JRC 2027 site → $OUTDIR/"
  echo "────────────────────────────────────────────"

  # Clean output directory
  rm -rf "$OUTDIR"
  mkdir -p "$OUTDIR"

  # Copy static assets verbatim
  if [[ -d "$ASSETS_SRC" ]]; then
    cp -r "$ASSETS_SRC" "$OUTDIR/"
    info "Copied assets/"
  fi

  # Copy root static files (Google verification, CNAME, robots.txt, etc.)
  shopt -s nullglob
  for static_file in google*.html CNAME robots.txt favicon.ico; do
    if [[ -f "$static_file" ]]; then
      cp "$static_file" "$OUTDIR/"
      info "Copied $static_file"
    fi
  done
  shopt -u nullglob

  # ── Home page ────────────────────────────────────────────────────────────
  pandoc "${PANDOC_COMMON[@]}" \
    -V root="" \
    -V page-home=true \
    -V home=true \
    -o "$OUTDIR/index.html" \
    index.org
  info "index.org → index.html"

  # ── Inner pages ──────────────────────────────────────────────────────────
  # Format: "slug:page-variable-flag"
  PAGES=(
    "program:page-program"
    "registration:page-registration"
    "speakers:page-speakers"
    "organizing-committee:page-organizing-committee"
    # ON HOLD — uncomment to restore Call for Papers page
    # "call-for-papers:page-call-for-papers"
    "short-courses:page-short-courses"
    "venue:page-venue"
  )

  for entry in "${PAGES[@]}"; do
    slug="${entry%%:*}"
    flag="${entry##*:}"
    src="${slug}.org"

    if [[ ! -f "$src" ]]; then
      echo "  ⚠  Skipping $src (file not found)"
      continue
    fi

    mkdir -p "$OUTDIR/$slug"
    pandoc "${PANDOC_COMMON[@]}" \
      -V root="../" \
      -V "$flag=true" \
      -o "$OUTDIR/$slug/index.html" \
      "$src"
    info "$src → $slug/index.html"
  done

  echo "────────────────────────────────────────────"
  echo "  Done. Output in $OUTDIR/"
  echo ""
}

# ── Local preview ─────────────────────────────────────────────────────────────
serve() {
  echo "Starting local server at http://localhost:8000 (Ctrl-C to stop)"
  cd "$OUTDIR"
  python3 -m http.server 8000
}

# ── Entry point ───────────────────────────────────────────────────────────────
build

if [[ "${1:-}" == "--serve" ]]; then
  serve
fi
