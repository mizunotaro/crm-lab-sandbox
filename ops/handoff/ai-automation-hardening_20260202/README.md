# 引継書パッケージ: ai-automation-hardening (20260202)

## 目的
本パッケージは、本セッションで実施した以下を「別セッションで再現・継続」するための引継書です。

1) Issue MD（8件）を `publish-issues_260131_v2.1.4.ps1` で GitHub Issue (#181〜#188) として作成  
2) `run_publish_issues.ps1` の失敗（パラメータ不整合・型変換・Get-Command 例外）を段階的に潰し、**fix3**（Get-Command 排除 + in-process 実行）で安定化  
3) 作成済み Issue の本文を `gh issue view` で追加スナップショット収集し、**AC / Verify / Rollback の存在**を静的チェック

## このフォルダの想定配置
repo ルート配下に置く想定です（例: `C:\src\_sandbox\crm-lab-sandbox`）。

```
ops/
  handoff/
    ai-automation-hardening_20260202/
      README.md
      01_scope_and_background.md
      02_artifacts_inventory.md
      03_publish_issues_pipeline.md
      04_debug_timeline_run_publish_issues.md
      05_fix3_design_and_implementation.md
      06_snapshot_issue_quality_check.md
      07_operational_runbook.md
      08_failure_modes_and_triage.md
      09_lessons_for_project.md
      90_restart_prompt.md
      scripts/
        collect_issue_snapshot.ps1
        check_issue_sections.ps1
```

## Quick Start（read-only / 破壊的操作なし）
### 1) Issue 本文のスナップショット収集（#181..#188）
`ops/handoff/ai-automation-hardening_20260202/scripts/collect_issue_snapshot.ps1` を参照。

### 2) AC / Verify / Rollback の静的チェック
`ops/handoff/ai-automation-hardening_20260202/scripts/check_issue_sections.ps1` を参照。

## 主要な根拠（Sources）
- [log1241.txt | sandbox:/mnt/data/log1241.txt | 2026-02-02]（Issue #181〜#188 作成成功ログ）
- [log1253.txt | sandbox:/mnt/data/log1253.txt | 2026-02-02]（Issue 本文の収集と静的チェック成功ログ）
- [publish-issues_260131_v2.1.4.ps1 | sandbox:/mnt/data/publish-issues_260131_v2.1.4.ps1 | 2026-02-02]（publisher のパラメータ定義と挙動）
- [PROJECT_ENV_SPEC.md | sandbox:/mnt/data/PROJECT_ENV_SPEC.md | 2026-02-02] / [PROJECT_CONTEXT.md | sandbox:/mnt/data/PROJECT_CONTEXT.md | 2026-02-02]（SSOT）

