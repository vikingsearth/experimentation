#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# fetch-docs.sh
# Fetch pages listed under the LangChain Python docs sitemap and save them under a local output directory.
# By default the script saves raw HTML files with a .md extension. Use --markdown to convert HTML->Markdown (requires pandoc).
# Usage:
#   ./fetch-docs.sh [--markdown] [--sitemap URL] [--output DIR]

SITEMAP='https://docs.langchain.com/sitemap.xml'
OUTPUT_DIR='prepwork/python-langchain/docs/remote'
CONVERT=false

while [ $# -gt 0 ]; do
  case "$1" in
    --markdown) CONVERT=true; shift ;;
    --sitemap) shift; SITEMAP="${1:-$SITEMAP}"; shift ;;
    --output) shift; OUTPUT_DIR="${1:-$OUTPUT_DIR}"; shift ;;
    -h|--help)
      cat <<'USAGE'
Usage: fetch-docs.sh [--markdown] [--sitemap URL] [--output DIR]

Options:
  --markdown       Convert fetched HTML to Markdown using pandoc (pandoc must be installed).
  --sitemap URL    Use an alternate sitemap URL (default https://docs.langchain.com/sitemap.xml).
  --output DIR     Directory to save files (default prepwork/python-langchain/docs/remote).
  -h, --help       Show this help and exit.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if $CONVERT; then
  if ! command -v pandoc >/dev/null 2>&1; then
    echo "Error: pandoc is required for --markdown but was not found." >&2
    exit 3
  fi
fi

mkdir -p "$OUTPUT_DIR"

echo "Extracting URLs from sitemap: $SITEMAP"
URLS=$(curl -s "$SITEMAP" | grep -o 'https://docs.langchain.com/oss/python/langchain[^<]*' | sort -u)

if [ -z "$URLS" ]; then
  echo "No URLs found. Exiting." >&2
  exit 1
fi

base='https://docs.langchain.com/oss/python/langchain'
while IFS= read -r url; do
  [ -z "$url" ] && continue
  rel=${url#"$base"}
  rel=${rel#/}
  rel=${rel%/}
  rel=${rel%%\?*}
  rel=${rel%%\#*}
  [ -z "$rel" ] && rel="index"
  out="$OUTPUT_DIR/${rel}.md"
  mkdir -p "$(dirname "$out")"
  printf 'Fetching %s -> %s\n' "$url" "$out"
  if ! curl -sSf "$url" -o "${out}.html"; then
    printf 'Failed to fetch %s\n' "$url" >&2
    continue
  fi
  if $CONVERT; then
    if pandoc -f html -t gfm --wrap=none "${out}.html" -o "$out"; then
      rm -f "${out}.html"
      printf 'Saved %s\n' "$out"
    else
      printf 'Pandoc conversion failed for %s\n' "$url" >&2
      mv "${out}.html" "${out}.failed.html"
    fi
  else
    mv "${out}.html" "$out"
    printf 'Saved %s (raw HTML)\n' "$out"
  fi
done < <(printf '%s\n' "$URLS")
