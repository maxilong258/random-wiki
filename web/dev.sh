#!/bin/sh
set -eu
cd "$(dirname "$0")"
if [ ! -d node_modules ]; then
  pnpm install --frozen-lockfile
fi
exec pnpm dev
