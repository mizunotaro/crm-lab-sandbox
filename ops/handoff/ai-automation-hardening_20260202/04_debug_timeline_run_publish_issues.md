# 04. デバッグタイムライン（run_publish_issues.ps1）

## 4.1 失敗→修正→成功の流れ（時系列）

### (1) 失敗: DryRun の値欠落 / IssuesRoot パラメータ不在
- 症状
  - `Missing an argument for parameter 'DryRun'. Specify a parameter of type 'System.Boolean'`
  - `A parameter cannot be found that matches parameter name 'IssuesRoot'.`
- 原因（確定）
  - publisher の `DryRun` は `[bool]`。switch ではなく値が必要。
  - publisher には `IssuesRoot` はなく、`IssueRootRel` が契約。
- 根拠: [log1144.txt | sandbox:/mnt/data/log1144.txt | 2026-02-02], [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]

### (2) 失敗: PostTaskLinksToSpec が "System.String" として渡り bool 変換失敗
- 症状
  - `Cannot convert value "System.String" to type "System.Boolean"`
- 原因（確定）
  - wrapper 側が `PostTaskLinksToSpec` に文字列を渡している（型保持できていない）。
- 根拠: [log1153.txt | sandbox:/mnt/data/log1153.txt | 2026-02-02], [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]

### (3) 失敗: Get-Command -LiteralPath が ArgumentList 関連で失敗
- 症状
  - `The command could not be retrieved because the ArgumentList parameter can be specified only when retrieving a single cmdlet or script.`
- 原因（Uncertain → ただし再発回避で fix3 採用）
  - `Get-Command` に `ArgumentList` が付与されている（profile / $PSDefaultParameterValues 等の外部要因の可能性）。  
  - いずれにせよ wrapper の目的（publisher 呼び出し）に必須ではないため、**Get-Command を排除**する方針が最小で堅牢。
- 根拠: [log1232.txt | sandbox:/mnt/data/log1232.txt | 2026-02-02]

### (4) 成功: fix3（Get-Command 排除 + in-process 実行）で publish 完走
- 事実
  - DryRun: 8件を “Would create issue” として列挙
  - Apply: #181〜#188 が CREATED として作成
  - `DryRun(type=System.Boolean)=True/False`、`PostTaskLinksToSpec(type=System.Boolean)=False` が出力され型保持が確認できる
- 根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]

## 4.2 fix3 の “勝ち筋”（要点）
- `pwsh -File publisher.ps1 ...` のような別プロセス実行ではなく、**同一プロセス内で `& $publisher @args` を実行**して型保持する。
- `Get-Command` に依存せず、publisher v2.1.4 の契約（引数名・型）に合わせて最小の呼び出しを行う。

（詳細は 05 参照）

