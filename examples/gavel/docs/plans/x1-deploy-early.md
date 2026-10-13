# X1 — Deploy early (step 1b, right after the UC-12 spike)

Judging: **Does it work (30%)** and **Use of the Serverpod stack (25%)**.

## Goal

By about hour 3 there's a public HTTPS URL where the Flutter web app loads from Serverpod and two browsers receive the UC-12 live ping from each other. Every later step redeploys to the same URL, so the last evening isn't spent fighting hosting.

## Target

1. **Serverpod Cloud** (preferred, because it earns stack points). Check:
   - Whether it supports SQLite with a persistent volume. If it doesn't, switch `config/production.yaml` to its managed Postgres. TaroDomain persists only through the Serverpod ORM, which means no code changes.
   - That WebSocket streaming endpoints work through its ingress.
   - That the web server serves `web/app` and the SPA fallback for `/a/*`.
2. **Fallback:** a small VM (any provider) running `dart compile exe` plus Caddy for automatic HTTPS, with `reverse_proxy` for the API, web and WebSocket ports. Docker is optional. Budget 1 h. Pick the fallback only if Serverpod Cloud blocks you for more than 30 min.

## Steps

1. `config/production.yaml` and `passwords.yaml` come from environment variables or secrets, never committed.
2. `tool/deploy.sh`: `flutter build web --release` → copy into `gavel_server/web/app` → `serverpod generate` → apply migrations → deploy.
3. Point `gavel_flutter/lib/config.dart` at the same origin (`Uri.base`), so one build works locally and deployed.
4. Smoke test on the deployed URL:
   - [ ] `/a/TEST` loads the app (deep link, SPA fallback).
   - [ ] Two devices (a laptop and a phone on mobile data) both receive the ping.
   - [ ] Opening the link from the **Facebook app** on a phone loads it in the in-app browser and the WebSocket connects. That's the real funnel, so test it here instead of assuming.
5. Redeploy after every finished UC. It should take under 5 min; if it doesn't, fix the script first.

Estimate: 1 h (Serverpod Cloud) to 1.5 h (VM fallback).
