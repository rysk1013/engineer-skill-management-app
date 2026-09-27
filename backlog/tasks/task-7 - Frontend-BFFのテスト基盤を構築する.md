---
id: TASK-7
title: Frontend/BFFのテスト基盤を構築する
status: Done
assignee: []
created_date: '2026-09-25 14:47'
updated_date: '2026-09-27 08:09'
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
- [x] #1 決定済みのFrontendテスト戦略に基づくTest Toolが導入されている
- [x] #2 FrontendのUnit Testを実行できる
- [x] #3 FrontendのComponent Testを実行できる
- [x] #4 BFF / Server-side CodeのTestを実行できる
- [x] #5 Test用の共通設定がProject内に定義されている
- [x] #6 npm scriptからFrontend Testを実行できる
- [x] #7 Docker開発環境上でFrontend Testが成功する
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
- [x] #9 Frontend TestがDocker開発環境で成功する
- [x] #10 必要な設定ファイルがGit管理されている
- [x] #11 必要な開発ドキュメントが更新されている
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
- VitestをFrontend/BFFのTest Runnerとして導入
- React Testing Library、user-event、jest-dom、jsdomを導入しComponent Test環境を構築
- MSWを導入し、HTTP Network BoundaryをMockする共通Test環境を構築
- Vitest共通設定、Test Setup、MSW Handler / Serverを追加
- Unit Test、Component Test、Server-side / API Client Testの最小構成を実装
- npm test / test:watchからFrontend Testを実行できるように設定
- Docker環境でTest、Lint、Type Check、Production Buildが成功することを確認
- Frontend Testの実行方法と共通構成を開発環境ドキュメントへ反映
<!-- SECTION:FINAL_SUMMARY:END -->
