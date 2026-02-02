# 09. 教訓集（ChatGPT プロジェクト登録用）

## 9.1 教訓（確定事実に基づく）
1) **publisher の param() は契約（SSOT）**  
   wrapper 側が勝手に引数名を作ると、即死する（`IssuesRoot` 不在）。  
   根拠: [log1144.txt | sandbox:/mnt/data/log1144.txt | 2026-02-02], [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]

2) **[bool] パラメータは switch ではない**  
   `[bool]$DryRun` は `-DryRun:$true` のように値が必要。  
   根拠: [log1144.txt | sandbox:/mnt/data/log1144.txt | 2026-02-02], [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]

3) **PowerShell は “別プロセス実行” で型が壊れることがある**（Eval）  
   `pwsh -File ...` で引数が文字列化され、bool 変換が失敗しうる。  
   対策は **in-process 実行（call operator &）**。  
   根拠: [log1153.txt | sandbox:/mnt/data/log1153.txt | 2026-02-02], [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]

4) **Get-Command 依存は環境要因で壊れうる**（Uncertain: 原因は特定不能だが事象は確定）  
   `Get-Command -LiteralPath` が ArgumentList 関連で失敗。  
   対策は “必要ない introspection を捨てる” ＝ wrapper を薄くする。  
   根拠: [log1232.txt | sandbox:/mnt/data/log1232.txt | 2026-02-02]

5) **副作用（Spec への自動コメント等）は既定で OFF に倒す**（Eval）  
   `PostTaskLinksToSpec` は運用合意が必要になりがち。Issue 作成の成功率を優先して `$false` を既定に。  
   根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02], [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]

6) **DryRun → Apply の2段階運用が有効**  
   DryRun で Targets とタイトルを検査し、Apply で作成に進む。  
   根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]

7) **Issue 本文の品質ゲートは “まず静的チェック” が実用的**  
   #181..#188 の本文に AC/Verify/Rollback が存在するかを機械点検し、欠落があれば CI で fail も可能。  
   根拠: [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02]

## 9.2 プロジェクトに登録する「ルール化」案（Eval）
- `ops/issues/<project>/run_publish_issues.ps1` の標準要件:
  - in-process `&` 呼び出し
  - bool 引数は値付きで渡す
  - `PostTaskLinksToSpec` は既定 false
  - 主要引数（Repo/RepoRoot/IssueRootRel/Publisher/型）をログ出力
- `ops/snapshots/` の標準:
  - issue_quality_YYYYMMDD_HHMMSS 形式
  - json + md + report をセットで保存

