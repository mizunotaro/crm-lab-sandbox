# 03. publish-issues パイプライン（仕様・契約・前提）

## 3.1 何が “SSOT” か
- Issue MD の形式（`- Title:` 行必須、ファイル命名 `NN_issue_*.md` 等）は **publisher が前提**としている仕様であり、Issue bundle 側はそれに合わせる必要がある。  
  根拠: [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]（Mode: files / DryRun / IssueRootRel 等の実装）
- 運用 SSOT（ラベル、AI_AUTOMATION_MODE 等）はプロジェクト SSOT に従う。  
  根拠: [PROJECT_ENV_SPEC.md | sandbox:/mnt/data/PROJECT_ENV_SPEC.md | 2026-02-02], [PROJECT_CONTEXT.md | sandbox:/mnt/data/PROJECT_CONTEXT.md | 2026-02-02]

## 3.2 publisher（publish-issues_260131_v2.1.4.ps1）のパラメータ定義（抜粋）
本セッションで問題になったのは主に以下です（= wrapper 側の引数整合が必要）。

- `[string]$Repo`（owner/name）
- `[string]$LocalRepoPath`
- `[string]$IssueRootRel`
- `[ValidateSet("files","range","all")] [string]$Mode`
- `[bool]$PostTaskLinksToSpec`
- `[bool]$DryRun`

根拠: [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]

### 重要ポイント（確定事実）
- `DryRun` と `PostTaskLinksToSpec` は **bool パラメータ**であり、値（True/False/0/1）が必要。  
  - `-DryRun` を switch 的に渡すと「Missing an argument for parameter 'DryRun'」になる。  
    根拠: [log1144.txt | sandbox:/mnt/data/log1144.txt | 2026-02-02]
  - `PostTaskLinksToSpec` に `"System.String"` のような文字列が渡ると変換エラーになる。  
    根拠: [log1153.txt | sandbox:/mnt/data/log1153.txt | 2026-02-02]
- `IssuesRoot` というパラメータは publisher には存在しない（`IssueRootRel` を使う契約）。  
  根拠: [log1144.txt | sandbox:/mnt/data/log1144.txt | 2026-02-02], [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]

## 3.3 wrapper（run_publish_issues.ps1）の役割
- repo ルートでの実行を前提に、publisher を正しいパラメータで呼び出す “thin wrapper” であるべき。
- 本セッションでは wrapper の不整合が原因で複数の失敗が発生し、最終的に **fix3** で安定化した。  
  根拠: [log1144.txt | sandbox:/mnt/data/log1144.txt | 2026-02-02], [log1153.txt | sandbox:/mnt/data/log1153.txt | 2026-02-02], [log1232.txt | sandbox:/mnt/data/log1232.txt | 2026-02-02], [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]

