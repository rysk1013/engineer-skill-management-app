---
id: TASK-22
title: BFF認証連携とBackend Credential管理を実装する
status: To Do
assignee: []
created_date: '2026-10-06 12:19'
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
  - docs/03_システム設計/02_認証・認可/02_Next.js-Auth.js設計.md
  - docs/03_システム設計/01_データベース/09_Auth.js-Sessionテーブル設計.md
  - docs/03_システム設計/01_データベース/10_Sanctum-Token保存方式.md
priority: high
type: feature
ordinal: 22000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Next.js BFFとLaravel Backend APIの認証連携を実装する。Sanctum Tokenをauth_sessionsへ暗号化して保持し、Sessionから取得・復号してBackend APIへBearer Tokenとして付与する。ログアウト時にはSanctum Token失効とAuth.js Session削除を連携させる。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ログイン成功時にLaravelから取得したSanctum TokenをNext.js Server側で扱える
- [ ] #2 Sanctum TokenをApplication Level Encryptionにより暗号化してauth_sessions.sanctum_tokenへ保存できる
- [ ] #3 SessionからSanctum Tokenを取得して復号できる
- [ ] #4 Backend API Clientが認証済みリクエストへBearer Tokenを付与できる
- [ ] #5 Sanctum TokenがBrowser・Client Component・API Responseへ露出しない
- [ ] #6 Backendから401が返された場合に認証エラーとして適切に処理できる
- [ ] #7 ログアウト時にLaravel側のSanctum Tokenを失効できる
- [ ] #8 Sanctum Token失効後に対応するAuth.js Sessionを削除できる
- [ ] #9 Auth.js SessionとSanctum Tokenが1:1のLifecycleとして管理されている
- [ ] #10 BFF認証連携の必要なTestが成功する
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
