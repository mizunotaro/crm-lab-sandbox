# 02. 成果物と参照スナップショット（棚卸し）

## 入力（根拠）
- publish スクリプト  
  - `publish-issues_260131_v2.1.4.ps1`  
  - パラメータ定義（抜粋は 03 で扱う）  
  根拠: [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]
- 実行ログ（失敗 → 修正 → 成功）  
  - `log1144.txt`（DryRun 引数欠落 / IssuesRoot 不在）: [log1144.txt | sandbox:/mnt/data/log1144.txt | 2026-02-02]
  - `log1153.txt`（PostTaskLinksToSpec 型変換失敗）: [log1153.txt | sandbox:/mnt/data/log1153.txt | 2026-02-02]
  - `log1232.txt`（Get-Command -LiteralPath が ArgumentList で失敗）: [log1232.txt | sandbox:/mnt/data/log1232.txt | 2026-02-02]
  - `log1241.txt`（fix3 適用後に publish 成功・Issue 作成）: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]
  - `log1253.txt`（Issue 本文スナップショット収集 + 静的チェック）: [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02]

## 出力（生成物）
- 作成された GitHub Issue（8件）  
  - #181〜#188（タイトル・URLは `log1241.txt` に出力）  
  根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]
- Issue 本文スナップショット（ローカル）  
  - `ops/snapshots/issue_quality_20260202_125122/`  
  - zip: [issue_quality_20260202_125122.zip | sandbox:/mnt/data/issue_quality_20260202_125122.zip | 2026-02-02]
- Issue バンドル（元の Issue MD 一式）  
  - [issues_bundle_20260202_ai-automation-hardening.zip | sandbox:/mnt/data/issues_bundle_20260202_ai-automation-hardening.zip | 2026-02-02]
- run_publish_issues 修正版（fix3）  
  - [issues_bundle_20260202_ai-automation-hardening_fix3.zip | sandbox:/mnt/data/issues_bundle_20260202_ai-automation-hardening_fix3.zip | 2026-02-02]

## 重要なパス（再現性の要）
- RepoRoot（実行場所）: `C:\src\_sandbox\crm-lab-sandbox`  
  根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]
- Publisher: `ops\scripts\publish-issues_260131_v2.1.4.ps1`  
  根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]
- IssueRootRel: `ops\issues\ai-automation-hardening`  
  根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]

