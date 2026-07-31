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
