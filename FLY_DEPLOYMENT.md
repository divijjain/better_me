# Fly.io Deployment

## App: better-me
- Fly app name: `better-me`
- URL: `better-me.fly.dev`
- Region: `bom` (Mumbai)
- 2 machines, shared 1 vCPU, 1024 MB RAM each
- Always-on: `min_machines_running = 1` — one machine always running, no cold starts
- Release command: `/app/bin/migrate` (auto-runs Ecto migrations on deploy)
- Deployed via multi-stage Dockerfile (Elixir 1.19.5 / OTP 28.3.1 / Debian trixie)
- Entrypoint: `/app/bin/server`

## Database: bme-postgres
- Fly app name: `bme-postgres`
- Region: `bom` (Mumbai)
- 1 machine, shared 1 vCPU, 512 MB RAM
- Volume: `vol_42kqypomk6o12334`, 5 GB, encrypted

## Distributed Erlang
- `rel/env.sh.eex` configures DNS cluster query and IPv6 when `FLY_APP_NAME` is set
- Uses `inet6_tcp` and `ECTO_IPV6=true` for Fly's private IPv6 networking

## Secrets required
- `SECRET_KEY_BASE`
- `DATABASE_URL`

## Deploy
```sh
fly deploy
```
