---
id: TASK-10
title: GitHub Actions / CIを構築する
status: To Do
assignee: []
created_date: '2026-09-27 08:39'
labels:
  - phase-0
  - infrastructure
  - github-actions
milestone: Phase 0 - 開発基盤
dependencies:
  - TASK-3
  - TASK-5
  - TASK-7
  - TASK-8
  - TASK-9
references:
  - docs/06_開発・運用/02_CI-Platform.md
  - docs/06_開発・運用/03_CICD方針.md
  - docs/04_技術選定/Backend/16_CI・Automation.md
priority: high
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
GitHub Actionsを利用して、Engineer Skill Management AppのPull Requestに対するCI基盤を構築する。

Frontend / Backend / OpenAPIの責務ごとにWorkflowを分離し、これまでのPhase 0で構築したTest・Code Quality・OpenAPI ValidationをCIから自動実行できるようにする。

LocalとCIで異なるQuality Definitionを作らず、Projectで定義したCommandをGitHub Actionsから再利用する。

Format / Lint / Static Analysis / Type Check / Test / Build / OpenAPI ValidationはBlocking Checkとして扱い、Complexity / MaintainabilityはMVP初期ではMonitoring Checkとして扱う。

E2E CI、CD、Deployment Automation、過度なPath FilterやCache最適化は本Taskの対象外とする。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 GitHub ActionsのFrontend CI Workflowが定義されている
- [ ] #2 Frontend CIでFormat / Lint / Type Check / Test / Buildを実行できる
- [ ] #3 GitHub ActionsのBackend CI Workflowが定義されている
- [ ] #4 Backend CIでFormat / Static Analysis / Testを実行できる
- [ ] #5 Backend CIでTest専用PostgreSQLを利用したDatabase Testを実行できる
- [ ] #6 GitHub ActionsのOpenAPI CI Workflowが定義されている
- [ ] #7 OpenAPI CIでLint / Bundle / Type生成 / Generated Type差分確認を実行できる
- [ ] #8 Pull RequestでFrontend / Backend / OpenAPI CIが実行される
- [ ] #9 mainへのPushでFrontend / Backend / OpenAPI CIが実行される
- [ ] #10 Blocking CheckとMonitoring Checkが既存CI/CD方針どおりに扱われている
- [ ] #11 GitHub ActionsのPermissionがLeast Privilegeで設定されている
- [ ] #12 CIからLocalと共通のProject Commandを利用している
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
- [ ] #8 Acceptance Criteriaをすべて満たしている
- [ ] #9 Frontend CIがGitHub Actions上で成功する
- [ ] #10 Backend CIがGitHub Actions上で成功する
- [ ] #11 OpenAPI CIがGitHub Actions上で成功する
- [ ] #12 Pull Request上で各CI結果を確認できる
- [ ] #13 Backend CIのTest DatabaseがDevelopment / Production Databaseから分離されている
- [ ] #14 Workflow設定がGit管理されている
- [ ] #15 必要な開発ドキュメントが更新されている
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. 現在のFrontend / Backend / OpenAPIのProject Commandを確認する
2. GitHub ActionsのFrontend CI Workflowを構築する
3. Frontend CIでFormat / Lint / Type Check / Test / Buildを実行する
4. GitHub ActionsのBackend CI Workflowを構築する
5. Backend CIへTest専用PostgreSQL Serviceを構築する
6. Backend CIでFormat / Static Analysis / Testを実行する
7. GitHub ActionsのOpenAPI CI Workflowを構築する
8. OpenAPI CIでLint / Bundle / Type生成 / Generated Type差分確認を実行する
9. Blocking CheckとMonitoring CheckをCI/CD方針に合わせて設定する
10. Workflow PermissionとAction Versionを確認する
11. Pull RequestおよびmainへのPushで各Workflowを実行確認する
12. 必要なドキュメントを更新する
<!-- SECTION:PLAN:END -->
