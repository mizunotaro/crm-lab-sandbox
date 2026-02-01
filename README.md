# CRM Lab Sandbox

A practice build for an enterprise-style contact management / business cards / lightweight CRM application.

## Overview

This repository is a training app for building a modern CRM system targeting:
- Web app
- Mobile app (iOS/Android)

## Tech Stack

- Backend DB: PostgreSQL
- Hosting: GCP (Cloud Run / Cloud SQL) - planned
- Package Manager: pnpm

## Development

```bash
# Install dependencies
pnpm install

# Run all dev checks (lint/typecheck/test/build) in CI order
pwsh ops/scripts/dev-check.ps1

# Skip specific steps
pwsh ops/scripts/dev-check.ps1 -SkipLint -SkipBuild

# Build
pnpm build
```

## Documentation

See `AGENTS.md` for project operating rules and agent guidelines.

## License

TBD
