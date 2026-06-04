# tabbify-io/deploy

GitHub Action to deploy an app to **Tabbify** — the fly-style way: one CLI
(`tcli`), two variants, both wrapping the same command.

- **Variant 2 (default, `remote: true`)** — Tabbify clones your repo and builds it
  on our infra inside an ephemeral Firecracker sandbox, then deploys. Your source
  never leaves a token you control: the clone token is the Action's built-in
  `GITHUB_TOKEN` (per-run, repo-scoped — **no GitHub App to install**).
- **Variant 1 (`remote: false`)** — the runner builds the image and pushes it to
  `registry.tabbify.io`; Tabbify only runs it. *(Pending the public registry token
  edge — see the spec.)*

## Usage

```yaml
name: Deploy to Tabbify
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read            # github.token = repo-scoped clone token
    steps:
      - uses: actions/checkout@v4
      - uses: tabbify-io/deploy@v1
        with:
          token: ${{ secrets.TABBIFY_TOKEN }}
          # remote: true (default) — we build on our infra
          # clone-token defaults to github.token — no GitHub App needed
```

Add `TABBIFY_TOKEN` to your repo secrets. The app is described by a
`tabbify.toml` at the repo root (`[build].builder`, `[[deploy]]` targets, `[env]`).

## Inputs

| Input | Default | Description |
|---|---|---|
| `token` | — (required) | Tabbify API bearer token. |
| `remote` | `true` | `true` = build on Tabbify infra (V2); `false` = build locally + push (V1). |
| `clone-token` | `${{ github.token }}` | Git clone token; the per-run repo-scoped Action token. |
| `app-dir` | `.` | Directory holding `tabbify.toml`. |
| `tenant` | `tabbify` | Tenant namespace (registry path prefix). |
| `builder` | `""` | Builder supervisor (name\|ULA); empty ⇒ `tabbify.toml [build].builder`. |
| `node-url` | `https://api.tabbify.io` | Node API base URL. |

## How it works

`install-tcli.sh` pulls the `tcli` binary for the runner arch from the public
release S3 (`<base>/latest` → `<base>/v<VER>/<arch>/tcli`), then runs
`tcli deploy [--remote]`, which POSTs to `<node-url>/v1/deploy`. See
`obsidian/projects/_app-layer/specs/2026-06-04-tcli-deploy-and-kill-github-app.md`.

> **Note:** the S3 install requires a published `tcli` release. Until then, use
> `examples/deploy-inline.yml` (checks out + builds `tcli` in the runner).
