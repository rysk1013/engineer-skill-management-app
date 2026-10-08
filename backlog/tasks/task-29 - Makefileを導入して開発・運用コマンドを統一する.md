---
id: TASK-29
title: Makefileを導入して開発・運用コマンドを統一する
status: Done
assignee: []
created_date: '2026-10-08 11:42'
updated_date: '2026-10-08 13:10'
labels: []
milestone: Phase 2 - 認証・認可基盤
dependencies: []
references:
  - compose.yaml
  - compose.production.yaml
  - scripts/
  - frontend/package.json
  - backend/composer.json
  - openapi/package.json
  - docs/06_開発・運用/01_開発環境.md
priority: high
type: feature
ordinal: 29000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
既存のDevelopment / Production環境操作スクリプト、およびFrontend / Backend / OpenAPIの開発・品質チェックコマンドをMakefileから統一的に実行できるようにする。

Makefileはコマンド実行の入口として位置づけ、既存のscripts/に実装された処理を原則として再利用する。

対象:
- Development環境のSetup / Up / Down / Reset
- Production環境のBuild / Up / Down
- Frontend / Backend / OpenAPIの品質チェック
- テスト実行
- Smoke Test
- Help表示
- 開発ドキュメントの更新

既存のDocker Compose構成とShell Scriptの責務を維持し、MVPに不要な複雑化を避ける。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 リポジトリルートにMakefileが配置されている
- [x] #2 make helpで利用可能なコマンドと説明を確認できる
- [x] #3 Development環境のSetup / Up / Down / Resetを実行できる
- [x] #4 Production環境のBuild / Up / Downを実行できる
- [x] #5 Frontendの品質チェックとテストを実行できる
- [x] #6 Backendの品質チェックとテストを実行できる
- [x] #7 OpenAPIの品質チェックを実行できる
- [x] #8 Smoke Testを実行できる
- [x] #9 既存のShell ScriptとDocker Compose構成を再利用し、処理の重複を避けている
- [x] #10 開発ドキュメントにMakefileの使用方法が記載されている
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
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. 既存のscripts/、Docker Compose構成、品質チェックコマンドを確認する
2. Makefileのターゲット名と命名規則を決定する
3. リポジトリルートにMakefileを作成する
4. Development / Production環境操作ターゲットを実装する
5. Frontend / Backend / OpenAPIの品質チェック・テストターゲットを実装する
6. Help表示とSmoke Testターゲットを実装する
7. 各ターゲットの動作確認を実施する
8. 開発ドキュメントを更新する
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## 実装内容
- リポジトリルートにMakefileを追加した
- Development環境のSetup / Up / Down / Resetターゲットを追加した
- Production相当環境のBuild / Up / Downターゲットを追加した
- Frontend / Backend / OpenAPIの品質チェック・テストターゲットを追加した
- quality / testの統合ターゲットを追加した
- make helpによるコマンド一覧表示を追加した
- 既存のShell Scriptとpnpm / Composer Scriptsを再利用した
- docs/06_開発・運用/01_開発環境.mdを更新した

## 検証結果
- make help：成功
- make dev-up：成功
- make smoke-test：成功（Frontend / Backend / Redis）
- Frontend品質チェック・テスト：成功
- Backend品質チェック・テスト：成功
- OpenAPI品質チェック・型生成：成功
- make quality / make test：成功
- Shell Script構文チェック：成功
- Development / Production Compose設定検証：成功
- 環境操作ターゲットのDry Run：成功
- git diff --check：成功

## 補足・制約
- dev-resetおよびProduction相当環境の操作は実行せず、Dry Runで委譲処理を検証した
- dev-resetはDocker Volumeを削除するため、実行時には注意が必要
- smoke-test.shのRedis確認はDevelopment用Compose設定を参照するため、Production相当環境での利用には追加対応が必要
- Makefileは既存スクリプトの実行入口とし、Docker Composeの処理を重複実装しない方針を維持した
<!-- SECTION:FINAL_SUMMARY:END -->
