---
id: TASK-22
title: BFF認証連携とBackend Credential管理を実装する
status: To Do
assignee: []
created_date: '2026-10-06 12:19'
updated_date: '2026-10-07 04:15'
labels:
  - phase-2
  - frontend
  - bff
  - authentication
milestone: m-2
dependencies:
  - TASK-20
  - TASK-21
references:
  - docs/03_システム設計/02_認証・認可/01_認証全体設計.md
  - docs/03_システム設計/02_認証・認可/02_Next.js-Better-Auth設計.md
  - docs/04_技術選定/03_認証方式.md
  - docs/04_技術選定/02_データベース.md
priority: high
type: feature
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Next.js BFFとLaravel Backend APIの認証連携を実装する。Laravelから取得したSanctum TokenをBackend CredentialとしてRedisへ保存し、Better Auth Session単位で1:1に関連付ける。Better Auth Session用Namespaceとは分離し、Backend Credential用NamespaceとACLを利用して安全に管理する。ログアウト時にはSanctum Token失効、Backend Credential削除、Better Auth Session失効を連携させる。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ログイン成功時にLaravelから取得したSanctum TokenをNext.js Server側でBackend Credentialとして扱える
- [ ] #2 Backend CredentialをRedisの専用Key Namespaceへ保存できる
- [ ] #3 Backend CredentialがBetter Auth Session単位で1:1に関連付けられている
- [ ] #4 Better Auth Session用NamespaceとBackend Credential用Namespaceが分離されている
- [ ] #5 Redis ACLによりBackend Credentialへのアクセス責務が適切に制限されている
- [ ] #6 Backend API ClientがSessionに対応するBackend Credentialを取得してBearer Tokenとして付与できる
- [ ] #7 Backend CredentialがBrowser・Client Component・API Response・Application Logへ露出しない
- [ ] #8 Backendから401が返された場合に認証状態を利用不能として適切に処理できる
- [ ] #9 ログアウト時にLaravel側のSanctum Token失効、Backend Credential削除、Better Auth Session失効を連携できる
- [ ] #10 BFF認証連携とBackend Credential管理の必要なTestが成功する
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
