# UI設計

## 1. 概要

本ディレクトリでは、Engineer Skill Management App のMVPにおけるUI設計を管理する。

Phase 1「UI設計」では、Frontend実装を開始する前に、画面構成・画面遷移・共通レイアウト・Design System・共通UIコンポーネント・各画面UI・UI状態・Responsive対応を整理する。

UI設計では既存の要件定義・アーキテクチャ・システム設計・技術選定・MVP実装計画・非機能要件を前提とし、UI設計のみで正式仕様を変更しない。

---

## 2. 目的

Phase 1完了時に、Frontend実装担当がUIについて大きな追加判断を行わなくても、各画面の実装へ着手できる状態を目指す。

具体的には、以下を明確にする。

- MVPに必要な画面
- Route
- 画面間の遷移
- Navigation構造
- App Shell
- 共通レイアウト
- Design System
- 共通UIコンポーネント
- 各画面の表示内容
- 各画面で可能な操作
- 権限による表示・操作差
- Loading / Empty / Error等のUI状態
- Desktop / Tablet / Mobileでの表示方針

---

## 3. ドキュメント構成

UI設計は以下の構成で管理する。

```text
08_UI設計/
├── README.md
├── 01_UI設計方針.md
├── 02_画面一覧.md
├── 03_画面遷移.md
├── 04_共通レイアウト.md
├── 05_デザインシステム.md
├── 06_共通コンポーネント.md
├── 07_画面設計/
├── 08_UI状態設計.md
└── 09_レスポンシブ設計.md
```

必要なドキュメントはPhase 1の進行に合わせて順次追加する。

空の設計ドキュメントを先に大量作成することはしない。

---

## 4. 各ドキュメントの責務

### 4.1 `01_UI設計方針.md`

Phase 1全体で共通して使用するUI設計方針を定義する。

主な対象:

- UI設計の対象範囲
- UI設計とFrontend実装の責務境界
- Desktop / Tablet / Mobile方針
- App Shell方針
- Design System方針
- 共通UIコンポーネント方針
- UI状態設計方針
- Accessibility方針
- 各画面設計の記述フォーマット

---

### 4.2 `02_画面一覧.md`

MVPで必要となる画面を一覧化する。

主な対象:

- 画面ID
- 画面名
- 目的
- Route
- 対象Role / Permission
- 関連機能

---

### 4.3 `03_画面遷移.md`

画面間のNavigationと遷移関係を定義する。

主な対象:

- 画面遷移
- Navigation構造
- Route構成
- Entry Point
- 戻る操作
- 権限による遷移制御

---

### 4.4 `04_共通レイアウト.md`

アプリケーション全体で使用する共通レイアウトを定義する。

主な対象:

- App Shell
- Header
- Sidebar
- Main Content
- Breadcrumb
- Page Header
- User Menu

---

### 4.5 `05_デザインシステム.md`

UI全体で共通して利用する視覚・表現上のルールを定義する。

Frontend技術選定で採用済みの Tailwind CSS v4 + CSS Variables を前提として、
Application全体で利用するDesign TokenおよびSemanticなUI表現を整理する。

主な対象:

- Color
- Typography
- Spacing
- Border
- Radius
- Shadow
- Breakpoint
- Icon
- Semantic State
- Design Token

---

### 4.6 `06_共通コンポーネント.md`

複数画面で共通して使用するUI ComponentおよびUIパターンを定義する。

UI Componentはshadcn/uiを基本とし、必要なComponentのみを採用する。

また、shadcn/ui Componentとは別にApplication固有の共通責務が必要な場合は、
Application共通Componentとして設計する。

主な対象:

- Button
- Input
- Select
- Checkbox
- Table
- Badge
- Pagination
- Dialog
- Alert
- Notification
- Empty State
- Error State
- Page Header
- Search / Filter
- Application共通Component

Componentごとに独自実装するのではなく、まずshadcn/uiで要件を満たせるか確認する。

---

### 4.7 `07_画面設計/`

個別画面の詳細UI設計を管理する。

各画面では原則として以下を定義する。

- 目的
- 対象ユーザー・権限
- Route
- 画面構成
- 表示項目
- 操作
- 画面遷移
- UI状態
- Responsive
- 備考

---

### 4.8 `08_UI状態設計.md`

アプリケーション全体で共通するUI状態を定義する。

主な対象:

- Loading
- Empty
- Error
- Validation Error
- Disabled
- Confirmation
- Success Feedback

---

### 4.9 `09_レスポンシブ設計.md`

画面幅に応じたUIの基本挙動を定義する。

主な対象:

- Desktop
- Tablet
- Mobile
- Navigation切り替え
- Table表示
- Form Layout
- Action配置

---

## 5. 設計の進行順

Phase 1では、以下の順序を基本とする。

```text
UI設計方針
    ↓
画面一覧
    ↓
画面遷移 / Route
    ↓
共通レイアウト
    ↓
Design System / 共通UI
    ↓
各画面設計
    ↓
UI状態 / Responsive確認
    ↓
Phase 1 統合確認
```

後続工程で共通設計の不足が判明した場合は、個別画面だけで独自対応せず、必要に応じて上位の共通設計へ反映する。

---

## 6. 正式仕様との関係

UI設計では以下の既存ドキュメントを正とする。

- `docs/01_要件定義`
- `docs/02_アーキテクチャ`
- `docs/03_システム設計`
- `docs/04_技術選定`
- `docs/05_MVP実装計画`
- `docs/06_開発・運用`
- `docs/07_非機能要件`

既存仕様とUI設計の間に矛盾が生じた場合は、UI設計のみで解釈を固定せず、正となる仕様を確認する。

正式仕様の変更が必要な場合は、変更理由と影響範囲を明確にした上で、該当する既存ドキュメントを更新する。

UI・Stylingに関する技術選定については、
`docs/04_技術選定/Frontend/03_UI・Styling.md` を正とする。

Phase 1のUI設計では、以下の採用済み技術を前提とする。

- Tailwind CSS v4
- shadcn/ui
- Base UI
- Lucide / lucide-react
- cn
- Tailwind CSS v4 + CSS VariablesによるDesign Token

---

## 7. Archiveの扱い

`archive` / `90_archive` / `99_archive` 配下のドキュメントは過去版として扱う。

現在のUI設計判断では、原則として現行ドキュメントを根拠とする。

---

## 8. 実装との関係

Phase 1はUI設計を対象とし、Frontendの具体的な実装は後続Phaseで行う。

以下は原則としてPhase 1の対象外とする。

- React Component実装
- Server Component / Client Componentの具体的な分割
- API接続
- BFF実装
- Auth.jsとの接続処理
- Form処理実装
- Frontendテスト実装

ただし、実装可能性を確認するために必要な範囲で技術的制約を考慮する。
