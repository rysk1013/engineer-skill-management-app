---
id: TASK-21
title: Laravel Sanctum認証APIを構築する
status: To Do
assignee: []
created_date: '2026-10-06 12:18'
labels:
  - phase-2
  - backend
  - authentication
  - sanctum
milestone: m-2
dependencies: []
references:
  - docs/03_システム設計/02_認証・認可/01_認証全体設計.md
  - docs/03_システム設計/02_認証・認可/03_Laravel-Sanctum設計.md
  - docs/03_システム設計/01_データベース/10_Sanctum-Token保存方式.md
priority: high
type: feature
ordinal: 21000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Laravel Sanctum Personal Access Tokenを利用したBackend API認証基盤を構築する。ログイン時のCredential検証とToken発行、保護APIでのToken検証、ログアウト時のToken失効までをLaravel側の責務として実装する。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Laravel Sanctumが導入・設定されている
- [ ] #2 personal_access_tokensテーブルが利用可能である
- [ ] #3 ログインAPIでCredentialを検証できる
- [ ] #4 ログイン成功時にSanctum Personal Access Tokenを発行できる
- [ ] #5 発行したTokenが対象Userと適切に紐付いている
- [ ] #6 Bearer Tokenを利用して保護対象APIの利用者を識別できる
- [ ] #7 保護対象APIにSanctum認証Middlewareが適用されている
- [ ] #8 ログアウトAPIで現在のSanctum Tokenを失効できる
- [ ] #9 未認証アクセスを401として適切に処理できる
- [ ] #10 Sanctum認証APIの必要なTestが成功する
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
