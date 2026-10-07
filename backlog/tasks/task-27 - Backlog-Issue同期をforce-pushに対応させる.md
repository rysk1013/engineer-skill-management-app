---
id: TASK-27
title: Backlog Issue同期をforce-pushに対応させる
status: Done
assignee: []
created_date: '2026-10-07 10:28'
updated_date: '2026-10-07 10:48'
labels: []
dependencies: []
references:
  - .github/workflows/sync-backlog-issues.yml
  - scripts/sync-backlog-issues.sh
priority: high
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
- [x] #1 通常pushではchanged syncが従来どおり利用される
- [x] #2 初回branch pushでBEFORE_SHAがzero SHAの場合は既存のmerge-base処理が利用される
- [x] #3 BEFORE_SHAがnon-zeroかつローカルRepositoryに存在しない場合はfull syncへフォールバックする
- [x] #4 force-push時にBEFORE_SHAが取得できないことを理由として同期処理が異常終了しない
- [x] #5 full syncへのフォールバック時に全Backlog Taskが同期対象として解決される
- [x] #6 AFTER_SHAが無効な場合は従来どおりエラー終了する
- [x] #7 fallback発生時に理由がLogから確認できる
- [x] #8 既存のchanged / full sync動作を壊していない
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
1. 現在のBEFORE_SHA / AFTER_SHA検証とdiff base解決処理を確認する
2. force-push時にBEFORE_SHAが履歴から到達不能になるケースを整理する
3. non-zeroのBEFORE_SHAが存在しない場合にfull syncへフォールバックする処理を追加する
4. zero SHAの初回push処理とAFTER_SHAのvalidationは既存挙動を維持する
5. 通常push / initial push / force-push fallback / invalid AFTER_SHAのケースを確認する
6. 必要に応じてGitHub Actions運用ドキュメントを更新する
7. git diff --checkとSelf Reviewを実施する
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Backlog → GitHub Issues同期処理をforce-pushに対応させた。

SYNC_MODE=changedでBEFORE_SHAがnon-zeroかつ現在のGit Repository上に存在しない場合、エラー終了せずSYNC_MODE=fullへフォールバックするように変更した。

通常pushではchanged syncを維持し、初回branch pushのzero SHAでは既存のorigin/devとのmerge-base処理を維持した。AFTER_SHAが無効な場合は従来どおりエラー終了する。

通常push、initial push、force-push相当のmissing BEFORE_SHA、invalid AFTER_SHA、明示的full syncを確認し、既存のchanged / full sync動作を維持できていることを確認した。bash -nおよびgit diff --checkも成功した。
<!-- SECTION:FINAL_SUMMARY:END -->
