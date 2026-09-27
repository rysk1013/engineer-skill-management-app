---
id: TASK-12
title: FrontendにPrettierを導入する
status: Done
assignee: []
created_date: '2026-09-27 08:50'
updated_date: '2026-09-27 12:03'
labels:
  - phase-0
  - frontend
  - code-quality
milestone: Phase 0 - 開発基盤
dependencies:
  - TASK-1
  - TASK-3
  - TASK-7
references:
  - docs/04_技術選定/Frontend/13_コード品質・Developer-Experience.md
  - docs/06_開発・運用/05_コード品質・複雑度監視.md
  - docs/06_開発・運用/01_開発環境.md
priority: high
ordinal: 12000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Frontend/BFFのCode Formattingを統一するため、Prettierを導入する。

PrettierをFrontend/BFFのFormattingのSource of Truthとし、ESLintはCode Quality、PrettierはCode Formattingという責務分離を行う。

SemicolonについてはPrettierの設定で有効化し、Frontend/BFFのTypeScript / TSX等のコードを統一されたFormatへ整形する。

また、DeveloperがDocker開発環境からFormatとFormat Checkを実行できるProject Commandを整備する。

CIへの組み込みはTASK-10で行う。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Frontend/BFFにPrettierがDevelopment Dependencyとして導入されている
- [x] #2 PrettierのConfigurationがGit管理されている
- [x] #3 Semicolonが有効になるようPrettierが設定されている
- [x] #4 PrettierとESLintの責務が分離されている
- [x] #5 Frontend/BFFのFormatを実行するProject Commandが定義されている
- [x] #6 Frontend/BFFのFormat Checkを実行するProject Commandが定義されている
- [x] #7 既存のFrontend/BFFコードがPrettierによってFormatされている
- [x] #8 Docker開発環境上でFormat Checkを正常に実行できる
- [x] #9 Prettier導入後もLint / Type Check / Test / Buildが成功する
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
- [x] #9 PrettierによるFormat Checkが成功する
- [x] #10 ESLintが成功する
- [x] #11 TypeScript Type Checkが成功する
- [x] #12 Frontend Testが成功する
- [x] #13 Next.js Buildが成功する
- [x] #14 必要なConfigurationとpackage-lock.jsonがGit管理されている
- [x] #15 必要な開発ドキュメントが更新されている
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. 現在のFrontend Formatting設定とDependencyを確認する
2. PrettierをDevelopment Dependencyとして導入する
3. Prettier Configurationを作成しSemicolonを有効化する
4. Prettierの対象外ファイルを整理する
5. package.jsonへFormat / Format Check Commandを追加する
6. 既存のFrontend/BFFコードをPrettierでFormatする
7. Docker開発環境でFormat Checkを実行する
8. Lint / Type Check / Test / Buildを実行する
9. 必要な開発ドキュメントを更新する
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
- PrettierをFrontend/BFFのDevelopment Dependencyとして導入した
- Prettier Configurationを追加し、Semicolonを有効化した
- ESLintをCode Quality、PrettierをFormattingとして責務を分離した
- `format` / `format:check` Commandを追加した
- OpenAPI Generated CodeをPrettierの対象外に設定した
- 既存のFrontend/BFF CodeへPrettierを適用した
- Docker開発環境でFormat Checkの成功を確認した
- ESLint / TypeScript Type Check / Frontend Test / Next.js Buildの成功を確認した
- Frontend Formattingの開発ドキュメントを更新した
<!-- SECTION:FINAL_SUMMARY:END -->
