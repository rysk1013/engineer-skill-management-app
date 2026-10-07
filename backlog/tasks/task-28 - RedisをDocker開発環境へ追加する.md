---
id: TASK-28
title: RedisをDocker開発環境へ追加する
status: In Progress
assignee: []
created_date: '2026-10-07 10:57'
updated_date: '2026-10-07 11:06'
labels: []
dependencies: []
references:
  - compose.yaml
  - compose.production.yaml
  - .env.example
  - scripts/
  - docs/06_開発・運用/01_開発環境.md
priority: high
ordinal: 28000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
MVPで採用するRedisをDocker開発環境へ追加する。
Better Auth Session StoreおよびBackend Credential Storeで利用する基盤として、既存のDevelopment / Production構成と整合するRedisコンテナ、接続設定、動作確認手順を整備する。
Redis上の具体的なSession / Credential実装は後続Taskで扱い、本TaskではDocker・環境変数・接続基盤の整備を対象とする。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Docker開発環境でRedisコンテナを起動できる
- [ ] #2 既存のdev起動・停止スクリプトからRedisを含む環境を操作できる
- [ ] #3 FrontendおよびBackendから利用するRedis接続情報を環境変数として定義できる
- [ ] #4 Redisコンテナにhealthcheckが設定され、正常状態を確認できる
- [ ] #5 Development環境でRedisへの疎通を確認できる
- [ ] #6 Production用Docker構成にもRedisが反映されている
- [ ] #7 既存のDocker構成および命名規則と整合している
- [ ] #8 Redis利用方法に関する必要な開発環境ドキュメントが更新されている
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
1. 現行のDocker / env / script構成を確認する
2. Redisイメージ・永続化・healthcheck方針を決定する
3. Development用ComposeへRedisを追加する
4. Production用ComposeへRedisを追加する
5. Redis接続用環境変数を整理する
6. 開発・運用スクリプトとの整合性を確認する
7. Redis疎通確認を行う
8. 必要なドキュメントを更新する
9. テスト・品質確認を行う
<!-- SECTION:PLAN:END -->
