---
id: TASK-9
title: コード品質・静的解析環境を構築する
status: Done
assignee: []
created_date: '2026-09-27 08:35'
updated_date: '2026-09-30 06:50'
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

既に決定しているCode Quality方針に従い、FrontendではESLint / TypeScript / Complexity Monitoring、BackendではLaravel Pint / PHPStan + Larastan / CleanCode + PHP_CodeSnifferを中心とした品質チェックを整備する。

各Toolの責務を分離し、DeveloperがDocker開発環境から統一されたProject Commandで実行できる状態にする。

ComplexityはMVP初期ではBlocking Quality GateではなくMonitoringとして扱う。

CI上での自動実行・Required Checkの構築はTASK-10で行う。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Frontend/BFFでESLintによるLintを実行できる
- [x] #2 Frontend/BFFでTypeScript Type Checkを実行できる
- [x] #3 Frontend/BFFでESLint complexity RuleによるComplexity Monitoringを実行できる
- [x] #4 BackendでLaravel PintによるFormatting Checkを実行できる
- [x] #5 BackendでPHPStan + LarastanによるStatic Analysisを実行できる
- [x] #6 BackendでCleanCode + PHP_CodeSnifferによるComplexity / Maintainability Checkを実行できる
- [x] #7 Frontend / Backendそれぞれの品質チェックをProject Commandから実行できる
- [x] #8 Complexity CheckがMVP方針どおりMonitoringとして扱われている
- [x] #9 Docker開発環境上で各Code Quality / Static Analysis Commandを実行できる
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
- [x] #8 Acceptance Criteriaをすべて満たしている
- [x] #9 Frontend/BFFのCode Quality / Type CheckがDocker開発環境で成功する
- [x] #10 BackendのFormatting / Static AnalysisがDocker開発環境で成功する
- [x] #11 Frontend / BackendのComplexity Checkをローカルで実行できる
- [x] #12 必要なConfigurationがGit管理されている
- [x] #13 必要なProject Commandが定義されている
- [x] #14 必要な開発ドキュメントが更新されている
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Frontend / Backendの現在のCode Quality構成を確認する
2. FrontendのESLint / TypeScript実行環境を整理する
3. FrontendへComplexity Monitoringを設定する
4. BackendのLaravel Pint設定を整備する
5. BackendへPHPStan / Larastanを導入・設定する
6. BackendへCleanCode + PHP_CodeSnifferを導入・設定する
7. Frontend / BackendのProject Commandを整備する
8. Docker開発環境で各Quality Checkを実行する
9. Blocking CheckとMonitoring Checkの扱いが設計と一致することを確認する
10. 必要なドキュメントを更新する
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Frontend/BFFとBackendのCode Quality / Static Analysis環境を構築した。

- Frontend/BFFにESLint、TypeScript Type Check、ESLint complexity Ruleの実行Commandを整備した
- Frontend/BFFのBlocking Checkを`pnpm quality`、Complexity Monitoringを`pnpm complexity`として分離した
- BackendにLaravel Pint、PHPStan + Larastanを導入・設定した
- BackendのBlocking Checkを`composer quality`として整備した
- BackendのComplexity / Maintainability MonitoringとしてCleanCode + PHP_CodeSnifferを導入し、`backend/phpcs.xml`で必要なSniffのみを選択した
- BackendのMonitoring Commandを`composer complexity`としてBlocking Checkから分離した
- PHPMDはLaravel / SymfonyとのDependency Conflict、PhpMetricsは必要なCode Quality責務を十分に満たさないため不採用とした
- Complexity / MaintainabilityはMVP初期ではBlocking Quality GateとせずMonitoringとして扱う方針をドキュメントへ反映した
- Docker開発環境でFrontend / BackendのQuality、Complexity、Testを実行し成功を確認した
- FrontendのProduction Buildが成功することを確認した
- 関連するArchitecture、技術選定、CI/CD、開発運用、非機能要件ドキュメントを現在のCode Quality方針へ更新した
- CIでの自動実行およびRequired Checkの構築はTASK-10で行う
<!-- SECTION:FINAL_SUMMARY:END -->
