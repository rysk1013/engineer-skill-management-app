---
id: TASK-16
title: Docker環境を運用可能な構成へ整理する
status: Done
assignee: []
created_date: '2026-10-01 14:11'
updated_date: '2026-10-02 14:13'
labels:
  - phase-0
  - docker
  - infrastructure
dependencies:
  - TASK-1
  - TASK-2
  - TASK-3
  - TASK-9
  - TASK-10
references:
  - docs/06_開発・運用/01_開発環境.md
  - docs/06_開発・運用/02_CI-Platform.md
  - docs/04_技術選定/Frontend/01_基本技術.md
  - docs/04_技術選定/Backend/01_基本技術.md
priority: high
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Docker開発環境を見直し、Development / Productionで主要なRuntimeと通信経路を可能な限り共通化する。

FrontendはNode.js、BackendはNginx + PHP-FPMをDevelopment / Productionで共通して利用する。
Backendではphp artisan serveを使用せず、NginxからFastCGI経由でPHP-FPMへ接続してLaravelを実行する。

Developmentではbind mount、開発用依存関係、hot reloadなどの開発支援機能を利用し、Productionではbuild済みApplication、Production依存関係、Production向け設定を利用する。

Docker ComposeはLocal Development環境として利用し、Production向けContainer Imageは将来RenderやAWS ECS等のContainer実行環境へ展開可能な構成とする。

OpenAPI ContainerはDevelopment / CI用Toolingとして扱い、Production Runtimeには含めない。

本TaskではProduction Infrastructureそのものの構築、Managed PostgreSQL、Load Balancer、TLS、Cloud固有設定は対象外とする。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 FrontendのDockerfileがDevelopment / Production向けのBuildを提供している
- [x] #2 FrontendのProduction ImageがNext.jsのProduction Runtimeとして起動できる
- [x] #3 BackendのDockerfileがDevelopment / Production向けのBuildを提供している
- [x] #4 BackendがDevelopment / Productionの両方でPHP-FPMを使用する構成になっている
- [x] #5 NginxからFastCGI経由でPHP-FPMへ接続しLaravel APIへアクセスできる
- [x] #6 Backendでphp artisan serveを使用していない
- [x] #7 Development環境でSource Codeの変更をContainerへ反映できる
- [x] #8 Production Imageに不要なDevelopment依存関係やSource bind mountを必要としない
- [x] #9 OpenAPI ContainerがDevelopment / CI用ToolingとしてProduction Runtimeから分離されている
- [x] #10 Docker Composeを利用してFrontend / Backend / PostgreSQL / OpenAPIを含むDevelopment環境を起動・検証できる
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
- Backend DockerfileをPHP-FPMベースのmulti-stage buildへ変更する
- Backend用Nginx設定とContainer構成を追加する
- Development環境のBackendをNginx + PHP-FPM構成へ変更する
- Frontend DockerfileをDevelopment / Production対応のmulti-stage buildへ変更する
- Next.js Production Imageをstandalone構成で実行できるようにする
- OpenAPI ContainerのDevelopment / CI用途を整理する
- compose.yamlをDevelopment向け構成として整理する
- .dockerignoreとDocker build contextを整理する
- Development環境とProduction Imageのbuild / runを検証する
- Docker構成に関するドキュメントを更新する
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
- Frontend Dockerfileをmulti-stage build化し、Development / Production Runtimeを分離した
- Next.js Production Imageをstandalone構成で実行できるようにした
- Backend DockerfileをPHP-FPMベースのmulti-stage buildへ変更した
- Nginx Containerを追加し、Nginx → FastCGI → PHP-FPM → Laravelの通信経路を構築した
- Backendからphp artisan serveを廃止した
- Docker ComposeをLocal Development向けに整理し、Frontend / Nginx / Backend / PostgreSQL / OpenAPIを起動できる構成にした
- BackendのPHP-FPM Port 9000はHostへ公開せず、Docker Network内で利用する構成にした
- OpenAPI ContainerをDevelopment / CI用ToolingとしてProduction Runtimeから分離した
- .dockerignoreとDocker build contextを整理した
- Frontend / BackendのProduction Imageをbuild・起動し、Production Runtimeでの疎通を確認した
- Development環境でNginx経由のLaravel APIおよびFrontend BFF経由のHealth Checkを確認した
- Frontendのformat / lint / typecheck / test / build、Backendのquality / test、OpenAPI checkが成功することを確認した
- Docker構成に関する開発環境ドキュメントを更新した
<!-- SECTION:FINAL_SUMMARY:END -->
