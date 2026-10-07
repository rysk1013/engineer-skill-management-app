---
id: TASK-25
title: Phase 2の認証・認可統合確認を行う
status: To Do
assignee: []
created_date: '2026-10-06 12:23'
updated_date: '2026-10-07 04:17'
labels:
  - phase-2
  - authentication
  - authorization
  - integration
milestone: m-2
dependencies:
  - TASK-23
  - TASK-24
references:
  - docs/03_システム設計/02_認証・認可/01_認証全体設計.md
  - docs/03_システム設計/02_認証・認可/02_Next.js-Better-Auth設計.md
  - docs/03_システム設計/02_認証・認可/03_Laravel-Sanctum設計.md
  - docs/04_技術選定/03_認証方式.md
priority: high
type: task
ordinal: 25000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Phase 2で構築したBetter Auth Session、Redis上のBackend Credential管理、Laravel Sanctum、BFF認証連携、認証UI、Authorization基盤を統合し、BrowserからLaravel Backend APIまでの認証・認可フローがEnd-to-Endで成立していることを確認する。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ログインからBetter Auth Session作成までのフローが正常に動作する
- [ ] #2 Better Auth Sessionに対応するBackend CredentialをRedisから取得してLaravel Backend APIへBearer Tokenとして付与できる
- [ ] #3 認証済み利用者が保護対象APIへ正常にアクセスできる
- [ ] #4 未認証利用者が保護対象画面・APIへアクセスした場合に適切に拒否される
- [ ] #5 権限不足の利用者に対してLaravel Backend API側で適切にAuthorization Errorを返せる
- [ ] #6 ログアウト時にSanctum Token、Backend Credential、Better Auth Sessionが適切に失効する
- [ ] #7 Better Auth SessionとBackend CredentialのKey NamespaceおよびACL境界が維持されている
- [ ] #8 Backend CredentialがBrowser・Client Component・API Response・Application Logへ露出しない
- [ ] #9 SessionまたはBackend Credentialが失効・不整合状態の場合に安全側へ処理される
- [ ] #10 Phase 2の認証・認可に必要なFrontend / Backend / Integration Testが成功する
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
