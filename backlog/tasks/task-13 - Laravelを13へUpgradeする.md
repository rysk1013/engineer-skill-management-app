---
id: TASK-13
title: Laravelを13へUpgradeする
status: Done
assignee: []
created_date: '2026-09-28 11:09'
updated_date: '2026-09-28 11:59'
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
- [x] #1 BackendでLaravel 13.xが利用されている
- [x] #2 composer.jsonのPHP / Laravel Version制約が技術選定と一致している
- [x] #3 Laravel 13と互換性のあるDependency構成になっている
- [x] #4 composer.lockがLaravel 13のDependency構成で更新されている
- [x] #5 Docker開発環境上でLaravel Applicationが正常に起動する
- [x] #6 既存のBackend Health Endpointが正常に応答する
- [x] #7 既存のBackend Testが成功する
- [x] #8 Laravel 13へのUpgradeによる不要な一時コードや互換対応が残っていない
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
- [x] #8 Laravel 13.xへのUpgradeが完了している
- [x] #9 Docker開発環境でBackendが正常に動作する
- [x] #10 composer.json / composer.lockがGit管理されている
- [x] #11 TASK-8をLaravel 13前提で開始できる状態になっている
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Laravel BackendをLaravel 12からLaravel 13へUpgradeした。

- PHP Version制約を^8.5へ更新
- laravel/frameworkを^13.0へ更新（13.33.0を導入）
- laravel/tinkerを^3.0へ更新（3.0.2を導入）
- PHPUnitを^12.0へ更新（12.5.36を導入）
- Laravel 13に必要なComposer Dependencyを更新
- composer validate成功
- Laravel Applicationの起動を確認
- /up がHTTP 200で応答することを確認
- /api/v1/health がHTTP 200で応答することを確認
- composer test成功（2 tests / 2 assertions）
- Pint --test成功（27 files）
- Laravel 13 Upgradeによる既存コードへの追加修正は不要であることを確認
- 技術選定Documentは既にPHP 8.5 / Laravel 13を採用しているため更新不要

これによりTASK-8のBackendテスト基盤構築をLaravel 13前提で開始できる状態になった。
<!-- SECTION:FINAL_SUMMARY:END -->
