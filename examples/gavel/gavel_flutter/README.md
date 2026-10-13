# gavel_flutter

Gavel's Flutter web app. `../tool/build_web.sh` builds it into
`../gavel_server/web/app`, where the server serves it on port 8082 with a
fallback to `index.html` for deep links such as `/a/<CODE>`.
