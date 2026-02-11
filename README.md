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

## Project Structure

```
crm-lab-sandbox/
├── apps/           # Web and mobile applications
├── packages/       # Shared packages
├── .github/        # GitHub Actions CI/CD
└── docs/           # Documentation
```

## Development

```bash
# Install dependencies
pnpm install

# Type check
pnpm -r exec tsc --noEmit

# Run tests
pnpm --filter @crm/api test:run
```

## Documentation

See `AGENTS.md` for project operating rules and agent guidelines.

## License

TBD
