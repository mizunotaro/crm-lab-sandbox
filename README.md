# CRM Lab Sandbox

A practice build for an enterprise-style contact management / business cards / lightweight CRM application.

## Overview

<<<<<<< HEAD
This repository serves as a training environment for building a web and mobile CRM application.

## Tech Stack

- **Backend:** PostgreSQL
- **Frontend:** (To be determined)
- **Mobile:** iOS / Android (To be determined)
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

[Getting started instructions placeholder]

## Development

[Development instructions placeholder]

## Deployment

[Deployment instructions placeholder]

## Contributing

[Contributing guidelines placeholder]

## License

[License information placeholder]
=======
This repository is a training app for building a modern CRM system targeting:
- Web app
- Mobile app (iOS/Android)

## Tech Stack

- Backend DB: PostgreSQL
- Hosting: GCP (Cloud Run / Cloud SQL) - planned
- Package Manager: pnpm

## Development

### Prerequisites

- Node.js 24+
- pnpm 10.28.2+
- PostgreSQL (for local development)

### Setup

```bash
# Install dependencies
pnpm install

# Copy environment variables template
cp .env.sample .env

# Edit .env with your local configuration
# IMPORTANT: Never commit .env file - it is in .gitignore

# Build
pnpm build
```

### Environment Variables

See `.env.sample` for the full list of required environment variables. Key variables include:

- `DATABASE_URL`: PostgreSQL connection string
- `DATABASE_*`: Individual database configuration options
- `NODE_ENV`: Application environment (development/staging/production)
- `PORT` / `API_PORT`: Application ports
- `GCP_*`: Google Cloud Platform configuration
- `JWT_SECRET`: Secret key for JWT authentication

**Security Note:** The `.env` file is ignored by git. Never commit actual secrets to the repository.

## Documentation

See `AGENTS.md` for project operating rules and agent guidelines.

## License

TBD
>>>>>>> origin/main
