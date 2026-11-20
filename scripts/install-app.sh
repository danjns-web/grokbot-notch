#!/usr/bin/env bash
set -euo pipefail

# Same path as `npm run install:app` / `./scripts/setup.sh --install`.
# Copies an existing ./GrokBot Notch.app with ditto (no rebuild) unless
# the bundle is missing or --rebuild is passed.
exec "$(cd "$(dirname "$0")" && pwd)/setup.sh" --install "$@"
