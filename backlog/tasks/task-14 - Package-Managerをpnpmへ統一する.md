---
id: TASK-14
title: Package Managerをpnpmへ統一する
status: In Progress
assignee: []
created_date: '2026-09-29 13:13'
updated_date: '2026-09-29 13:17'
labels:
  - phase-0
  - frontend
  - openapi
milestone: Phase 0 - 開発基盤
dependencies:
  - TASK-1
  - TASK-3
  - TASK-5
references:
  - docs/04_技術選定/Frontend/14_採用技術一覧.md
  - docs/04_技術選定/04_API・OpenAPI.md
  - docs/06_開発・運用/01_開発環境.md
  - docs/06_開発・運用/03_CICD方針.md
priority: high
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Frontend / BFFおよびOpenAPI開発環境のPackage Managerをnpmからpnpmへ統一する。

設計書で採用しているpnpmをProjectの標準Package Managerとし、package.json、Lockfile、Docker開発環境、npm依存のScriptおよび関連Documentationをpnpm前提へ変更する。

pnpmのVersionはpackageManagerで固定し、再現可能なDependency Install環境を構築する。

本Taskではpnpm Workspaceへの再構成は行わず、FrontendとOpenAPIの既存構成を維持したままPackage Managerを統一する。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 FrontendのPackage Managerがpnpmへ変更されている
- [ ] #2 OpenAPI開発環境のPackage Managerがpnpmへ変更されている
- [ ] #3 Frontend / OpenAPIのpackage.jsonでpnpm VersionがpackageManagerにより固定されている
- [ ] #4 package-lock.jsonが削除され、pnpm-lock.yamlがGit管理されている
- [ ] #5 Frontend / OpenAPIのDockerfileがpnpmを利用してDependencyをInstallする
- [ ] #6 OpenAPIのpackage.json Scriptからnpm依存のCommandが除去されている
- [ ] #7 Docker環境でFrontendのDependency InstallおよびApplication起動が成功する
- [ ] #8 FrontendのLint / Test / Buildがpnpm環境で成功する
- [ ] #9 OpenAPIのLint / Generate / Checkがpnpm環境で成功する
- [ ] #10 npmを前提とした現在有効なConfiguration / Documentationがpnpm前提へ更新されている
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
- [ ] #8 Frontend / OpenAPIからpackage-lock.jsonが削除されている
- [ ] #9 Frontend / OpenAPIのpnpm-lock.yamlがGit管理されている
- [ ] #10 Docker環境でpnpmを利用したFrontend / OpenAPIの実行が成功している
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Frontend / OpenAPIの現在のnpm利用箇所を確認する
2. Projectで利用するpnpm Versionを決定する
3. Frontend / OpenAPIのpackage.jsonへpackageManagerを設定する
4. package-lock.jsonを削除し、pnpm-lock.yamlを生成する
5. Frontend / OpenAPIのDockerfileをpnpm対応へ変更する
6. OpenAPIのnpm依存Scriptをpnpmへ変更する
7. npm前提となっている関連Documentationをpnpmへ更新する
8. Docker Imageを再Buildし、pnpmによるDependency Installを確認する
9. FrontendのLint / Test / Buildを実行する
10. OpenAPIのLint / Generate / Checkを実行する
11. npm由来の不要なConfiguration / Lockfileが残っていないことを確認する
<!-- SECTION:PLAN:END -->
