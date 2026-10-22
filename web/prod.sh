#!/bin/sh
set -eu
cd "$(dirname "$0")"
pnpm build
test -f out/index.html
pnpm dlx wrangler@4 pages deploy out \
  --project-name="${CF_PAGES_PROJECT:-random-wiki}" \
  --branch="${CF_PAGES_BRANCH:-main}"
