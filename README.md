# CRM Lab Sandbox

A practice/sandbox repository for building an "enterprise-ish" CRM (Customer Relationship Management) application.

## Overview

This is a training project that demonstrates modern full-stack development practices for a contact management/business cards/lightweight CRM application.

### Architecture

- **Monorepo structure** using pnpm workspaces
- **Target platforms**: Web app + Mobile app (iOS/Android)
- **Backend**: API server with PostgreSQL database
- **CI/CD**: GitHub Actions with GitHub Actions service container for PostgreSQL in CI
- **Hosting**: Designed for Google Cloud Platform (GCP) - Cloud Run / Cloud SQL

### Project Structure

```
.
├── apps/
│   ├── api/          # Backend API server
│   └── web/          # Frontend web application
├── packages/
│   └── shared/       # Shared utilities and types
├── .github/
│   └── workflows/    # CI/CD pipelines
├── AGENTS.md         # AI agent operating rules
└── docs/
    └── ai/           # AI session logs and decisions
```

## Getting Started

### Prerequisites

- Node.js >= 24
- pnpm 10.28.2

### Installation

```bash
# Install dependencies
pnpm install

# Run development servers
pnpm dev
```

## Development

### Running the Application

```bash
# Start all apps in development mode
pnpm dev

# Start specific app
pnpm --filter @crm-lab/api dev
pnpm --filter @crm-lab/web dev
```

### Building

```bash
# Build all apps
pnpm build

# Build specific app
pnpm --filter @crm-lab/api build
pnpm --filter @crm-lab/web build
```

## CI/CD

This project uses GitHub Actions for continuous integration and deployment:

- **ci.yml**: Main CI pipeline for linting, testing, and building
- **ai-*.yml**: AI agent orchestration workflows

## Contributing

This is a training/sandbox project. Contributions follow the guidelines in `AGENTS.md`.

## License

OSS-compatible license (to be determined)

---

## 概要 (Japanese)

これはコンタクト管理/名刺管理/軽量CRMアプリケーションのためのトレーニング/サンドボックスリポジトリです。

### アーキテクチャ

- **モノレポ構造**: pnpm workspaces
- **ターゲットプラットフォーム**: Webアプリ + モバイルアプリ（iOS/Android）
- **バックエンド**: PostgreSQLを使用したAPIサーバー
- **CI/CD**: GitHub Actions（CI用PostgreSQLコンテナ）
- **ホスティング**: Google Cloud Platform（Cloud Run / Cloud SQL）設計

### 始め方

```bash
# 依存関係のインストール
pnpm install

# 開発サーバーの起動
pnpm dev
```

### 開発

```bash
# 全アプリのビルド
pnpm build

# 特定アプリのビルド
pnpm --filter @crm-lab/api build
pnpm --filter @crm-lab/web build
```

## 貢献について

これはトレーニング用のサンドボックスプロジェクトです。貢献は `AGENTS.md` のガイドラインに従います。

---

**Note**: This is a work-in-progress project. Documentation will be updated as the application evolves.
