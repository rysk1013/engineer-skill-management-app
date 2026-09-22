---
id: TASK-4
title: Backlog.mdとGitHub Issuesを同期する
status: Done
assignee: []
created_date: '2026-09-21 08:38'
updated_date: '2026-09-22 10:33'
labels:
  - phase-0
  - infrastructure
  - github-actions
dependencies: []
priority: high
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Backlog.mdをSource of Truthとして、GitHub Issuesへタスク情報を一方向同期する仕組みを構築する。

GitHub上から現在のBacklogタスクの状態を確認できるようにする。

### Scope

- Backlog TASKの解析
- GitHub Issueの作成・更新
- TASK StatusとIssue Stateの同期
- TASK LabelとIssue Labelの同期
- Priority Labelの同期
- TASK本文とIssue Bodyの同期
- push時の差分同期
- devを基準としたFull Sync
- GitHub Actions Workflowの構築
- TASK Validation
- TASK ID重複チェック
- Issue重複チェック
- エラーハンドリング

### Out of Scope

- GitHub Projects連携
- GitHub IssuesからBacklog.mdへの逆同期
- GitHub Milestone同期
- GitHub Assignee同期
- TASK削除時のIssue自動削除・Close
- Dry Run
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 新規TASKからGitHub Issueが作成される
- [x] #2 TASKのタイトル・本文・labels・priorityの変更が既存Issueへ反映される
- [x] #3 To Do / In ProgressはOpen、DoneはClosedとして同期される
- [x] #4 DoneからIn Progressへ戻した場合、既存IssueがReopenされる
- [x] #5 push時は変更されたTASKだけが同期され、他TASKのIssue状態を巻き戻さない
- [x] #6 devを基準としてFull Syncを手動実行できる
- [x] #7 同じTASKを複数回同期してもGitHub Issueが重複作成されない
- [x] #8 TASK ID重複または同一TASKに対応するIssue重複を検出した場合、同期が失敗する
- [x] #9 TASK削除時に対応Issueを自動削除・Closeしない
- [x] #10 ValidationまたはGitHub操作に失敗した場合、Workflowが失敗し再実行可能である
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Acceptance Criteria are satisfied
- [x] #2 Required tests pass
- [x] #3 Required lint and static analysis pass
- [x] #4 Documentation is updated if needed
- [x] #5 No temporary or debug code remains
- [x] #6 Self review is completed
- [x] #7 Final Summary is completed
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
- Backlog TASKのFrontmatterと本文を解析する
- TASK IDを使用して対応するGitHub Issueを特定する
- Issueの作成・更新を冪等に実行する
- Label、Priority、StatusをGitHub Issueへ同期する
- push時は変更TASKのみ同期する
- workflow_dispatchではdevを基準にFull Syncする
- TASK ID・Issue重複をValidationする
- GitHub Actions Workflowから同期スクリプトを実行する
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
- Backlog.mdをSource of TruthとしたGitHub Issuesへの一方向同期を実装
- push時は変更されたTASKのみを同期
- workflow_dispatchではdevを基準として全TASKをFull Sync
- TASK IDをIssue Bodyのmarkerとして使用し、Issueの作成・更新を冪等化
- TASK本文、labels、priority、statusをGitHub Issueへ同期
- TASK Statusに応じたIssueのOpen / Close / Reopenに対応
- TASK ID・Issue重複のValidationを実装
- TASK削除時は対応Issueを変更しない仕様に対応
- 日本語を含むTASKファイル名をNUL区切りで安全に処理
- GitHub Actions上でchanged sync / Full Syncの正常動作を確認
- 異常系の追加検証は必要になったタイミングで随時対応
<!-- SECTION:FINAL_SUMMARY:END -->
