#!/usr/bin/env bash
# Deploys Gavel to Serverpod Cloud. The tests run first; then
# `serverpod cloud deploy` runs the scloud.yaml pre-deploy hooks
# (`serverpod generate` and the `flutter_build` script, which builds the web
# app into gavel_server/web/app), uploads, and applies the migrations.
# Extra arguments go to `serverpod cloud deploy`.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$PATH:$HOME/.pub-cache/bin"

cd "$root/gavel_server"
if [[ ! -f scloud.yaml ]]; then
  echo "No scloud.yaml yet: run 'serverpod cloud launch' in gavel_server once." >&2
  exit 1
fi

dart test
serverpod cloud deploy "$@"
