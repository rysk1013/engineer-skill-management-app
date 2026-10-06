---
id: TASK-3
title: Docker開発環境を構築する
status: Done
assignee: []
created_date: '2026-09-20 08:28'
updated_date: '2026-10-06 11:25'
labels:
  - phase-0
  - docker
  - infrastructure
milestone: Phase 0 - 開発基盤
dependencies:
  - TASK-1
  - TASK-2
priority: high
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Next.js、Laravel、PostgreSQLを利用するローカルDocker開発環境を構築する。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Frontend用のDocker環境が定義されている
- [x] #2 Backend用のDocker環境が定義されている
- [x] #3 PostgreSQL用のDocker環境が定義されている
- [x] #4 Docker Composeで必要なサービスを起動できる
- [x] #5 Docker環境でNext.jsを起動できる
- [x] #6 Docker環境でLaravelを起動できる
- [x] #7 PostgreSQLコンテナが正常に起動する
- [x] #8 開発に必要なVolume / Networkが適切に構成されている
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

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## 実施内容

- Next.js用Docker開発環境を構築
- Laravel用Docker開発環境を構築
- PostgreSQL 17用Docker環境を構築
- Docker Composeで3サービスを一括起動可能にした
- `frontend` / `backend` の2つのDocker Networkで通信経路を分離
- FrontendからPostgreSQLへ直接通信できない構成にした
- PostgreSQLのHost向けPort公開を行わない構成にした
- `node_modules` / `vendor` / PostgreSQL DataをNamed Volumeで管理
- PostgreSQL HealthcheckとBackendの起動依存を設定
- LaravelからPostgreSQLへの接続を確認
- Docker開発環境ドキュメントを実装内容に合わせて更新

## Test

- `docker compose exec backend php artisan test`: PASS
- `docker compose exec frontend npm run build`: PASS

## Code Quality

- `docker compose exec backend ./vendor/bin/pint --test`: PASS
- `docker compose exec frontend npm run lint`: PASS
- 本格的なStatic Analysisは後続Taskで導入・設定予定

## Docker Verification

- Next.js: `localhost:3000` OK
- Laravel: `localhost:8000` OK
- PostgreSQL: Healthcheck OK
- Laravel → PostgreSQL: `php artisan db:show` OK
- frontend → backend: 接続可能
- backend → db: 接続可能
- frontend → db: 直接接続不可

## Self Review

- TASK-3のAcceptance Criteriaをすべて確認
- TASK-3のスコープ外の変更がないことを確認
- 一時ファイル・デバッグコードが残っていないことを確認
- 実装と開発環境ドキュメントの整合性を確認
<!-- SECTION:FINAL_SUMMARY:END -->
