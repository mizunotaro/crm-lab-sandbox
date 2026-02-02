# 06. Issue 品質点検（追加スナップショット収集 + 静的チェック）

## 6.1 目的
GitHub 上の Issue #181〜#188 の本文を取得し、最低限の “骨格” が揃っているか（AC / Verify / Rollback）を機械的に点検する。

根拠: [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02]

## 6.2 収集手順（確定）
- `gh issue view` を使い、以下フィールドを JSON 取得:
  - number, title, url, labels, body, createdAt, updatedAt
- JSON を `issues_181_188.json` として保存
- さらに監査しやすいよう、1 Issue = 1 MD で `issue_181.md` 形式で保存

根拠: [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02], [issue_quality_20260202_125122.zip | sandbox:/mnt/data/issue_quality_20260202_125122.zip | 2026-02-02]

## 6.3 静的チェックの実装（確定）
- “見出し or キーワード” の存在を正規表現で判定
- パターン（例）
  - AC: `Acceptance Criteria`, `AC`, `受け入れ基準`
  - Verify: `Verification Steps`, `Verify`, `検証手順`
  - Rollback: `Risk / Rollback`, `Rollback`, `ロールバック`, `リスク`
- 出力
  - `issue_quality_report.csv`
  - `issue_quality_report.md`
  - 画面表示: `Format-Table`

根拠: [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02]

## 6.4 結果（確定）
#181〜#188 全件が `HasAC=True, HasVerify=True, HasRollback=True`（Missing なし）

根拠: [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02]

## 6.5 限界と次の強化（Eval）
現方式は “文字列があるか” だけなので、品質の十分性（具体性・実行可能性）までは保証しない。  
強化案（小さく追加可能）:
- AC: `- [ ]` のチェックボックスが最低1つある
- Verify: コマンド例（コードブロック）が含まれる
- Rollback: `revert`/`戻す`/`backup` 等の具体動詞が含まれる

