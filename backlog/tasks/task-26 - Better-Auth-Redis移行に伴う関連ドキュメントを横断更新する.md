---
id: TASK-26
title: Better Auth / Redis移行に伴う関連ドキュメントを横断更新する
status: Done
assignee: []
created_date: '2026-10-07 08:17'
updated_date: '2026-10-07 10:02'
labels:
  - phase-2
  - documentation
  - authentication
  - better-auth
  - redis
milestone: m-2
dependencies: []
references:
  - docs/02_アーキテクチャ
  - docs/03_システム設計/02_認証・認可/01_認証全体設計.md
  - docs/03_システム設計/02_認証・認可/02_Next.js-Better-Auth設計.md
  - docs/04_技術選定/03_認証方式.md
  - docs/05_MVP実装計画
  - docs/06_開発・運用
  - docs/07_非機能要件
  - docs/08_UI設計
priority: high
type: docs
ordinal: 26000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Better Auth / Redisへの認証基盤変更に伴い、既存ドキュメント・Backlog内に残る旧Auth.js / PostgreSQL Database Session前提を横断的に確認し、現行の認証・Session・Credential管理方針へ更新する。

対象にはArchitecture、System Design、技術選定、MVP実装計画、開発・運用、非機能要件、UI設計、Project README、Backlog References等を含む。

Archive・不採用案・変更履歴など、意図的に残す旧Auth.js記述は修正対象から除外し、現行仕様と矛盾する記述のみ更新する。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 現行ドキュメントに残る旧Auth.js / PostgreSQL Database Session前提を横断検索し、修正対象を特定できている
- [x] #2 現行仕様と矛盾するAuth.js / PostgreSQL Session関連記述がBetter Auth / Redis / Laravel Sanctum構成へ更新されている
- [x] #3 Application User AuthenticationはLaravel、Browser Session ManagementはBetter Auth、Session StoreはRedisとして一貫して記述されている
- [x] #4 Backend CredentialはBetter Auth Sessionと分離し、Redisへ暗号化保存する方針が関連ドキュメントで一貫している
- [x] #5 Next.jsからPostgreSQLへ直接接続しない方針が関連ドキュメントで一貫している
- [x] #6 旧ドキュメントパスやBacklog Referencesが現行ドキュメントへ更新されている
- [x] #7 Archive・不採用案・過去の変更履歴として意図的に残すAuth.js記述と修正漏れを区別できている
- [x] #8 最終横断検索で現行仕様と矛盾する旧Auth.js / PostgreSQL Session記述が残っていない
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Acceptance Criteria are satisfied
- [x] #2 Required tests pass
- [x] #3 Required lint and static analysis pass
- [x] #4 Documentation is updated if needed
- [x] #5 No temporary or debug code remains
- [x] #6 Self review is completed
- [x] #7 Final Summary is completed
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. 旧Auth.js / PostgreSQL Database Session前提の記述を現行ドキュメント・Backlogから横断検索する
2. Archive・不採用案・変更履歴として意図的に残す記述と修正漏れを切り分ける
3. Architecture / System Designの現行認証構成との整合性を確認する
4. 技術選定・MVP実装計画の旧認証前提を更新する
5. 開発・運用・非機能要件のBetter Auth / Redis対応を確認・更新する
6. UI設計のAuth.js前提を現行認証責務へ更新する
7. Project READMEおよびBacklog Referencesの旧パス・旧技術名を更新する
8. Application User Authentication / Browser Session / Backend Credential / PostgreSQL Accessの責務が全ドキュメントで一貫していることを確認する
9. 最終横断検索を実施し、残存記述を意図的なものと修正漏れに分類する
10. git diff --checkとSelf Reviewを実施する
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Better Auth / Redisへの認証基盤変更に伴い、Architecture、System Design、技術選定、MVP実装計画、開発・運用、非機能要件、UI設計、Project README、Backlog Referencesを横断確認・更新した。

旧Auth.js / PostgreSQL Database Session前提の現行仕様上の矛盾を解消し、Application User AuthenticationはLaravel、Browser Session ManagementはBetter Auth、Session StoreはRedis、Backend CredentialはBetter Auth Sessionと分離してRedisへ暗号化保存する責務へ統一した。

Next.jsからPostgreSQLへ直接接続しない方針、Session / Backend CredentialのNamespace・ACL分離、旧ドキュメントパスおよびBacklog Referencesも確認・更新した。

最終横断検索では、残存するAuth.js / PostgreSQL Session記述が不採用案・変更履歴・過去Taskの記録・PostgreSQL接続Session等の意図的な記述であることを確認した。
<!-- SECTION:FINAL_SUMMARY:END -->
