# Table・一覧UI

## 1. 目的

本ドキュメントでは、FrontendにおけるTable・一覧UIの技術選定および実装方針を定義する。

対象：

- Table Library
- Table UI Component
- Pagination
- Sort
- Filter
- Search
- URL State
- Column定義
- Row Action
- Selection
- Loading / Empty / Error State
- Responsive Design
- Accessibility

主な対象画面：

- Employee一覧
- Employee Skill一覧
- Skill一覧
- Skill Category一覧
- Department一覧
- User一覧
- 各種管理画面

一覧画面のArchitectureについてはFrontend Architecture、
Server Stateについては `07_状態管理.md`、
UI Componentについては `03_UI・Styling.md` に従う。

---

# 2. 基本方針

Table Logicには **TanStack Table** を採用する。

Table UIには **shadcn/ui Table** を利用する。

基本構成：

    URL
     ↓
    Search / Filter / Sort / Pagination
     ↓
    TanStack Query
     ↓
    Next.js BFF
     ↓
    Laravel API
     ↓
    PostgreSQL

取得したDataを、

    TanStack Table
         ↓
    shadcn/ui Table

で表示する。

責務：

    TanStack Table
        → Table Logic

    shadcn/ui
        → Table Presentation

    TanStack Query
        → Server State

    URL
        → List State

    Laravel API
        → Search / Filter / Sort / Pagination

一覧DataをすべてBrowserへ取得してから処理する方式をDefaultとしない。

---

# 3. Table Library

## 3.1 採用

Table Libraryには **TanStack Table** を採用する。

TanStack TableはHeadless Table Libraryとして利用する。

主な責務：

- Column定義
- Row Model
- Header
- Cell Rendering
- Sorting State
- Filtering State
- Pagination State
- Row Selection
- Column Visibility

UI StylingはTanStack Tableへ依存しない。

---

## 3.2 採用理由

主な理由：

- Headless
- TypeScriptとの親和性
- React対応
- FlexibleなColumn定義
- Server-side Paginationとの組み合わせ
- Server-side Sortingとの組み合わせ
- Server-side Filteringとの組み合わせ
- shadcn/uiとの親和性
- Application固有Tableを構築しやすい

---

## 3.3 不採用候補

候補：

- MUI Data Grid
- AG Grid
- Handsontable
- Tableの完全自作

### MUI Data Grid

高機能だが、
本ProjectではUI Componentをshadcn/uiへ統一するため採用しない。

### AG Grid

非常に高機能だが、

- Enterprise向け機能
- 高度なSpreadsheet的操作
- 大規模Data Grid

をMVPでは必要としない。

### Handsontable

Spreadsheet的UIを主目的としており、
本Projectの通常の管理一覧には過剰である。

### 完全自作

基本的なTable HTMLはshadcn/uiを利用できるが、

- Column定義
- Sorting
- Selection
- Visibility
- Table State

まで独自実装する必要はない。

---

# 4. shadcn/uiとの役割分担

## 4.1 基本方針

TanStack Tableとshadcn/uiを組み合わせる。

    TanStack Table
        ↓
    Table Logic
        ↓
    shadcn/ui
        ↓
    Presentation

---

## 4.2 TanStack Tableの責務

主に以下を担当する。

- Column Definition
- Header Definition
- Cell Definition
- Row Model
- Sorting State
- Pagination State
- Filter State
- Selection State
- Visibility State

---

## 4.3 shadcn/uiの責務

主に以下を担当する。

- Table
- Table Header
- Table Body
- Table Row
- Table Cell
- Button
- Checkbox
- Dropdown Menu
- Select
- Input
- Pagination UI

---

## 4.4 DataTable Component

ReusableなDataTable Componentを作成してよい。

ただし、

    <DataTable />

へ全一覧要件を詰め込んだ巨大Generic Componentを作らない。

共通化候補：

- Basic Table Layout
- Pagination UI
- Empty State
- Loading State
- Column Visibility UI

Feature固有：

- Column
- Filter
- Row Action
- Cell Renderer
- Permission
- Business-specific Display

を分離する。

---

# 5. Server-side Pagination

## 5.1 基本方針

一覧画面のPaginationは
原則として **Server-side Pagination** とする。

    Browser
       ↓
    page / perPage
       ↓
    API
       ↓
    Database
       ↓
    Page Result

全件取得後にBrowserでPaginationする方式をDefaultとしない。

---

## 5.2 理由

主な理由：

- Employee数増加への対応
- Skill Data増加への対応
- Network Transfer削減
- Browser Memory削減
- Database Index活用
- API責務の明確化

---

## 5.3 Pagination方式

MVPでは **Offset Pagination** を基本とする。

概念：

    page=2
    perPage=20

またはAPI Contractに応じて、

    offset
    limit

を利用する。

具体的なParameter Namingは
OpenAPI Contractで統一する。

---

## 5.4 Cursor Pagination

Cursor PaginationはMVPでは採用しない。

以下が必要になった場合に再検討する。

- 非常に大量のData
- Infinite Scroll
- 頻繁に追加されるTimeline Data
- Offset Costが問題になる

管理画面中心の本Projectでは
Page-based Navigationを優先する。

---

## 5.5 Page Size

Page Sizeは選択可能としてよい。

候補：

    20
    50
    100

ただし具体的なDefault / Maximumは
API Performanceを確認して決定する。

無制限取得Optionを提供しない。

---

# 6. Sort

## 6.1 基本方針

Sortは原則として **Server-side Sorting** とする。

    Column Header
        ↓
    URL Sort State
        ↓
    API
        ↓
    ORDER BY

---

## 6.2 Sort State

Sort対象とDirectionを
URLへ保持する。

例：

    ?sort=name&order=asc

具体的なParameter Namingは
OpenAPI Contractで統一する。

---

## 6.3 Sort可能Column

すべてのColumnをSort可能にしない。

Backend APIが明示的に許可したColumnのみ
Sort可能とする。

---

## 6.4 Backend

Sort ColumnをClientから受け取った文字列のまま
SQLへ利用しない。

Backend側で許可されたSort Keyから
Database ColumnへMappingする。

Frontendの安全性に依存しない。

---

## 6.5 Default Sort

一覧ごとに安定したDefault Sortを定義する。

同一Sort Valueが存在する場合は、
必要に応じてID等をSecondary Sortとして利用し、
Pagination結果の順序を安定させる。

---

# 7. Filter・Search

## 7.1 基本方針

Filter / Searchは原則として
Server-sideで処理する。

    Filter UI
        ↓
    URL
        ↓
    API
        ↓
    Database Query

---

## 7.2 Search

Keyword SearchはURLへ保持する。

例：

    /employees?keyword=php

Search対象Columnや検索仕様は
Backend APIで定義する。

---

## 7.3 Filter

例えばEmployee一覧では、

- Department
- Employment Status
- Skill
- Skill Level

などがFilter候補となる。

実際のFilterは
各Feature要件に応じて追加する。

---

## 7.4 Client-side Filter

Serverから取得済みのPage Dataだけを
Client-side Filterする方式をDefaultとしない。

例えば、

    API → 20件
          ↓
    Browser Filter
          ↓
    3件

とすると、
「全Data中3件」なのか
「現在Page中3件」なのかが曖昧になる。

一覧検索条件は原則Serverへ渡す。

---

## 7.5 Search Input

Keyword入力のたびに
即座にAPI Requestを送信しない。

必要に応じて、

- Search Button
- Enter
- Debounce

を利用する。

UXとAPI負荷を考慮してFeatureごとに決定する。

---

## 7.6 Debounce

Incremental Searchを採用する場合のみ
Debounceを利用する。

すべてのInputへ機械的にDebounceを追加しない。

---

# 8. URL Stateとの連携

## 8.1 基本方針

一覧画面の主要StateはURLへ保持する。

対象：

- Page
- Page Size
- Search Keyword
- Filter
- Sort
- Selected Tab

---

## 8.2 URL例

例えば：

    /employees
        ?page=2
        &perPage=20
        &keyword=php
        &department=3
        &sort=name
        &order=asc

---

## 8.3 URLをSource of Truthとする

一覧条件についてはURLをSource of Truthとする。

避ける：

    URL State
       +
    useState
       +
    Zustand

で同じFilter条件を三重管理する。

---

## 8.4 利点

URL Stateにすることで、

- Reload
- Bookmark
- Share
- Back
- Forward

を自然に利用できる。

---

## 8.5 Parameter Validation

URL ParameterはExternal Inputとして扱う。

必要に応じてZod等でParse / Validateする。

例えば、

    page=-100
    perPage=999999
    sort=unknown

などをそのまま利用しない。

---

## 8.6 Invalid Parameter

不正なParameterについては、

- DefaultへFallback
- Canonical URLへNormalize
- Validation Error

のいずれかをParameterの性質に応じて選択する。

一般的な一覧条件では
安全なDefaultへのFallbackを基本とする。

---

# 9. Column定義

## 9.1 基本方針

Column DefinitionはFeature単位で管理する。

概念：

    features/
      employees/
        table/
          columns.tsx

共通Table Componentへ
Feature固有Columnを埋め込まない。

---

## 9.2 Type Safety

TanStack TableのColumn Definitionには
API ResponseまたはView ModelのTypeを利用する。

    ColumnDef<Employee>

のように型安全に定義する。

---

## 9.3 API Type / View Model

API Responseをそのまま表示できる場合は
Generated Typeを利用できる。

UI用変換が必要な場合のみ、

    API Response
        ↓
    View Model
        ↓
    Column Definition

とする。

---

## 9.4 Cell Renderer

Cell Rendererでは
複雑なBusiness Logicを実行しない。

主に、

- Formatting
- Badge
- Link
- Button
- Status Display

などPresentation Logicを担当する。

---

## 9.5 Column ID

Sort / Visibility等で利用するColumn IDは
安定したIdentifierとする。

Display LabelをIdentifierとして利用しない。

---

# 10. Row Action

## 10.1 基本方針

Row Actionには、

- 詳細
- 編集
- 無効化
- その他Feature固有操作

などを配置できる。

---

## 10.2 Action Menu

Action数が多い場合は
Dropdown Menu等へまとめる。

主要Actionが1つだけの場合は
直接Button / Linkとして表示してよい。

---

## 10.3 Authorization

表示可能ActionはPermissionに応じて制御する。

ただしFrontendでButtonを非表示にするだけで
Authorizationを保証しない。

    Frontend
        → UX

    Backend
        → Authorization

とする。

---

## 10.4 Row Click

Row全体Clickを利用する場合は、
内部Button / LinkとのInteraction Conflictに注意する。

Keyboard操作やAccessibilityを損なう場合は
明示的なDetail Linkを優先する。

---

# 11. Selection

## 11.1 基本方針

Row Selectionは必要な一覧だけで有効にする。

すべてのTableへCheckboxを追加しない。

---

## 11.2 利用例

将来的には、

- Bulk Action
- Bulk Assignment
- Bulk Export

などで利用できる。

MVP要件にBulk Operationがなければ
Selection機能を実装しない。

---

## 11.3 Pageを跨ぐSelection

Server-side Pagination環境で
複数Pageを跨ぐSelectionは複雑になる。

必要になるまでは対応しない。

導入時は、

- Current Page Selection
- Explicit ID Selection
- All Matching Results

を明確に区別する。

---

# 12. Loading・Empty・Error State

## 12.1 基本方針

一覧画面では以下を明確に区別する。

    Loading
    Empty
    No Search Results
    Error
    Data

---

## 12.2 Initial Loading

初回取得時には
Table Skeleton等を利用できる。

既存Dataが存在しない状態で
空Tableだけを表示しない。

---

## 12.3 Background Refetch

Background Refetchでは
既存Tableを可能な限り維持する。

毎回Table全体をLoading UIへ置き換えない。

必要に応じて小さなFetching Indicatorを表示する。

---

## 12.4 Empty State

Dataそのものが存在しない場合：

    Employeeがまだ登録されていません

など、
次のActionが分かるEmpty Stateを表示する。

---

## 12.5 No Results

Filter / Search結果が0件の場合は
通常のEmpty Stateと区別する。

例えば：

    条件に一致する社員が見つかりません

Filter解除などのActionを提供できる。

---

## 12.6 Error

Query Errorでは、

- Error Message
- Retry
- Request ID等のSupport情報

を必要に応じて表示する。

内部Exceptionを直接表示しない。

---

# 13. Responsive Design

## 13.1 基本方針

Desktop Tableを
単純にMobileへ縮小しない。

Dataの重要度に応じて表示方法を変更する。

---

## 13.2 Column Priority

ColumnにPriorityを持たせる。

例えば：

    High
        → Name
        → Skill
        → Status

    Low
        → Supplemental Information

画面幅に応じて
重要度の低いColumnを非表示にできる。

---

## 13.3 Horizontal Scroll

情報量が多い管理Tableでは
Horizontal Scrollを許容する。

無理にすべてのColumnを
狭い画面へ押し込まない。

---

## 13.4 Mobile Layout

Mobileでは必要に応じて、

- Card
- Compact List
- Detail Navigation

への切り替えを検討する。

すべてのTableを必ずCardへ変換するルールにはしない。

---

## 13.5 Column Visibility

UserによるColumn Visibility変更が
明確な価値を持つ場合のみ提供する。

MVPでは必要なColumnを設計側で決めることを優先する。

---

# 14. Accessibility

## 14.1 Semantic Table

Tabular Dataには
Semantic HTML Tableを利用する。

基本：

    table
    thead
    tbody
    tr
    th
    td

見た目だけTableにした `div` 構造をDefaultとしない。

---

## 14.2 Header

Column Headerには
適切な `th` を利用する。

Sort可能Headerでは
現在のSort状態を利用者へ伝える。

---

## 14.3 Sort

Sort状態はVisual Iconだけに依存しない。

必要に応じて `aria-sort` 等を利用する。

---

## 14.4 Checkbox

Row Selection Checkboxには
対象が分かるAccessible Nameを付与する。

---

## 14.5 Action

Icon-only Actionには
Accessible Nameを設定する。

例えば、

    編集

    社員詳細を表示

などをScreen Readerでも理解できるようにする。

---

## 14.6 Keyboard

Table内のInteractive Elementは
Keyboard操作可能とする。

Row ClickだけにNavigationを依存させない。

---

## 14.7 Loading

Loading / Updating状態を
必要に応じて `aria-busy` やStatus Messageで通知する。

---

# 15. 採用技術一覧

| 分類 | 採用技術 / 方針 |
|---|---|
| Table Logic | TanStack Table |
| Table UI | shadcn/ui Table |
| Server State | TanStack Query |
| Pagination | Server-side Offset Pagination |
| Sorting | Server-side Sorting |
| Filtering | Server-side Filtering |
| Search | Server-side Search |
| List State | URL / Next.js Search Params |
| Column Definition | TanStack Table `ColumnDef` |
| Row Action | shadcn/ui Button / Dropdown Menu |
| Row Selection | 必要な場合のみTanStack Table |
| Loading | Skeleton / Existing Data維持 |
| Empty State | 専用Empty UI |
| Error | Query Error UI |
| Responsive | Column Priority / Horizontal Scroll / 必要に応じてList化 |
| Accessibility | Semantic HTML Table + ARIA |

---

## 15.1 不採用

| 技術 / 方針 | 理由 |
|---|---|
| MUI Data Grid | shadcn/uiとのUI方針を優先 |
| AG Grid | MVP要件に対して過剰 |
| Handsontable | Spreadsheet機能を必要としない |
| Table Logic完全自作 | TanStack Tableを利用 |
| 全件Client-side Pagination | Data増加への対応が弱い |
| 全件Client-side Sort | Server-sideをSource of Truthとする |
| Page単位Client-side Filter | 検索結果の意味が不明確になる |
| Cursor Pagination | MVPの管理一覧では不要 |
| Infinite Scroll | 管理画面ではPage Navigationを優先 |
| Filter StateのGlobal Store管理 | URL Stateを利用 |
| 全TableへのRow Selection | 必要なUse Caseのみ導入 |
| 巨大Generic DataTable | Feature固有責務が集中する |
| `div` ベースTable | Semantic HTMLを優先 |

---

# 16. 決定事項

Table Logicには **TanStack Table** を採用する。

Table Presentationには **shadcn/ui Table** を利用する。

基本構成：

    URL
     ↓
    Search / Filter / Sort / Pagination
     ↓
    TanStack Query
     ↓
    Next.js BFF
     ↓
    Laravel API
     ↓
    PostgreSQL

Response：

    Laravel API
        ↓
    TanStack Query
        ↓
    TanStack Table
        ↓
    shadcn/ui Table
        ↓
    User

以下をProject標準方針とする。

1. Table LogicにはTanStack Tableを利用する。
2. Table UIにはshadcn/uiを利用する。
3. TanStack TableをHeadless Table Libraryとして利用する。
4. Server StateはTanStack Queryで管理する。
5. Paginationは原則Server-sideとする。
6. MVPではOffset / Page-based Paginationを採用する。
7. Cursor Paginationは必要になるまで導入しない。
8. Infinite Scrollは管理一覧のDefaultとしない。
9. Sortingは原則Server-sideとする。
10. Sort可能ColumnはBackend側でもAllow Listを持つ。
11. Stable Paginationのため必要に応じてSecondary Sortを定義する。
12. Filteringは原則Server-sideとする。
13. Searchは原則Server-sideとする。
14. Search / Filter / Sort / Pagination StateはURLへ保持する。
15. URLを一覧条件のSource of Truthとする。
16. 同じ一覧条件をLocal State / Global Storeへ重複保持しない。
17. URL ParameterはExternal InputとしてParse / Validateする。
18. Column DefinitionはFeature単位で管理する。
19. Feature固有Columnを巨大な共通DataTableへ埋め込まない。
20. API Typeを直接利用できる場合は不要なView Modelを作らない。
21. Cell RendererにはPresentation Logicを中心に配置する。
22. Row Actionの表示制御はUXであり、Authorizationの最終保証はBackendで行う。
23. Row Selectionは必要なUse Caseのみ実装する。
24. Pageを跨ぐSelectionは必要になるまで実装しない。
25. Loading / Empty / No Results / Error / Dataを区別する。
26. Background Refetch時は可能な限り既存Dataを維持する。
27. Responsive対応ではColumn Priorityを考慮する。
28. 必要に応じてHorizontal Scrollを許容する。
29. MobileでTableが不適切な場合のみList / Card表示を検討する。
30. Tabular DataにはSemantic HTML Tableを利用する。
31. Sort状態をVisual Iconだけに依存させない。
32. Interactive ElementをKeyboard操作可能にする。
33. 全件取得してBrowserで処理する設計をDefaultとしない。
34. Databaseで効率的に検索・Sort・PaginationできるAPI Contractを設計する。
35. Table LibraryにBackend Data処理の責務を持たせない。

以上を `Frontend/08_Table・一覧UI.md` の決定版とする。
