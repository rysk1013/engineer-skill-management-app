---
id: TASK-1
title: Next.jsを初期構築する
status: Done
assignee: []
created_date: '2026-09-20 08:28'
updated_date: '2026-09-22 15:52'
labels:
  - phase-0
  - frontend
  - infrastructure
milestone: m-0
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
frontend/ にNext.jsアプリケーションを初期構築し、Frontend / BFF開発を開始できる状態にする。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 frontend/ にNext.jsアプリケーションが構築されている
- [x] #2 App Routerを使用している
- [x] #3 TypeScriptを使用している
- [x] #4 ローカル環境でNext.jsを起動できる
- [x] #5 Browserから初期ページへアクセスできる
- [x] #6 Production Buildが成功する
- [x] #7 生成物や依存パッケージが適切にGit管理対象外になっている
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Acceptance Criteria are satisfied
- [ ] #2 Required tests pass
- [x] #3 Required lint and static analysis pass
- [x] #4 Documentation is updated if needed
- [x] #5 No temporary or debug code remains
- [x] #6 Self review is completed
- [x] #7 Final Summary is completed
<!-- DOD:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
## 実施内容

- `frontend/` にNext.jsアプリケーションを構築
- App Router / TypeScript / Tailwind CSS / ESLintを使用
- Next.jsのローカル起動とBrowserからの初期ページ表示を確認
- `npm run build` の成功を確認
- `npm run lint` の成功を確認
- `.next/`、`node_modules/` などの生成物・依存パッケージがGit管理対象外であることを確認

## Test

- Test環境は未導入のため、TASK-1では実行対象なし
- Test環境の構築は後続Taskで対応する

## Self Review

- Staged filesを確認し、TASK-1のスコープ外の変更がないことを確認
- 一時ファイル、デバッグコード、秘密情報が含まれていないことを確認
<!-- SECTION:FINAL_SUMMARY:END -->
