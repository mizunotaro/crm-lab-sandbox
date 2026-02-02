# 08. 失敗モードと最短復旧（Triage）

## 8.1 publish が失敗する（代表例）
### A) DryRun 引数欠落（bool 値必須）
- 症状: `Missing an argument for parameter 'DryRun'`
- 対応: `-DryRun:$true` のように値を渡す（publisher は `[bool]$DryRun`）
- 根拠: [log1144.txt | sandbox:/mnt/data/log1144.txt | 2026-02-02], [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]

### B) IssuesRoot パラメータ不在
- 症状: `A parameter cannot be found that matches parameter name 'IssuesRoot'`
- 対応: publisher 契約は `IssueRootRel`。wrapper から `IssuesRoot` を渡さない。
- 根拠: [log1144.txt | sandbox:/mnt/data/log1144.txt | 2026-02-02], [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]

### C) PostTaskLinksToSpec の型変換失敗
- 症状: `Cannot convert value "System.String" to type "System.Boolean"`
- 対応: `PostTaskLinksToSpec` は bool。in-process 実行で型を保持し、`$false` を渡す。
- 根拠: [log1153.txt | sandbox:/mnt/data/log1153.txt | 2026-02-02], [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]

### D) Get-Command が ArgumentList 関連で失敗
- 症状: `ArgumentList parameter ...`
- 対応: wrapper から `Get-Command` を排除（fix3）。publisher 呼び出しに不要な依存を持ち込まない。
- 根拠: [log1232.txt | sandbox:/mnt/data/log1232.txt | 2026-02-02]

## 8.2 収集/点検が失敗する
### A) gh 認証
- 症状: `gh issue view` が認証エラー
- 対応: `gh auth status -h github.com` で状態確認（トークンは表示しない）
- 根拠: [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02]

### B) 出力先パス
- 症状: `ops/snapshots` が見つからない
- 対応: `New-Item -Force` で作成（ログの通り）

## 8.3 失敗時のログ最小セット
- `run_publish_issues.ps1` 実行ログ（DryRun/Apply）
- `publish-issues_*.ps1` バージョン
- どの repo root で実行したか（`pwd`）
- ただし Secrets/Token はマスク（ログに含まれる場合も伏せる）

