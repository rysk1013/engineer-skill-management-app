---
id: TASK-14
title: Package Managerをpnpmへ統一する
status: Done
assignee: []
created_date: '2026-09-29 13:13'
updated_date: '2026-09-29 15:42'
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
- [x] #1 FrontendのPackage Managerがpnpmへ変更されている
- [x] #2 OpenAPI開発環境のPackage Managerがpnpmへ変更されている
- [x] #3 Frontend / OpenAPIのpackage.jsonでpnpm VersionがpackageManagerにより固定されている
- [x] #4 package-lock.jsonが削除され、pnpm-lock.yamlがGit管理されている
- [x] #5 Frontend / OpenAPIのDockerfileがpnpmを利用してDependencyをInstallする
- [x] #6 OpenAPIのpackage.json Scriptからnpm依存のCommandが除去されている
- [x] #7 Docker環境でFrontendのDependency InstallおよびApplication起動が成功する
- [x] #8 FrontendのLint / Test / Buildがpnpm環境で成功する
- [x] #9 OpenAPIのLint / Generate / Checkがpnpm環境で成功する
- [x] #10 npmを前提とした現在有効なConfiguration / Documentationがpnpm前提へ更新されている
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
- [x] #8 Frontend / OpenAPIからpackage-lock.jsonが削除されている
- [x] #9 Frontend / OpenAPIのpnpm-lock.yamlがGit管理されている
- [x] #10 Docker環境でpnpmを利用したFrontend / OpenAPIの実行が成功している
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Frontend / BFFおよびOpenAPI開発環境のPackage Managerをnpmからpnpmへ統一した。

- Frontend / OpenAPIでpnpm 12.6.0をpackageManagerにより固定
- package-lock.jsonを削除し、pnpm-lock.yamlへ移行
- DockerfileをCorepack / pnpm対応へ変更
- OpenAPIのnpm依存Scriptをpnpmへ変更
- FrontendでLint / Test / Buildが成功することを確認
- OpenAPIでLint / Generate / Checkが成功することを確認
- Docker環境でpnpmによるDependency InstallおよびApplication起動を確認
- 関連する技術選定・開発環境・CI/CD Documentationをpnpm前提へ更新
- 現在有効なConfiguration / Documentationにnpm依存が残っていないことを確認
<!-- SECTION:FINAL_SUMMARY:END -->
