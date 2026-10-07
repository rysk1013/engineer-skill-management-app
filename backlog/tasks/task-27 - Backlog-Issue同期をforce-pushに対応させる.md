---
id: TASK-27
title: Backlog Issue同期をforce-pushに対応させる
status: In Progress
assignee: []
created_date: '2026-10-07 10:28'
updated_date: '2026-10-07 10:30'
labels: []
dependencies: []
references:
  - .github/workflows/sync-backlog-issues.yml
  - scripts/sync-backlog-issues.sh
ordinal: 27000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
GitHub ActionsのBacklog → GitHub Issues同期において、amend後のforce-pushなどでgithub.event.beforeが現在のGit履歴から到達不能になった場合でも同期処理が失敗しないようにする。

SYNC_MODE=changedでBEFORE_SHAがnon-zeroかつローカルRepository上に存在しない場合は、changed syncを継続せずfull syncへ安全にフォールバックする。

AFTER_SHAが無効な場合は実行対象Commit自体を確認できない異常状態として、従来どおりエラーとする。初回branch pushのzero SHAについては既存のmerge-base処理を維持する。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 通常pushではchanged syncが従来どおり利用される
- [ ] #2 初回branch pushでBEFORE_SHAがzero SHAの場合は既存のmerge-base処理が利用される
- [ ] #3 BEFORE_SHAがnon-zeroかつローカルRepositoryに存在しない場合はfull syncへフォールバックする
- [ ] #4 force-push時にBEFORE_SHAが取得できないことを理由として同期処理が異常終了しない
- [ ] #5 full syncへのフォールバック時に全Backlog Taskが同期対象として解決される
- [ ] #6 AFTER_SHAが無効な場合は従来どおりエラー終了する
- [ ] #7 fallback発生時に理由がLogから確認できる
- [ ] #8 既存のchanged / full sync動作を壊していない
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
1. 現在のBEFORE_SHA / AFTER_SHA検証とdiff base解決処理を確認する
2. force-push時にBEFORE_SHAが履歴から到達不能になるケースを整理する
3. non-zeroのBEFORE_SHAが存在しない場合にfull syncへフォールバックする処理を追加する
4. zero SHAの初回push処理とAFTER_SHAのvalidationは既存挙動を維持する
5. 通常push / initial push / force-push fallback / invalid AFTER_SHAのケースを確認する
6. 必要に応じてGitHub Actions運用ドキュメントを更新する
7. git diff --checkとSelf Reviewを実施する
<!-- SECTION:PLAN:END -->
