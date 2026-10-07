---
id: TASK-20
title: Better Auth / Redis Session基盤を構築する
status: To Do
assignee: []
created_date: '2026-10-06 12:17'
updated_date: '2026-10-07 08:34'
labels:
  - phase-2
  - frontend
  - authentication
  - better-auth
  - redis
milestone: m-2
dependencies:
  - TASK-26
references:
  - docs/04_技術選定/01_アプリケーション構成.md
  - docs/04_技術選定/02_データベース.md
  - docs/04_技術選定/03_認証方式.md
  - docs/03_システム設計/02_認証・認可/01_認証全体設計.md
  - docs/03_システム設計/02_認証・認可/02_Next.js-Better-Auth設計.md
  - docs/03_システム設計/02_認証・認可/03_Laravel-Sanctum設計.md
priority: high
type: feature
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Better Authを利用してBrowserとNext.js間のSession管理基盤を構築する。Session StoreにはRedisを利用し、Next.jsからPostgreSQLへ直接アクセスしない。Better Auth SessionとBackend Credentialは同一Redis上でKey NamespaceとACLを分離して管理し、Backend CredentialのLaravel Sanctum連携は後続Taskで実装する。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Better AuthがFrontendへ導入・設定されている
- [ ] #2 RedisをBetter AuthのSession Storeとして利用できる
- [ ] #3 Better Auth SessionがPostgreSQLへ保存されない構成になっている
- [ ] #4 Next.jsからPostgreSQLへ直接アクセスしない構成になっている
- [ ] #5 Session CookieがHttpOnly等の既存セキュリティ方針に従っている
- [ ] #6 Sessionの作成・取得・更新・失効をNext.js Server側で扱える
- [ ] #7 Better Auth Session用Redis Key NamespaceがBackend Credentialと分離されている
- [ ] #8 Redis ACLによりSessionとBackend Credentialのアクセス責務を分離できる構成になっている
- [ ] #9 Backend CredentialがBrowserやClient Componentへ露出しない基盤になっている
- [ ] #10 Session関連の必要なTestが成功する
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
1. TASK-26で整理したBetter Auth / Redisの現行技術選定と認証設計を確認する
2. Better AuthをFrontendへ導入する
3. Redis接続基盤をFrontend Server側へ追加する
4. Better AuthのSession StoreをRedisとして構成する
5. Better Auth Session用Key Namespaceを定義する
6. Backend Credential用NamespaceとのACL境界を定義する
7. Session Cookieを既存セキュリティ方針に合わせて設定する
8. Next.js Server側からSessionを取得・失効できる構成を追加する
9. Session作成・取得・期限・失効・非露出に関するTestを追加する
10. lint / typecheck / test / buildを実行する
11. TASK-26で更新した関連ドキュメントとの整合性を最終確認する
<!-- SECTION:PLAN:END -->
