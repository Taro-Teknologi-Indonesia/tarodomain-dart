#!/usr/bin/env bash
# Builds the Flutter web app and copies it to gavel_server/web/app, where the
# server's FlutterRoute serves it. Extra arguments go to `flutter build web`,
# for example --dart-define=GAVEL_API_URL=https://example.com/api/.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

cd "$root/gavel_flutter"
flutter build web --release "$@"

mkdir -p "$root/gavel_server/web/app"
rsync -a --delete "$root/gavel_flutter/build/web/" "$root/gavel_server/web/app/"
echo "Copied the web build to gavel_server/web/app"
