---
id: TASK-29
title: Makefileを導入して開発・運用コマンドを統一する
status: In Progress
assignee: []
created_date: '2026-10-08 11:42'
updated_date: '2026-10-08 11:47'
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
- [ ] #1 リポジトリルートにMakefileが配置されている
- [ ] #2 make helpで利用可能なコマンドと説明を確認できる
- [ ] #3 Development環境のSetup / Up / Down / Resetを実行できる
- [ ] #4 Production環境のBuild / Up / Downを実行できる
- [ ] #5 Frontendの品質チェックとテストを実行できる
- [ ] #6 Backendの品質チェックとテストを実行できる
- [ ] #7 OpenAPIの品質チェックを実行できる
- [ ] #8 Smoke Testを実行できる
- [ ] #9 既存のShell ScriptとDocker Compose構成を再利用し、処理の重複を避けている
- [ ] #10 開発ドキュメントにMakefileの使用方法が記載されている
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
