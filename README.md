# CRM Lab Sandbox

A practice build for an enterprise-style contact management / business cards / lightweight CRM application.

## Overview

This repository serves as a training environment for building a web and mobile CRM application.

## Tech Stack

- **Backend:** PostgreSQL
- **Frontend:** (To be determined)
- **Mobile:** iOS / Android (To be determined)
- **Hosting:** GCP (Cloud Run / Cloud SQL) - planned
- **Package Manager:** pnpm

## Project Structure

```
crm-lab-sandbox/
├── apps/           # Web and mobile applications
├── packages/       # Shared packages
├── .github/        # GitHub Actions CI/CD
└── docs/           # Documentation
```

## Getting Started

```bash
# Install dependencies
pnpm install

# Build
pnpm build
```

## Development

```bash
# Type check
pnpm -r exec tsc --noEmit

# Run tests
pnpm --filter @crm/api test:run
```

## Documentation

See `AGENTS.md` for project operating rules and agent guidelines.

## Deployment

GCP Cloud Run deployment (planned). See `docs/deploy/` for details.

## Contributing

See `AGENTS.md` for contribution guidelines.

## License

TBD
