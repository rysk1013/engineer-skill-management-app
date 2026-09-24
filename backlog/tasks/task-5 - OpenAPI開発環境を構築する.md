---
id: TASK-5
title: OpenAPI開発環境を構築する
status: Done
assignee: []
created_date: '2026-09-23 11:29'
updated_date: '2026-09-24 12:49'
labels:
  - phase-0
  - openapi
  - infrastructure
milestone: Phase 0 - 開発基盤
dependencies:
  - TASK-1
  - TASK-3
references:
  - docs/03_システム設計/03_API/README.md
  - docs/03_システム設計/03_API/03_API共通仕様.md
  - docs/04_技術選定/07_API・OpenAPI.md
  - docs/06_開発・運用/01_開発環境.md
priority: high
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
OpenAPI FirstでAPI開発を進めるための開発環境を構築する。

Redocly CLIによるOpenAPI仕様のLint・Bundleと、`openapi-typescript`によるTypeScript型生成を実行できる状態にする。

Phase 1以降で、API単位に以下のサイクルを回せることを目的とする。

OpenAPI定義 → Lint → Bundle → TypeScript型生成 → Backend / BFF実装

このタスクではOpenAPI開発基盤の構築を対象とし、Employee APIなどの個別API仕様の本格的な定義は対象外とする。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 OpenAPI仕様を配置するディレクトリ構成が決定している
- [x] #2 Redocly CLIが導入されている
- [x] #3 openapi-typescriptが導入されている
- [x] #4 動作確認用の最小構成OpenAPI仕様が存在する
- [x] #5 OpenAPI仕様に対してLintを実行できる
- [x] #6 OpenAPI仕様からBundleを生成できる
- [x] #7 BundleしたOpenAPI仕様からTypeScript型を生成できる
- [x] #8 OpenAPI関連コマンドを統一されたコマンドから実行できる
- [x] #9 Dockerベースの開発環境からLint・Bundle・型生成を実行できる
- [x] #10 OpenAPI関連の生成物についてGit管理方針が決定している
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Acceptance Criteria are satisfied
- [x] #2 Required tests pass
- [x] #3 Required lint and static analysis pass
- [x] #4 Documentation is updated if needed
- [x] #5 No temporary or debug code remains
- [ ] #6 Self review is completed
- [ ] #7 Final Summary is completed
- [ ] #8 Acceptance Criteriaをすべて満たしている
- [ ] #9 Lint → Bundle → TypeScript型生成の一連の処理が正常に完了する
- [ ] #10 必要な設定ファイルがGit管理されている
- [ ] #11 必要な開発ドキュメントが更新されている
- [ ] #12 ローカルのDocker開発環境で動作確認が完了している
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. OpenAPI関連ファイルのディレクトリ構成を決定する
2. Redocly CLIを導入する
3. `openapi-typescript`を導入する
4. Redocly CLIの設定ファイルを作成する
5. 動作確認用の最小構成OpenAPI仕様を作成する
6. OpenAPI Lintを実行できるようにする
7. OpenAPI Bundleを生成できるようにする
8. BundleからTypeScript型を生成できるようにする
9. OpenAPI関連コマンドを`package.json` scriptsなどに整理する
10. 生成物のGit管理方針を決定し、必要に応じて`.gitignore`を更新する
11. Docker開発環境から一連のコマンドを実行して動作確認する
12. 必要なドキュメントを更新する
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
OpenAPI First開発環境を構築した。Redocly CLIによるLint・Bundle、openapi-typescriptによるTypeScript型生成、専用OpenAPI Docker Containerからの実行環境を整備した。openapi/distはGit管理対象外、frontend/src/generated/api/schema.d.tsはGit管理対象とした。関連ドキュメントも更新した。
<!-- SECTION:FINAL_SUMMARY:END -->
