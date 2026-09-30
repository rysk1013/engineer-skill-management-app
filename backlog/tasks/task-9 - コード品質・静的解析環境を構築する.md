---
id: TASK-9
title: コード品質・静的解析環境を構築する
status: In Progress
assignee: []
created_date: '2026-09-27 08:35'
updated_date: '2026-09-30 01:56'
labels:
  - phase-0
  - frontend
  - backend
  - code-quality
milestone: Phase 0 - 開発基盤
dependencies:
  - TASK-1
  - TASK-2
  - TASK-3
  - TASK-7
references:
  - docs/04_技術選定/Frontend/13_コード品質・Developer-Experience.md
  - docs/04_技術選定/Backend/13_Static-Analysis・Code-Quality.md
  - docs/06_開発・運用/05_コード品質・複雑度監視.md
  - docs/06_開発・運用/01_開発環境.md
priority: high
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Frontend/BFFおよびLaravel Backendで、コード品質・静的解析を継続的に確認できる開発環境を構築する。

既に決定しているCode Quality方針に従い、FrontendではESLint / TypeScript / Complexity Monitoring、BackendではLaravel Pint / PHPStan + Larastan / PHPMDを中心とした品質チェックを整備する。

各Toolの責務を分離し、DeveloperがDocker開発環境から統一されたProject Commandで実行できる状態にする。

ComplexityはMVP初期ではBlocking Quality GateではなくMonitoringとして扱う。

CI上での自動実行・Required Checkの構築はTASK-10で行う。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Frontend/BFFでESLintによるLintを実行できる
- [ ] #2 Frontend/BFFでTypeScript Type Checkを実行できる
- [ ] #3 Frontend/BFFでESLint complexity RuleによるComplexity Monitoringを実行できる
- [ ] #4 BackendでLaravel PintによるFormatting Checkを実行できる
- [ ] #5 BackendでPHPStan + LarastanによるStatic Analysisを実行できる
- [ ] #6 BackendでPHPMDによるComplexity / Maintainability Checkを実行できる
- [ ] #7 Frontend / Backendそれぞれの品質チェックをProject Commandから実行できる
- [ ] #8 Complexity CheckがMVP方針どおりMonitoringとして扱われている
- [ ] #9 Docker開発環境上で各Code Quality / Static Analysis Commandを実行できる
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
- [ ] #9 Frontend/BFFのCode Quality / Type CheckがDocker開発環境で成功する
- [ ] #10 BackendのFormatting / Static AnalysisがDocker開発環境で成功する
- [ ] #11 Frontend / BackendのComplexity Checkをローカルで実行できる
- [ ] #12 必要なConfigurationがGit管理されている
- [ ] #13 必要なProject Commandが定義されている
- [ ] #14 必要な開発ドキュメントが更新されている
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Frontend / Backendの現在のCode Quality構成を確認する
2. FrontendのESLint / TypeScript実行環境を整理する
3. FrontendへComplexity Monitoringを設定する
4. BackendのLaravel Pint設定を整備する
5. BackendへPHPStan / Larastanを導入・設定する
6. BackendへPHPMDを導入・設定する
7. Frontend / BackendのProject Commandを整備する
8. Docker開発環境で各Quality Checkを実行する
9. Blocking CheckとMonitoring Checkの扱いが設計と一致することを確認する
10. 必要なドキュメントを更新する
<!-- SECTION:PLAN:END -->
