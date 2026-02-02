# 07. 運用 Runbook（この作業を再現する）

## 7.1 安全原則
- read-only 操作は `gh issue view` / `gh repo view` のみに限定する（Secrets出力禁止）。
- publish は必ず `-DryRun` → `Apply` の順で行う。
- rollback 手順を先に作る（`Copy-Item ... .bak`）。

根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]（DryRun→Apply）, [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02]（tokenはマスク）

## 7.2 publish（Issue 作成）手順
### 前提
- repo root: `C:\src\_sandbox\crm-lab-sandbox`
- `ops\issues\ai-automation-hardening\` に Issue MD がある
- `ops\scripts\publish-issues_260131_v2.1.4.ps1` が存在

根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]

### 手順
1) rollback 用バックアップ
2) DryRun 実行
3) Apply 実行
4) 生成された Issue 番号と URL をログ保存

参考ログ: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]

## 7.3 追加スナップショット収集と品質点検
- 収集: `gh issue view` → JSON/MD 保存
- 点検: 正規表現で HasAC/HasVerify/HasRollback 判定

参考ログ: [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02]

## 7.4 監査用の保管
- `ops/snapshots/issue_quality_YYYYMMDD_HHMMSS/` を zip 化して保管（監査・別セッション共有用）

根拠: [issue_quality_20260202_125122.zip | sandbox:/mnt/data/issue_quality_20260202_125122.zip | 2026-02-02]

