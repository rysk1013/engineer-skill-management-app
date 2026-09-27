---
id: TASK-12
title: FrontendにPrettierを導入する
status: To Do
assignee: []
created_date: '2026-09-27 08:50'
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
- [ ] #1 Frontend/BFFにPrettierがDevelopment Dependencyとして導入されている
- [ ] #2 PrettierのConfigurationがGit管理されている
- [ ] #3 Semicolonが有効になるようPrettierが設定されている
- [ ] #4 PrettierとESLintの責務が分離されている
- [ ] #5 Frontend/BFFのFormatを実行するProject Commandが定義されている
- [ ] #6 Frontend/BFFのFormat Checkを実行するProject Commandが定義されている
- [ ] #7 既存のFrontend/BFFコードがPrettierによってFormatされている
- [ ] #8 Docker開発環境上でFormat Checkを正常に実行できる
- [ ] #9 Prettier導入後もLint / Type Check / Test / Buildが成功する
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
- [ ] #9 PrettierによるFormat Checkが成功する
- [ ] #10 ESLintが成功する
- [ ] #11 TypeScript Type Checkが成功する
- [ ] #12 Frontend Testが成功する
- [ ] #13 Next.js Buildが成功する
- [ ] #14 必要なConfigurationとpackage-lock.jsonがGit管理されている
- [ ] #15 必要な開発ドキュメントが更新されている
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
