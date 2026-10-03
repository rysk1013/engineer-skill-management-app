---
id: TASK-17
title: Development / Production環境操作をスクリプト化する
status: Done
assignee: []
created_date: '2026-10-02 14:53'
updated_date: '2026-10-03 04:53'
labels:
  - phase-0
  - docker
  - development-environment
  - production
  - scripts
milestone: Phase 0 - 開発基盤
dependencies:
  - TASK-16
references:
  - docs/06_開発・運用/01_開発環境.md
priority: high
ordinal: 17000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Development / Production環境の構築・起動・停止・初期化・疎通確認をスクリプト化し、環境操作手順を統一・再現可能にする。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Development環境を初期構築するスクリプトが存在する
- [x] #2 Development環境を起動するスクリプトが存在する
- [x] #3 Development環境を停止するスクリプトが存在する
- [x] #4 Development環境を初期化するスクリプトが存在する
- [x] #5 Production Imageを構築するスクリプトが存在する
- [x] #6 Production構成を起動するスクリプトが存在する
- [x] #7 Production構成を停止するスクリプトが存在する
- [x] #8 Development / Production環境の疎通確認を実行できる
- [x] #9 スクリプトがエラー発生時に非0終了コードを返す
- [x] #10 環境操作方法がドキュメント化されている
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
- [x] #8 新規clone相当の状態からDevelopment環境を構築できる
- [x] #9 Development環境をスクリプト経由で起動・停止できる
- [x] #10 Production構成をローカルでbuild・起動・停止できる
- [x] #11 Frontend / Backend / Databaseの疎通確認が成功する
- [x] #12 Shell Scriptのsyntax checkが成功する
- [x] #13 TASK-11の統合確認で利用可能な状態になっている
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. 現在のDevelopment / Production環境の起動・停止・build手順を整理する
2. scriptsディレクトリとスクリプト命名方針を決定する
3. Development環境の初期構築スクリプトを実装する
4. Development環境の起動・停止・初期化スクリプトを実装する
5. Production Imageのbuildスクリプトを実装する
6. Production構成の起動・停止スクリプトを実装する
7. Development / Production共通の疎通確認スクリプトを実装する
8. エラー処理と終了コードを整理する
9. Shell Scriptのsyntax checkを実施する
10. 新規clone相当のDevelopment環境構築を検証する
11. Production構成のbuild・起動・停止を検証する
12. Frontend / Backend / Databaseの疎通確認を実施する
13. 環境操作方法をドキュメントへ反映する
14. TASK-11で利用できる状態になっていることを確認する
15. Self Reviewを実施する
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Development / Production環境操作をShell Scriptで統一し、環境構築・起動・停止・初期化・疎通確認を再現可能にした。

- Development用にdev-setup.sh / dev-up.sh / dev-down.sh / dev-reset.shを追加
- Production相当環境用にprod-build.sh / prod-up.sh / prod-down.shを追加
- Frontend / Backendの疎通確認用にsmoke-test.shを追加
- Docker Compose共通処理をscripts/lib/common.shへ分離
- compose.production.yamlと.env.production.exampleを追加
- Development / ProductionでDocker Compose Projectを分離し、Image / Container / Network / Volumeの衝突を防止
- Development環境の初回構築からMigration / OpenAPI生成 / Smoke Testまでをdev-setup.shで自動化
- dev-reset.shでNamed Volume削除後にDevelopment環境を再構築可能にした
- Production Imageのbuild・起動・停止・疎通確認をローカルで検証
- 全Shell Scriptのsyntax checkを実施
- docs/06_開発・運用/01_開発環境.mdへ環境操作手順とProduction相当環境の方針を反映
<!-- SECTION:FINAL_SUMMARY:END -->
