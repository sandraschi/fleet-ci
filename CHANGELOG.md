# CHANGELOG -- fleet-ci

All notable changes to this project will be documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added (2026-08-28)

- **`scripts/competitor-scan.ps1`** -- new standalone script (not a CI
  workflow, invoked manually). Scans the official MCP registry
  (registry.modelcontextprotocol.io) for a keyword, fetches every matching
  competitor's README from GitHub, extracts Highlights/Features/Tools/
  Comparison/Why sections via regex, and writes a consolidated markdown
  scaffold comparing them against one of our own repos' README. Pure
  data-gathering -- no LLM calls, no judgment on what's worth borrowing.
  First real run: `godot` keyword against `godot-mcp`, 12 registry entries
  and 11 competitor README fetches in ~3 seconds. Output feeds a manual
  (or Claude-assisted) "filch list" review -- see the godot-mcp competitive
  scan note in fleet memory for the first one done this way.
  - Known gotcha fixed during build: PowerShell's `Where-Object` returns a
    bare object (not a 1-element array) when exactly one match exists, so
    `.Count` on that result silently returns `$null`. Fixed by wrapping
    filtered results in `@(...)`.
