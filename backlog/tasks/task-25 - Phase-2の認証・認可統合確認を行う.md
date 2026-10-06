---
id: TASK-25
title: Phase 2の認証・認可統合確認を行う
status: To Do
assignee: []
created_date: '2026-10-06 12:23'
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
  - docs/05_MVP実装計画/02_実装フェーズ.md
  - docs/03_システム設計/02_認証・認可/01_認証全体設計.md
  - docs/03_システム設計/02_認証・認可/02_Next.js-Auth.js設計.md
  - docs/03_システム設計/02_認証・認可/03_Laravel-Sanctum設計.md
priority: high
type: task
ordinal: 25000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Phase 2で構築したAuth.js Session、Laravel Sanctum、BFF認証連携、認証UI、Authorization基盤を統合し、BrowserからLaravel Backend APIまでの認証・認可フローがEnd-to-Endで成立していることを確認する。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ログインからAuth.js Session作成までのフローが正常に動作する
- [ ] #2 認証済みSessionからBFF経由でLaravel Backend APIへアクセスできる
- [ ] #3 Sanctum Bearer TokenによってLaravel側で利用者を識別できる
- [ ] #4 保護対象APIへの未認証アクセスが401として適切に処理される
- [ ] #5 権限不足アクセスが403として適切に処理される
- [ ] #6 ログアウト時にSanctum TokenとAuth.js Sessionの両方が失効する
- [ ] #7 Sanctum TokenがBrowser・Client Component・API Responseへ露出していない
- [ ] #8 ログイン・ログアウト・未認証・権限不足の主要User FlowがEnd-to-Endで動作する
- [ ] #9 Frontend / Backend / Integrationの必要なTestが成功する
- [ ] #10 Phase 2の完了条件を満たしていることが確認されている
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
