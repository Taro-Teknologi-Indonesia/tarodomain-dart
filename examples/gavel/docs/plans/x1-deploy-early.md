# X1 — Deploy early (step 1b, right after the UC-12 spike)

Judging: **Does it work (30%)** and **Use of the Serverpod stack (25%)**.

## Goal

By about hour 3 there's a public HTTPS URL where the Flutter web app loads from Serverpod and two browsers receive the UC-12 live ping from each other. Every later step redeploys to the same URL, so the last evening isn't spent fighting hosting.

## Target

1. **Serverpod Cloud** (chosen, because it earns stack points). Check:
   - ~~Whether it supports SQLite with a persistent volume.~~ It doesn't: Cloud offers only managed Postgres, and Serverpod requires one dialect in every run mode. So dev, test and production all moved to Postgres (embedded locally), and the migrations were regenerated. TaroDomain persists only through the Serverpod ORM, so no app code changed.
   - The API lives on `<project>.api.serverpod.space` and the web app on `<project>.serverpod.space`; `gavel_flutter/lib/config.dart` derives one from the other.
   - **Future calls are off on the current plan** (`SERVERPOD_FUTURE_CALL_ENABLED` is plan-managed). Without them the server runs catch-up, saga timeouts and the auction-close sweep every 5 s from in-process timers (`lib/src/infra/timer_jobs.dart`), and `create` doesn't schedule a close. Locally and in tests, future calls stay on.
   - Live at https://gavel-auction.serverpod.space (API: https://gavel-auction.api.serverpod.space).
   - That WebSocket streaming endpoints work through its ingress.
   - That the web server serves `web/app` and the SPA fallback for `/a/*`.
2. **Fallback:** a small VM (any provider) running `dart compile exe` plus Caddy for automatic HTTPS, with `reverse_proxy` for the API, web and WebSocket ports. Docker is optional. Budget 1 h. Pick the fallback only if Serverpod Cloud blocks you for more than 30 min.

## Steps

1. ✅ `config/production.yaml` holds no secrets (Cloud injects the database credentials). The committed `passwords.yaml` has only the local embedded-Postgres passwords; production secrets go through `serverpod cloud password set`.
2. ✅ `tool/deploy.sh` runs the tests, then `serverpod cloud deploy`. Its `scloud.yaml` pre-deploy hooks run `serverpod generate` and the `flutter_build` script (`tool/build_web.sh` → `gavel_server/web/app`, shipped through `.scloudignore`), and Cloud applies the migrations. One-time setup: `serverpod cloud launch` in `gavel_server`.
3. ✅ `gavel_flutter/lib/config.dart` derives the API URL from `Uri.base`, so one build works locally and deployed.
4. Smoke test on the deployed URL:
   - [x] `/a/TEST` loads the app (deep link, SPA fallback).
   - [ ] Two devices (a laptop and a phone on mobile data) both receive the ping.
   - [ ] Opening the link from the **Facebook app** on a phone loads it in the in-app browser and the WebSocket connects. That's the real funnel, so test it here instead of assuming.
5. Redeploy after every finished UC. It should take under 5 min; if it doesn't, fix the script first.

Estimate: 1 h (Serverpod Cloud) to 1.5 h (VM fallback).
