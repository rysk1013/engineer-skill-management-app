---
id: TASK-15
title: Backlog → GitHub Issues同期時のAC・DoD項目番号を除去する
status: Done
assignee: []
created_date: '2026-09-29 15:57'
updated_date: '2026-09-29 16:58'
labels: []
dependencies: []
priority: high
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Backlog.mdのTaskをGitHub Issuesへ同期する際、Acceptance CriteriaおよびDefinition of Doneの項目番号（#n）がGitHub Issue参照として解釈される問題を修正する。

Backlog.md側では項目番号を保持し、GitHub Issue本文を生成する段階でAC・DoDセクションの項目番号のみを除去する。通常のIssue参照（#123など）やその他のTask Bodyには影響を与えない。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Backlog.md側のAcceptance CriteriaおよびDefinition of Doneでは項目番号（#n）が保持されている
- [x] #2 GitHub Issueへ同期されたAcceptance Criteriaの先頭の項目番号（#n）が除去されている
- [x] #3 GitHub Issueへ同期されたDefinition of Doneの先頭の項目番号（#n）が除去されている
- [x] #4 Acceptance CriteriaおよびDefinition of Done以外のTask Bodyは項目番号除去の対象にならない
- [x] #5 通常のGitHub Issue参照（#123など）が意図せず変更されない
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
1. 現在のGitHub Issue本文生成処理とTask Body構造を確認する
2. Acceptance Criteria / Definition of Doneセクションを識別して項目番号（#n）を除去する変換処理を追加する
3. generate_issue_bodyからGitHub Issue向け変換処理を利用する
4. AC / DoD以外のTask Bodyおよび通常のGitHub Issue参照が変更されないことを確認する
5. Shell Scriptの構文・Lintを確認する
6. Backlog → GitHub Issues同期を実行し、実際のIssue本文を確認する
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Backlog.mdからGitHub IssuesへTaskを同期する際、Acceptance CriteriaおよびDefinition of Doneの項目番号（#n）がGitHub Issue参照として解釈される問題を修正した。

- Backlog.md側ではAC・DoDの項目番号（#n）を保持
- GitHub Issue本文生成時のみAC・DoDの項目番号を除去
- AC・DoDセクション以外のTask Bodyは変換対象外
- 通常のGitHub Issue参照（#123など）が保持されることを確認
- Shell Scriptの構文チェックに成功
- 実際のTASK-15を使用したローカル変換結果を確認
- GitHub Actionsのchanged同期を通してIssue本文へ修正が反映されることを確認
<!-- SECTION:FINAL_SUMMARY:END -->
