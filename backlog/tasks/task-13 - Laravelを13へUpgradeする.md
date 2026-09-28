---
id: TASK-13
title: Laravelを13へUpgradeする
status: In Progress
assignee: []
created_date: '2026-09-28 11:09'
updated_date: '2026-09-28 11:19'
labels:
  - phase-0
  - backend
milestone: Phase 0 - 開発基盤
dependencies:
  - TASK-2
  - TASK-3
references:
  - docs/04_技術選定/Backend/01_基本技術.md
  - docs/04_技術選定/Backend/12_Test.md
  - docs/06_開発・運用/01_開発環境.md
priority: high
ordinal: 13000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Backendの実装Versionを、Backend技術選定で採用しているLaravel 13へUpgradeする。

現在のBackend ProjectはLaravel 12で初期構築されているが、Backend技術選定ではPHP 8.5 / Laravel 13を採用している。

Backendのテスト基盤を構築するTASK-8へ進む前に、Framework Versionを技術選定と一致させ、Laravel 13を前提としたDependency構成へ更新する。

このTaskではLaravel 13へのUpgradeと既存Backend機能の動作確認を対象とし、Pest等のテスト基盤構築はTASK-8で実施する。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 BackendでLaravel 13.xが利用されている
- [ ] #2 composer.jsonのPHP / Laravel Version制約が技術選定と一致している
- [ ] #3 Laravel 13と互換性のあるDependency構成になっている
- [ ] #4 composer.lockがLaravel 13のDependency構成で更新されている
- [ ] #5 Docker開発環境上でLaravel Applicationが正常に起動する
- [ ] #6 既存のBackend Health Endpointが正常に応答する
- [ ] #7 既存のBackend Testが成功する
- [ ] #8 Laravel 13へのUpgradeによる不要な一時コードや互換対応が残っていない
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
- [ ] #8 Laravel 13.xへのUpgradeが完了している
- [ ] #9 Docker開発環境でBackendが正常に動作する
- [ ] #10 composer.json / composer.lockがGit管理されている
- [ ] #11 TASK-8をLaravel 13前提で開始できる状態になっている
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. 現在のLaravel / PHP / Composer / Dependency構成を確認する
2. Laravel 13のUpgrade要件とDependency Compatibilityを確認する
3. composer.jsonのPHP / Laravel Version制約を更新する
4. Composer DependencyをLaravel 13互換Versionへ更新する
5. Laravel 13のBreaking Changesによる影響を確認・修正する
6. Docker開発環境でLaravel Applicationを起動する
7. Backend Health Endpointの動作を確認する
8. 既存Backend Testを実行する
9. lint / static analysis等の既存Quality Checkを実行する
10. 必要なドキュメントを更新する
11. Self Reviewを実施する
<!-- SECTION:PLAN:END -->
