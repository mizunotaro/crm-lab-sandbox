# 05. fix3 設計と実装方針（run_publish_issues.ps1）

## 5.1 fix3 の設計ゴール
- **環境依存の排除**（Get-Command / default parameter injection 等で落ちない）
- **型の保持**（bool を bool のまま渡す）
- **副作用の抑制**（Spec へのコメント投稿を既定で無効化）

根拠: [log1153.txt | sandbox:/mnt/data/log1153.txt | 2026-02-02]（bool変換失敗）, [log1232.txt | sandbox:/mnt/data/log1232.txt | 2026-02-02]（Get-Command失敗）, [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]（fix3成功）

## 5.2 fix3 の要点（確定事項）
1) publisher 呼び出しは in-process で行う  
   - `& $publisherPath @invoke` を採用
2) bool パラメータは明示的に bool 値を渡す  
   - `DryRun = $true/$false`  
   - `PostTaskLinksToSpec = $false`（意図しないコメント投稿を避ける）
3) デバッグ容易性のため、実行時に引数の型をログ出力する  
   - `DryRun(type=System.Boolean)=...` 等  
   根拠: [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]

## 5.3 “なぜ PostTaskLinksToSpec を既定で false にするか”（Eval）
- publish の第一目的は Issue 作成であり、Spec コメント投稿は副作用（レビューや運用上の合意が要る）。
- 特に運用中は、コメント更新がノイズになる可能性があるため、既定は false に倒し、必要なら明示的に true にする方が安全。

※これは運用上の推奨（Eval）であり、仕様確定はプロジェクト判断。

## 5.4 互換性方針（Eval）
- publisher のインターフェースが将来変わる可能性があるため、
  - wrapper は “publisher の param() を解析して自動適応” するよりも、
  - **publisher のバージョンを SSOT として固定**し、その契約に合う thin wrapper を維持する方が事故りにくい。
- 変更が必要なら “Issue 化→小PR” の手順で更新する。

