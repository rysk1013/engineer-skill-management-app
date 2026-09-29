---
id: TASK-15
title: Backlog → GitHub Issues同期時のAC・DoD項目番号を除去する
status: In Progress
assignee: []
created_date: '2026-09-29 15:57'
updated_date: '2026-09-29 16:01'
labels: []
dependencies: []
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Backlog.mdのTaskをGitHub Issuesへ同期する際、Acceptance CriteriaおよびDefinition of Doneの項目番号（#n）がGitHub Issue参照として解釈される問題を修正する。

Backlog.md側では項目番号を保持し、GitHub Issue本文を生成する段階でAC・DoDセクションの項目番号のみを除去する。通常のIssue参照（#123など）やその他のTask Bodyには影響を与えない。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Backlog.md側のAcceptance CriteriaおよびDefinition of Doneでは項目番号（#n）が保持されている
- [ ] #2 GitHub Issueへ同期されたAcceptance Criteriaの先頭の項目番号（#n）が除去されている
- [ ] #3 GitHub Issueへ同期されたDefinition of Doneの先頭の項目番号（#n）が除去されている
- [ ] #4 Acceptance CriteriaおよびDefinition of Done以外のTask Bodyは項目番号除去の対象にならない
- [ ] #5 通常のGitHub Issue参照（#123など）が意図せず変更されない
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Acceptance Criteria are satisfied
- [ ] #2 Required tests pass
- [ ] #3 Required lint and static analysis pass
- [ ] #4 Documentation is updated if needed
- [ ] #5 No temporary or debug code remains
- [ ] #6 Self review is completed
- [ ] #7 Final Summary is completed
<!-- DOD:END -->
