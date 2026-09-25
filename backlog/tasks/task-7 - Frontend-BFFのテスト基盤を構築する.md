---
id: TASK-7
title: Frontend/BFFのテスト基盤を構築する
status: In Progress
assignee: []
created_date: '2026-09-25 14:47'
updated_date: '2026-09-25 14:54'
labels:
  - phase-0
  - frontend
milestone: Phase 0 - 開発基盤
dependencies:
  - TASK-1
  - TASK-3
references:
  - docs/02_アーキテクチャ/02_Frontend/NextJS/13_テスト戦略.md
  - docs/04_技術選定/Frontend/12_テスト.md
  - docs/06_開発・運用/01_開発環境.md
priority: high
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Next.js Frontend/BFFのテストを継続的に実装・実行できるように、Frontendのテスト基盤を構築する。

既に決定しているFrontend ArchitectureおよびFrontend技術選定のテスト方針に従い、必要なTest Runner・Testing Library・設定・npm scriptsを実際のFrontend Projectへ導入する。

このTaskでは個別の業務機能に対する網羅的なテスト実装ではなく、今後のMVP実装で利用する共通のテスト実行基盤を整備することを目的とする。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 決定済みのFrontendテスト戦略に基づくTest Toolが導入されている
- [ ] #2 FrontendのUnit Testを実行できる
- [ ] #3 FrontendのComponent Testを実行できる
- [ ] #4 BFF / Server-side CodeのTestを実行できる
- [ ] #5 Test用の共通設定がProject内に定義されている
- [ ] #6 npm scriptからFrontend Testを実行できる
- [ ] #7 Docker開発環境上でFrontend Testが成功する
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
- [ ] #9 Frontend TestがDocker開発環境で成功する
- [ ] #10 必要な設定ファイルがGit管理されている
- [ ] #11 必要な開発ドキュメントが更新されている
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. 現在のFrontend構成とDependencyを確認する
2. Vitest / Testing Library / user-event / jest-dom / jsdomを導入する
3. Vitestの共通設定とTest Setupを作成する
4. Unit Testの最小構成を実装して実行確認する
5. Component Testの最小構成を実装して実行確認する
6. MSWを導入しNetwork Mockの共通構成を作成する
7. BFF / Server-side CodeのTest方法を確認して最小Testを実装する
8. npm scriptsを整理する
9. Docker開発環境でFrontend Test全体を実行する
10. Lint / Type Check / Production Buildとの整合性を確認する
11. 必要なドキュメントを更新する
<!-- SECTION:PLAN:END -->
