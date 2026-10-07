---
id: TASK-23
title: ログイン・ログアウトUIを実装する
status: To Do
assignee: []
created_date: '2026-10-06 12:21'
updated_date: '2026-10-07 04:16'
labels:
  - phase-2
  - frontend
  - authentication
  - ui
milestone: m-2
dependencies:
  - TASK-22
references:
  - docs/03_システム設計/02_認証・認可/01_認証全体設計.md
  - docs/03_システム設計/02_認証・認可/02_Next.js-Better-Auth設計.md
  - docs/08_UI設計/07_画面設計/18_ログイン.md
priority: high
type: feature
ordinal: 23000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Phase 1のUI設計に従い、Better Auth SessionとBFF認証連携を利用したログイン・ログアウトUIを実装する。認証状態に応じた画面遷移を含め、BrowserへBackend Credentialを露出しない構成とする。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ログイン画面がPhase 1のUI設計に従って実装されている
- [ ] #2 ログインフォームからBFFの認証処理を呼び出せる
- [ ] #3 認証成功後にログイン済み画面へ遷移できる
- [ ] #4 認証失敗時に適切なエラー状態を表示できる
- [ ] #5 ログアウト操作からBFFのログアウト処理を実行できる
- [ ] #6 ログアウト後に未認証状態へ遷移できる
- [ ] #7 未認証利用者が保護対象画面へアクセスした場合に適切に処理できる
- [ ] #8 Client ComponentへSanctum Token等のBackend Credentialが渡されない
- [ ] #9 Loading / Error等の認証UI状態が既存UI設計に従っている
- [ ] #10 ログイン・ログアウトUIの必要なFrontend Testが成功する
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
