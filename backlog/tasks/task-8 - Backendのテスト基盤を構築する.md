---
id: TASK-8
title: Backendのテスト基盤を構築する
status: In Progress
assignee: []
created_date: '2026-09-27 08:31'
updated_date: '2026-09-28 12:06'
labels:
  - phase-0
  - backend
milestone: Phase 0 - 開発基盤
dependencies:
  - TASK-13
references:
  - docs/02_アーキテクチャ/01_Backend/Laravel/12_テスト戦略.md
  - docs/04_技術選定/Backend/12_Test.md
  - docs/06_開発・運用/01_開発環境.md
priority: high
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Laravel Backendのテストを継続的に実装・実行できるように、Backendのテスト基盤を構築する。

既に決定しているBackend ArchitectureおよびBackend技術選定のテスト方針に従い、Pest / PHPUnit / Laravel Testingを中心としたTest Runner・設定・Test Suite構成を実際のBackend Projectへ導入する。

また、Infrastructure / Feature TestでProductionと同じPostgreSQLを利用できるTest Database環境を整備する。

このTaskでは個別の業務機能に対する網羅的なテスト実装ではなく、今後のMVP実装で利用する共通のBackendテスト実行基盤を整備することを目的とする。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 決定済みのBackendテスト戦略に基づくTest Toolが導入されている
- [ ] #2 Pestを利用してBackendのUnit Testを実行できる
- [ ] #3 Laravel Feature Testを実行できる
- [ ] #4 PostgreSQLを利用したIntegration Testを実行できる
- [ ] #5 Unit / Integration / FeatureのTest Suiteを区別して実行できる
- [ ] #6 Test専用のConfigurationとPostgreSQL Databaseが定義されている
- [ ] #7 Docker開発環境上でBackend Testが成功する
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
- [ ] #9 Backend TestがDocker開発環境で成功する
- [ ] #10 Test DatabaseがDevelopment Databaseから分離されている
- [ ] #11 必要な設定ファイルがGit管理されている
- [ ] #12 必要な開発ドキュメントが更新されている
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. 現在のBackend Test構成とDependencyを確認する
2. Pest / PHPUnit / Pest Laravel Pluginの構成を確認・整備する
3. Backend Test DirectoryとTest Suite構成を整備する
4. Test専用Configurationを整備する
5. Test専用PostgreSQL Databaseを構築する
6. Unit Testの最小構成を実装して実行確認する
7. Integration Testの最小構成を実装してPostgreSQL接続を確認する
8. Feature Testの最小構成を実装して実行確認する
9. Test Suiteを個別・一括実行できるようにする
10. Docker開発環境でBackend Test全体を実行する
11. 必要なドキュメントを更新する
<!-- SECTION:PLAN:END -->
