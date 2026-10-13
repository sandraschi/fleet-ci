# Fleet CI — Reusable GitHub Actions Workflows

Centralized CI workflows for the [sandraschi MCP fleet](https://github.com/sandraschi).

## Workflows

| Workflow | Use for |
|----------|---------|
| `python.yml` | Python-only repos (no frontend) |
| `hybrid.yml` | Python backend + optional React/Vite frontend |

## Usage

```yaml
# .github/workflows/ci.yml in your repo
name: CI

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
  workflow_dispatch:

jobs:
  ci:
    uses: sandraschi/fleet-ci/.github/workflows/hybrid.yml@v1
```

## What gets checked

- **ruff** — lint + format (requires `[dependency-groups] dev` with ruff in pyproject.toml)
- **pytest** — runs only if `tests/` directory exists
- **TypeScript typecheck** — runs `npm run check` or `npm run typecheck` if frontend detected
- **Biome** — runs `npm run biome:ci` or `npm run lint` if frontend detected
- **Playwright** — runs `npx playwright test` if `playwright.config.*` exists
- **ty** — optional typecheck (skipped if not installed)
- **pip-audit** — optional security audit (skipped if not installed)

## Fleet pins

| Tool | Version |
|------|---------|
| Python | 3.12 |
| Node | 22 |
| uv | latest |
| ruff | any |

## Graceful degradation

- No `tests/` → pytest step reports "no tests" and passes
- No frontend dir → all Node/TypeScript/Biome/Playwright steps skipped
- No `npm run check` script → typecheck step skipped with log message
- No `npm run biome:ci` → Biome step skipped with log message
- No `npm run lint` → lint step skipped with log message
- No `playwright.config.*` → Playwright steps skipped
- No `ty` in dev deps → ty step skipped
- No `pip-audit` in dev deps → pip-audit step skipped

## pyproject.toml requirements

```toml
[dependency-groups]
dev = [
    "ruff>=0.16.0,<0.17",
    "pytest>=8",
]
```

## Scripts

Standalone fleet-wide tooling, separate from the reusable CI workflows above.

| Script | Purpose |
|--------|---------|
| `scripts/competitor-scan.ps1` | Scans the official MCP registry (registry.modelcontextprotocol.io) for a keyword, pulls competitor READMEs, and writes a feature-comparison scaffold against one of our own repos. Read-only, no LLM calls. |

### competitor-scan.ps1

```powershell
.\scripts\competitor-scan.ps1 -Keyword godot -OwnRepoPath D:\Dev\repos\godot-mcp -OutFile C:\temp\godot-competitor-scan.md
```

Queries the registry for `-Keyword`, filters to the latest version of every
matching server, fetches each competitor's `README.md` from GitHub, and
extracts any Highlights/Features/Tools/Comparison/Why sections via regex
alongside the same extraction run against `-OwnRepoPath`'s own README. Output
is a single markdown file for manual (or Claude-assisted) review -- the
script does not judge what's worth borrowing, it just gathers the raw
material.

Requires no fleet MCP tools to run -- plain `Invoke-RestMethod` against the
registry API and `raw.githubusercontent.com`, both of which are reliable from
a normal PowerShell session (unlike some fetch tools, which have known
issues against the registry domain specifically).

