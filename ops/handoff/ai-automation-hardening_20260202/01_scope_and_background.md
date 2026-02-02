# 01. スコープと背景

## スコープ
本セッションでは、以下の範囲を扱いました。

1) **Issue バンドルの publish（DryRun → Apply）**  
   - Issue MD 8件（30〜37）を GitHub Issue (#181〜#188) として作成  
   - 入口スクリプト: `ops/issues/ai-automation-hardening/run_publish_issues.ps1`  
   - publisher: `ops/scripts/publish-issues_260131_v2.1.4.ps1`  
   根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]

2) **run_publish_issues.ps1 のデバッグ（段階的修正）**  
   - `-DryRun` / `-IssuesRoot` / `-PostTaskLinksToSpec` / `Get-Command -LiteralPath` 周りの失敗を、ログ根拠で潰し込み  
   根拠: [log1144.txt | sandbox:/mnt/data/log1144.txt | 2026-02-02], [log1153.txt | sandbox:/mnt/data/log1153.txt | 2026-02-02], [log1232.txt | sandbox:/mnt/data/log1232.txt | 2026-02-02]

3) **作成済み Issue の“品質ゲート（静的）”の追加収集と点検**  
   - `gh issue view` で #181..#188 の本文（body）を JSON/MD として保存  
   - 本文に「AC / Verify / Rollback」相当の見出し・キーワードがあるかを正規表現で判定  
   根拠: [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02], [issue_quality_20260202_125122.zip | sandbox:/mnt/data/issue_quality_20260202_125122.zip | 2026-02-02]

## 目的（今回のゴール）
- 「公開情報/スナップショットに基づく」Issue 化を小さく検証可能に進める（あなたの運用ポリシーに整合）
- Issue の投入（publish）が不安定になる根本原因（PowerShell/パラメータ型/環境依存）を潰し、**再現性**を確保

## 前提（SSOT）
- 運用・環境の SSOT:  
  - [PROJECT_ENV_SPEC.md | sandbox:/mnt/data/PROJECT_ENV_SPEC.md | 2026-02-02]  
  - [PROJECT_CONTEXT.md | sandbox:/mnt/data/PROJECT_CONTEXT.md | 2026-02-02]  
  - [AGENTS.md | sandbox:/mnt/data/AGENTS.md | 2026-02-02]  
  - [CHEATSHEET_COMMANDS.md | sandbox:/mnt/data/CHEATSHEET_COMMANDS.md | 2026-02-02]

## 本セッションで確定した成果（確定事実）
- `run_publish_issues.ps1`（fix3適用後）で **DryRun と Apply が完走**し、Issue #181〜#188 が作成された。  
  根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]
- `gh issue view` により、#181..#188 の本文スナップショットと静的チェックレポートが生成された。  
  根拠: [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02], [issue_quality_20260202_125122.zip | sandbox:/mnt/data/issue_quality_20260202_125122.zip | 2026-02-02]

