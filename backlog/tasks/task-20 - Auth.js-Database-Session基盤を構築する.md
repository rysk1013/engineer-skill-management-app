---
id: TASK-20
title: Auth.js Database Session基盤を構築する
status: To Do
assignee: []
created_date: '2026-10-06 12:17'
updated_date: '2026-10-06 12:18'
labels:
  - phase-2
  - frontend
  - authentication
  - authjs
milestone: m-2
dependencies: []
references:
  - docs/03_システム設計/02_認証・認可/02_Next.js-Auth.js設計.md
  - docs/03_システム設計/01_データベース/09_Auth.js-Sessionテーブル設計.md
  - docs/03_システム設計/01_データベース/10_Sanctum-Token保存方式.md
priority: high
type: feature
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Auth.jsのDatabase Session Strategyを利用し、PostgreSQL上のauth_sessionsをSession StoreとしてBrowserとNext.js間のSession管理基盤を構築する。Sanctum Tokenの暗号化・復号およびBackendとのLifecycle連携は後続Taskで実装する。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Auth.jsが導入・設定されている
- [ ] #2 Database Session Strategyが設定されている
- [ ] #3 PostgreSQLをSession Storeとして利用できる
- [ ] #4 auth_sessionsテーブルが現行設計に従って作成されている
- [ ] #5 usersとauth_sessionsの1:N Relationが成立している
- [ ] #6 session_tokenがUNIQUEとして管理されている
- [ ] #7 Session有効期限をexpires_atで管理できる
- [ ] #8 Session CookieがHttpOnly等の既存セキュリティ方針に従っている
- [ ] #9 Next.js Server側から認証Sessionを取得できる
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
