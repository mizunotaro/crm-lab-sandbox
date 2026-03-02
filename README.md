# CRM Lab Sandbox

[English](#english) | [日本語](#日本語)

---

<a name="english"></a>
## English

A practice build for an enterprise-style contact management / business cards / lightweight CRM application.

### Overview

This repository serves as a training environment for building a web and mobile CRM application.

### Tech Stack

- **Backend:** PostgreSQL
- **Frontend:** (To be determined)
- **Mobile:** iOS / Android (To be determined)
- **Hosting:** GCP (Cloud Run / Cloud SQL) - planned
- **Package Manager:** pnpm

### Project Structure

```
crm-lab-sandbox/
├── apps/           # Web and mobile applications
├── packages/       # Shared packages
├── .github/        # GitHub Actions CI/CD
└── docs/           # Documentation
```

### Getting Started

```bash
# Install dependencies
pnpm install

# Build
pnpm build
```

### Development

```bash
# Type check
pnpm -r exec tsc --noEmit

# Run tests
pnpm --filter @crm/api test:run
```

### Documentation

See `AGENTS.md` for project operating rules and agent guidelines.

### Deployment

GCP Cloud Run deployment (planned). See `docs/deploy/` for details.

### Contributing

See `AGENTS.md` for contribution guidelines.

### License

TBD

---

<a name="日本語"></a>
## 日本語

エンタープライズスタイルの連絡先管理・名刺管理・軽量CRMアプリケーションの練習用ビルドです。

### 概要

このリポジトリは、WebおよびモバイルCRMアプリケーションを構築するためのトレーニング環境です。

### 技術スタック

- **バックエンド:** PostgreSQL
- **フロントエンド:** （未定）
- **モバイル:** iOS / Android（未定）
- **ホスティング:** GCP（Cloud Run / Cloud SQL）- 計画中
- **パッケージマネージャー:** pnpm

### プロジェクト構成

```
crm-lab-sandbox/
├── apps/           # Web・モバイルアプリケーション
├── packages/       # 共有パッケージ
├── .github/        # GitHub Actions CI/CD
└── docs/           # ドキュメント
```

### はじめに

```bash
# 依存関係のインストール
pnpm install

# ビルド
pnpm build
```

### 開発

```bash
# 型チェック
pnpm -r exec tsc --noEmit

# テスト実行
pnpm --filter @crm/api test:run
```

### ドキュメント

プロジェクトの運用ルールとエージェントガイドラインについては `AGENTS.md` を参照してください。

### デプロイ

GCP Cloud Runへのデプロイ（計画中）。詳細は `docs/deploy/` を参照してください。

### コントリビュート

コントリビュートガイドラインについては `AGENTS.md` を参照してください。

### ライセンス

未定
