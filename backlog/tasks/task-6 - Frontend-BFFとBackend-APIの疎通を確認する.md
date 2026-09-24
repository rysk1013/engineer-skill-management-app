---
id: TASK-6
title: Frontend/BFFとBackend APIの疎通を確認する
status: In Progress
assignee: []
created_date: '2026-09-24 17:28'
updated_date: '2026-09-24 17:33'
labels:
  - phase-0
  - frontend
  - backend
milestone: Phase 0 - 開発基盤
dependencies:
  - TASK-3
  - TASK-5
references:
  - docs/03_システム設計/03_API/README.md
  - docs/03_システム設計/03_API/03_API共通仕様.md
  - docs/04_技術選定/04_API・OpenAPI.md
  - docs/06_開発・運用/01_開発環境.md
  - openapi/openapi.yaml
  - compose.yaml
priority: high
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Next.js Frontend/BFFからLaravel Backend APIへHTTP Requestを送信し、Docker開発環境上でアプリケーション間通信が正常に行えることを確認する。

TASK-5で定義したOpenAPIの `/health` Endpointを利用して、Frontend/BFF → Laravel Backend APIの基本的な通信経路を構築する。

このTaskでは業務APIやSanctumによる認証連携は実装せず、Frontend/BFFとBackend API間の疎通確認に範囲を限定する。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Laravel Backend APIに `GET /health` が実装されている
- [ ] #2 `GET /health` がOpenAPI仕様に準拠したResponseを返す
- [ ] #3 Next.js BFFからLaravel Backend APIの `/health` を呼び出せる
- [ ] #4 BFFからBackend APIを呼び出す際にOpenAPIから生成した型を利用している
- [ ] #5 BrowserからBackend APIを直接呼び出さず、BFF経由で疎通確認できる
- [ ] #6 Docker開発環境上でFrontend/BFF → Backend APIの通信が成功する
- [ ] #7 Backend APIの接続先を環境変数で設定できる
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
- [ ] #9 Docker開発環境でFrontend/BFF → Backend APIの疎通確認が完了している
- [ ] #10 OpenAPI仕様と実装のResponseに差異がない
- [ ] #11 必要な設定ファイルがGit管理されている
- [ ] #12 必要な開発ドキュメントが更新されている
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. 現在のFrontend / Backend構成を確認する
2. Laravel Backend APIにGET /healthを実装する
3. Backend単体でGET /healthのResponseを確認する
4. Backend API接続先の環境変数をFrontend/BFFに設定する
5. OpenAPI生成型を利用するBackend API Clientを最小構成で実装する
6. Next.js BFFに疎通確認用Endpointを実装する
7. Browser → BFF → Backend APIの疎通を確認する
8. Docker開発環境で一連の通信を確認する
9. OpenAPI仕様と実装の整合性を確認する
10. 必要なドキュメントを更新する
<!-- SECTION:PLAN:END -->
