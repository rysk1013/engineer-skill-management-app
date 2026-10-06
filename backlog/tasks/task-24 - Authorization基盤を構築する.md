---
id: TASK-24
title: Authorization基盤を構築する
status: To Do
assignee: []
created_date: '2026-10-06 12:21'
updated_date: '2026-10-06 12:22'
labels:
  - phase-2
  - backend
  - frontend
  - authorization
milestone: m-2
dependencies:
  - TASK-20
  - TASK-21
references:
  - docs/03_システム設計/02_認証・認可/01_認証全体設計.md
  - docs/03_システム設計/02_認証・認可/03_Laravel-Sanctum設計.md
  - docs/02_アーキテクチャ/01_Backend/DDD設計/10_Access-Control設計.md
  - docs/08_UI設計/07_画面設計/16_Access-Denied.md
priority: high
type: feature
ordinal: 24000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
後続の業務APIで共通利用するAuthorization基盤を構築する。Laravelを最終的な認可判断の主体とし、Roleの基礎、Policy / Gate等の認可基盤、403処理、およびNext.js側の表示制御基盤を整備する。Role変更・担当社員割当等のAccess Control業務機能は対象外とする。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 UserのRoleを利用して認可判定できる基礎が整備されている
- [ ] #2 Laravel Policy / Gate等を利用したAuthorization基盤が構築されている
- [ ] #3 保護対象APIで認証後に必要な認可判定を実行できる
- [ ] #4 権限不足アクセスを403として適切に処理できる
- [ ] #5 Next.js側でSession情報を利用した表示制御の基盤が構築されている
- [ ] #6 Frontend側の表示制御だけを最終的な認可手段としていない
- [ ] #7 Access Denied UIへ適切に遷移または表示できる
- [ ] #8 Role変更・担当社員割当等のAccess Control業務管理機能が本Taskへ含まれていない
- [ ] #9 Authorization基盤の必要なBackend Testが成功する
- [ ] #10 Authorizationに関する必要なFrontend Testが成功する
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
