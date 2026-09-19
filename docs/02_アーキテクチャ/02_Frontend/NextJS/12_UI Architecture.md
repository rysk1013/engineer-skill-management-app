# 12_UI Architecture

## 1. 目的

本プロジェクトでは、UI Componentの責務・配置・依存関係を明確にし、Feature固有のUIとApplication全体で再利用するUIを適切に分離する。

目的は以下とする。

- 共通UIとFeature固有UIを分離する
- `app/`へUI Logicを集中させない
- `components/`を巨大な共有Component置き場にしない
- UI ComponentへBusiness Logicを持ち込まない
- Server Component First方針と整合させる
- Client Component Boundaryを必要最小限にする
- Form / Table / Dialog等の責務を明確にする
- AccessibilityをUI Architectureへ組み込む
- UI Library依存を限定する
- Design Systemを過剰設計しない
- Feature間のUI Dependencyを抑える
- 将来のUI変更を局所化する

基本構造を以下とする。

```text
app
 ↓
Feature Components
 ↓
Shared UI Components
```

Directory上では、

```text
src/
├── app/
├── features/
│   └── <feature>/
│       └── components/
└── components/
    ├── ui/
    └── layout/
```

を基本とする。

---

## 2. UI Layerの分類

UIを大きく以下の3種類へ分類する。

```text
1. App-level UI
2. Feature UI
3. Shared UI
```

それぞれ責務を分離する。

---

## 3. App-level UI

App-level UIはApplication全体のCompositionを担当する。

主な例：

```text
Root Layout
Dashboard Layout
Navigation
Header
Sidebar
Page Shell
Route-level Composition
```

配置は、

```text
app/
components/layout/
```

を基本とする。

---

## 4. Feature UI

Feature固有の意味を持つUIは`features/<feature>/components/`へ配置する。

例：

```text
features/
└── employees/
    └── components/
        ├── employee-list.tsx
        ├── employee-table.tsx
        ├── employee-form.tsx
        ├── employee-detail.tsx
        └── employee-skill-section.tsx
```

Feature固有UIはEmployee / Skill等のApplication Conceptを知ってよい。

---

## 5. Shared UI

Application Conceptに依存しない再利用可能なUIは`components/ui/`へ配置する。

例：

```text
components/
└── ui/
    ├── button.tsx
    ├── input.tsx
    ├── select.tsx
    ├── dialog.tsx
    ├── badge.tsx
    ├── table.tsx
    ├── pagination.tsx
    └── alert.tsx
```

---

## 6. Shared UIの基準

`components/ui/`へ配置するComponentは以下を満たすことを基本とする。

```text
Employeeを知らない
Skillを知らない
Permissionを知らない
Laravel APIを知らない
Feature Stateを知らない
```

つまり、

```text
Generic Presentation
```

として成立するものだけをShared UIとする。

---

## 7. Feature Componentの基準

以下のようなUIはFeature Componentとする。

```text
EmployeeTable
SkillSelector
EmployeeSkillForm
PermissionMatrix
DepartmentFilter
```

これらを`components/ui/`へ配置しない。

---

## 8. Shared化を急がない

似ているComponentが1つ存在するだけで共通化しない。

基本方針：

```text
最初
→ Feature内

複数Featureで明確に同じ役割
→ Shared化検討
```

Premature Abstractionを避ける。

---

## 9. Shared Component化の判断

Shared化は以下を基準とする。

```text
複数Featureで利用される
SemanticsがFeature非依存
Propsが自然
Business Knowledgeを必要としない
APIが安定している
```

---

## 10. Feature間で内部UIを直接共有しない

以下を原則避ける。

```text
skills/
 ↓
employees/components/employee-table
```

Feature AがFeature Bの内部Componentへ直接依存しない。

---

## 11. Feature横断Composition

複数Featureを1画面で組み合わせる場合は`app/`側でCompositionする。

```text
app
 ├── Employee Feature
 └── Skill Feature
```

Feature同士を直接結合しない。

---

## 12. `app/`の責務

`app/`は以下を担当する。

```text
Routing
Layout
Page Entry
Feature Composition
Loading
Error
Not Found
Metadata
```

複雑なFeature UI実装を大量に置かない。

---

## 13. Page Component

`page.tsx`は薄く保つ。

概念：

```tsx
export default async function EmployeesPage() {
  const employees = await getEmployees();

  return <EmployeeList employees={employees} />;
}
```

Page Componentは主に、

```text
Data取得
Route Context
Feature Composition
```

を担当する。

---

## 14. Page Componentを巨大化しない

以下のような構成を避ける。

```text
page.tsx
├── Table定義
├── Form定義
├── Dialog
├── Validation
├── API変換
├── Permission分岐
└── 大量のJSX
```

Feature UIへ分離する。

---

## 15. Server Component First

UI ComponentもServer ComponentをDefaultとする。

```text
Component
 ↓
Client機能が必要？
   │
   ├── No → Server Component
   └── Yes → Client Component
```

---

## 16. Server Componentに向くUI

以下はServer Componentを第一候補とする。

```text
Detail表示
List表示
Static Section
Server DataのRendering
Page Header
Read-only Metadata
```

---

## 17. Client Componentに向くUI

以下ではClient Componentを利用する。

```text
Form Interaction
Dialog Open / Close
Dropdown
Tabs
Accordion
Autocomplete
Drag and Drop
Browser API
Local UI State
Event Handler
```

---

## 18. Client Boundaryを小さくする

Page全体を安易にClient Component化しない。

```tsx
"use client";

export default function EmployeesPage() {
  // Page全体
}
```

のような構成は原則避ける。

Interactive部分だけClient Componentへ切り出す。

---

## 19. 推奨Server / Client Boundary

例：

```text
Employee Detail Page
├── EmployeeSummary        Server
├── EmployeeSkillList      Server
└── EditEmployeeButton     Client
```

Formの場合：

```text
Employee Form
├── Form Container         Client
├── Shared UI Primitive
└── Initial Data           Serverから受け取る
```

---

## 20. Server → Client Props

Client Componentへ渡すPropsは必要最小限とする。

以下をそのまま渡さない。

```text
Full Session
Sanctum Token
Internal Credential
不要なBackend DTO全体
```

必要なPresentation Dataだけを渡す。

---

## 21. Serializable Props

Server → Client BoundaryではSerializableなDataを基本とする。

```text
string
number
boolean
null
plain object
array
```

Framework Boundaryを意識してPropsを設計する。

---

## 22. Shared UI ComponentとAPI通信

Shared UI ComponentからAPI通信を行わない。

禁止例：

```text
Button
 ↓
Laravel API
```

```text
components/ui/table.tsx
 ↓
getEmployees()
```

Shared UIはPresentationへ限定する。

---

## 23. Feature ComponentとData Fetch

Feature ComponentでもClient ComponentからLaravelへ直接アクセスしない。

Server Componentの場合はFeature Server Queryを利用できる。

```text
Feature Server Component
 ↓
Feature Server Query
 ↓
API Client
 ↓
Laravel
```

---

## 24. Presentational Component

Data取得を必要としないComponentはPresentational Componentとして分離してよい。

例：

```tsx
<EmployeeTable employees={employees} />
```

のようにPropsのみで描画可能な構成を許可する。

---

## 25. Container / Presentational Pattern

厳格なContainer / Presentational Architectureは採用しない。

ただし、

```text
Data取得
+
純粋な描画
```

を分けた方が理解しやすい場合には利用してよい。

---

## 26. UI ComponentへBusiness Logicを置かない

以下をUI Componentへ置かない。

```text
EmployeeSkill Invariant
Permission管理者最低1人Rule
退職Employee保持Rule
Skill無効化Rule
```

Business RuleはLaravel Domainの責務とする。

---

## 27. UI Condition

Business RuleをUXへ反映するためのUI Conditionは許可する。

例：

```text
未経験
→ Skill Level 2〜5をDisable
```

これはUX Controlであり、Business Invariantの最終Authorityではない。

---

## 28. Permission UI

Permissionに応じて、

```text
Button非表示
Navigation非表示
Read-only表示
```

等を行ってよい。

ただしFrontend Permission ControlをSecurity Boundaryとは扱わず、Laravel Authorizationを必ず残す。

---

## 29. Shared Layout Components

Feature非依存のApplication Layout Componentは`components/layout/`へ配置する。

例：

```text
components/
└── layout/
    ├── app-header.tsx
    ├── sidebar.tsx
    ├── page-container.tsx
    └── page-header.tsx
```

---

## 30. Layout Componentの責務

Layout Componentは主に以下を担当する。

```text
Page Structure
Spacing
Navigation Structure
Header
Sidebar
Responsive Layout
```

Feature固有Data Processingを持たせない。

---

## 31. `layout.tsx`

Next.jsの`layout.tsx`はFramework Layout Boundaryとして扱う。

```text
app/(dashboard)/layout.tsx
 ↓
Shared Layout Components
 ↓
children
```

複雑なLayout UIは`components/layout/`へ分離してよい。

---

## 32. UI Primitive

`components/ui/`は意味のある低Level UI Primitiveを中心とする。

例：

```text
Button
Input
Textarea
Select
Checkbox
Radio
Dialog
Popover
Tooltip
Badge
Table
Pagination
Alert
Skeleton
```

---

## 33. 過剰なPrimitive化を避ける

以下のような抽象化は原則行わない。

```text
div.tsx
span.tsx
flex.tsx
```

意味のあるUI PrimitiveだけをComponent化する。

---

## 34. Design Token

色・Spacing・Typography等は可能な限り一貫したTokenとして扱う。

```text
Color
Spacing
Border Radius
Typography
Shadow
Breakpoints
```

Componentごとに無秩序な値を定義しない。

---

## 35. Design Systemの範囲

MVPでは巨大な独自Design Systemを構築しない。

目標は、

```text
Consistent UI Primitive
+
Reusable Pattern
```

とする。

独立した社内Component Library Package化等は行わない。

---

## 36. UI Library

UI Primitive構築には既存Libraryを利用してよい。

選定基準：

```text
Accessibility
Customizability
TypeScript Support
Next.jsとの相性
Bundle影響
Maintenance状況
```

---

## 37. Accessible Primitive Library

Dialog / Popover / Dropdown等、Accessibility実装が難しいUIでは既存のAccessible / Headless Primitiveを優先して利用する。

Focus Trap、Keyboard Navigation、ARIA等を一から独自実装することを避ける。

---

## 38. shadcn/ui等

shadcn/uiのようにComponent SourceをApplication側へ保持できる方式を有力候補とする。

利点：

```text
SourceをApplication側で管理可能
Customizationしやすい
Runtime Libraryへの依存を限定しやすい
Accessible Primitiveを利用しやすい
```

ただし正式なUI Libraryは実装開始時に採用Version・Maintenance状況を確認して決定する。

---

## 39. UI Library Wrapperを作りすぎない

Library Componentをすべて一段独自Wrapperすることを目的化しない。

以下のような不要なLayerを避ける。

```text
OurButton
OurInput
OurDialog
OurTable
```

DesignやAPI統一に意味があるものだけShared UIとして管理する。

---

## 40. Styling

Styling方式はApplication全体で統一する。

Tailwind CSS等を候補とする。

重要なのは、

```text
Featureごとに異なるStyling方式を混在させない
```

ことである。

---

## 41. Inline Style

Dynamic Style等の明確な理由がない限り、大量のInline Styleを標準としない。

Design Token / Utility Class / Shared Componentを優先する。

---

## 42. CSS Scope

Feature固有StyleはFeature Scopeへ閉じ込める。

Global CSSへFeature固有Ruleを大量追加しない。

---

## 43. Global CSS

Global CSSは主に以下へ限定する。

```text
Reset
Base Typography
CSS Variables
Global Theme
Application-wide Defaults
```

Feature固有Styleは配置しない。

---

## 44. Table Architecture

本Applicationでは一覧画面が多いため、Tableを重要なUI Patternとして扱う。

代表例：

```text
Employee Table
Skill Table
Permission Table
```

---

## 45. Shared Table Primitive

Shared側にはGeneric Table Primitiveを配置する。

```text
Table
TableHeader
TableBody
TableRow
TableCell
```

Employee-specific Column等はFeature側へ置く。

---

## 46. Feature Table

例：

```text
features/
└── employees/
    └── components/
        ├── employee-table.tsx
        └── employee-table-columns.tsx
```

Shared TableはEmployee DTOやEmployee-specific Ruleを知らない。

---

## 47. Table State

Search / Filter / Sort / Paginationは`07_状態管理.md`に従う。

```text
Search
Filter
Sort
Pagination
↓
URL State
```

を基本とする。

Table内部Global Stateへ閉じ込めない。

---

## 48. Client-side Table Library

TanStack Table等はTable Requirementが十分複雑になった場合に導入を検討する。

MVPから高度なTable Infrastructureを構築しない。

---

## 49. Server-side Pagination

Employee等のBusiness DataではServer-side Paginationを基本とする。

```text
URL
 ↓
Server Component
 ↓
Laravel API
 ↓
Paged Result
```

大量DataをBrowserへ全件送信してClient-side Paginationする構成を標準としない。

---

## 50. Form Architecture

Form UIは`09_フォーム・Validation.md`の方針に従う。

```text
Feature Form Component
 ↓
Frontend Schema
 ↓
Server Action
```

---

## 51. Shared Form Primitive

以下はShared UI候補とする。

```text
Input
Textarea
Select
Checkbox
Radio
Label
Field Error
Form Field Layout
```

Employee固有Form等はFeature側へ置く。

---

## 52. Form Field Component

Label / Input / Errorを組み合わせるGeneric Patternを作成してよい。

ただし、

```text
万能FormField
```

1つですべてのInput Typeを処理するような過剰抽象化は避ける。

---

## 53. Dialog Architecture

Dialog PrimitiveはShared UIへ置く。

Feature固有DialogはFeature Componentとする。

```text
components/ui/dialog
      ↓
features/skills/components/deactivate-skill-dialog
```

---

## 54. Dialogへ責務を集中させない

Dialog Componentへ以下を過剰に持たせない。

```text
API Communication
Business Rules
Large State Management
```

MutationはServer Action等の既存Boundaryを利用する。

---

## 55. Confirmation Dialog

Delete / Disable等のConfirmation Dialogでは以下を明確にする。

```text
対象
実行内容
影響
Cancel
Confirm
```

Destructive Actionは通常Actionと視覚的・意味的に区別する。

---

## 56. Modal乱用を避ける

複雑な編集WorkflowをすべてModalへ詰め込まない。

以下ではDedicated Pageを検討する。

```text
入力項目が多い
複数Section
深いNavigation
URL共有が有益
Error Recoveryが複雑
```

---

## 57. Page / Dialog判断

概ね以下を基準とする。

```text
軽い確認 / 小さな入力
→ Dialog

主要編集Workflow
→ Page
```

---

## 58. Feedback UI

User Action結果を必要に応じてFeedbackする。

候補：

```text
Inline Message
Alert
Toast
Updated State
Redirect
```

すべてのSuccess ActionでToastを必須とはしない。

---

## 59. Toast

Toastは補助Feedbackとして扱う。

以下の重要情報をToastだけで伝えない。

```text
Validation Error
Critical Authorization Error
長いRecovery Instruction
```

---

## 60. Success Feedback

Mutation後に画面上のDataが明確に更新される場合、Updated UI自体をSuccess Feedbackとしてよい。

不要なSuccess Toastを大量表示しない。

---

## 61. Error UI

Error UIは`10_エラーハンドリング.md`の方針に従う。

```text
Field Error
Inline Error
Forbidden
Not Found
Error Boundary
System Error
```

を使い分ける。

---

## 62. Empty State

Empty Stateを正式なUI Stateとして扱う。

例：

```text
社員がまだ登録されていません
検索条件に一致する社員はいません
Skillが登録されていません
```

Error Stateと混同しない。

---

## 63. Loading UI

Server Readでは、

```text
loading.tsx
Suspense
Skeleton
```

等を利用する。

すべてのLoadingをSpinnerだけで表現しない。

---

## 64. Skeleton

Layout Shiftを抑えられる一覧・Card等ではSkeletonを利用候補とする。

短時間処理へ過度なLoading Animationを導入しない。

---

## 65. Pending UI

Mutation中は操作箇所へ局所的なPending UIを表示する。

例：

```text
Save Button
↓
Saving...
```

Application全体をBlockingするGlobal LoadingをDefaultとしない。

---

## 66. Navigation UI

Role / Capabilityに応じてNavigation Itemの表示制御を行ってよい。

```text
Navigation
 ↓
Frontend Permission
```

ただしSecurity Boundaryとはしない。

---

## 67. Navigation Definition

Navigation定義をFeature内部へ散在させない。

以下のようなApplication-levelな場所で管理する。

```text
lib/navigation/
```

または、

```text
components/layout/
```

周辺を候補とする。

---

## 68. Breadcrumb

階層が明確な画面ではBreadcrumbを利用してよい。

例：

```text
Employee List
→ Employee Detail
→ Employee Edit
```

---

## 69. Accessibility

AccessibilityをUI Architectureの標準Requirementとする。

対象：

```text
Keyboard Navigation
Focus Management
ARIA
Label
Contrast
Screen Reader
Error Association
Semantic HTML
```

既存のユーザビリティ・アクセシビリティ要件に従う。

---

## 70. Semantic HTML

可能な限りSemantic HTMLを利用する。

```text
button
nav
main
header
section
table
form
label
```

クリック可能な`div`等を安易に利用しない。

---

## 71. Button / Link

ActionにはButton、NavigationにはLinkを利用する。

```text
Save
→ Button

Employee Detailへ移動
→ Link
```

Semanticを混同しない。

---

## 72. Focus Management

以下ではFocusを適切に管理する。

```text
Dialog Open / Close
Validation Error
Route Transition
Dynamic UI
```

特にDialog等はAccessible Primitive Libraryの標準Behaviorを活用する。

---

## 73. Keyboard Operation

主要操作はKeyboardだけでも実行可能にする。

Hoverでしか利用できない重要機能を作らない。

---

## 74. Responsive Design

Desktop業務Applicationを主用途としつつ、最低限Window Widthの変化へ対応する。

例：

```text
Sidebar Collapse
Table Horizontal Scroll
Form Width
Dialog Width
```

---

## 75. Mobile Firstの扱い

一般消費者向けMobile Applicationではないため、Mobile UXを最優先にはしない。

ただしMobile / Narrow Windowで完全に操作不能となる設計も避ける。

互換性・動作環境要件に従う。

---

## 76. Page Width

Pageごとに無秩序なWidth / Paddingを設定しない。

共通`PageContainer`等で、

```text
Max Width
Horizontal Padding
Vertical Spacing
```

を統一する。

---

## 77. Component Size

以下が発生した場合にComponent分割を検討する。

```text
複数責務
巨大なConditional Rendering
多数のState
大量のEvent Handler
読みにくいJSX
```

単純な行数だけを分割基準とはしない。

---

## 78. Component Abstraction

以下の両極端を避ける。

```text
巨大Component
```

```text
過剰な細分化
```

責務単位でComponentを分割する。

---

## 79. Props Design

PropsはComponentの責務を明確に表現する。

以下のような曖昧な万能Propsを避ける。

```ts
type Props = {
  data: any;
  config: any;
  mode: string;
};
```

明確な型を利用する。

---

## 80. Boolean Props

Boolean Propsが大量に増加してComponent Behaviorが複雑になった場合、設計を見直す。

例：

```text
isEditable
isCompact
isAdmin
isCreate
isDelete
isReadOnly
```

が増え続ける場合はComponent分割やVariant設計を検討する。

---

## 81. Variant

Presentation上のVariationが明確なShared UIではVariantを利用してよい。

例：

```text
Button
├── primary
├── secondary
└── destructive
```

Business Role名をVariantへ持ち込まない。

禁止例：

```text
variant="administrator"
```

---

## 82. Compositionを優先する

大量のConfiguration Propsを持つGeneric Componentより、意味のあるCompositionを優先する。

例：

```tsx
<PageHeader>
  <PageHeader.Title />
  <PageHeader.Actions />
</PageHeader>
```

必要な場合に利用する。

---

## 83. 高度なReact Pattern

以下は必要になった場合のみ利用する。

```text
Render Props
Compound Components
Context
高度なGeneric Component Pattern
```

単純なUIへ過剰な抽象化を導入しない。

---

## 84. UI State Ownership

UI Stateは可能な限り最も近いClient Componentが所有する。

```text
Dialog Open
→ Dialog周辺

Dropdown
→ Dropdown Component

Accordion
→ Accordion Component
```

Application Global Storeへ置かない。

---

## 85. Derived UI State

Props / Server Dataから計算可能な値をLocal Stateへ重複保存しない。

例：

```text
skills.length === 0
```

から導出可能なら、

```text
hasSkills
```

を別Stateとして持つ必要はない。

---

## 86. Theme

Theme切替がMVP Requirementでない場合、Light / Dark両対応を必須Architecture Requirementとはしない。

ただしDesign Tokenによって将来的な変更を妨げない構造とする。

---

## 87. Icon

Icon Libraryを利用する場合はApplication全体で統一する。

Featureごとに別Icon Libraryを導入しない。

Decorative IconではAccessibilityを考慮する。

---

## 88. Date / Number Presentation

Date / Year-Month / Number FormatをComponentごとに直接実装しない。

```text
API Data
 ↓
Formatter / View Model
 ↓
UI
```

共通Formatterを利用する。

国際化・日時要件に従う。

---

## 89. Status表示

Employment Status / Skill State等のAPI ValueとUI Labelを分離する。

```text
ACTIVE
↓
在籍
```

API Enum値をそのままUserへ表示しない。

---

## 90. Badge

Status表示にはShared Badge Primitiveを利用してよい。

Feature側で、

```text
EmploymentStatus
↓
Badge Variant / Label
```

へMappingする。

Shared BadgeはEmploymentStatus自体を知らない。

---

## 91. Feature Public API

外部からFeature UIを利用する場合、Feature Public APIを基本とする。

```text
features/employees/index.ts
```

ただしServer-only ExportとClient-safe Exportを不用意に混在させない。

---

## 92. Deep Import

別Featureや`app/`からFeature内部へ無制限なDeep Importを行わない。

例：

```text
features/employees/components/internal/foo
```

への外部依存を抑える。

---

## 93. Shared UI Dependency

依存方向は、

```text
Feature
  ↓
Shared UI
```

とする。

逆方向：

```text
Shared UI
  ↓
Feature
```

は禁止する。

---

## 94. Layout Dependency

基本Dependency：

```text
app
 ↓
components/layout
 ↓
components/ui
```

とする。

LayoutからFeature Componentへ大量に依存する構成を避ける。

---

## 95. UI Test

Shared UIでは主に以下を確認する。

```text
Interaction
Accessibility
Variant
Keyboard Behavior
```

Feature UIでは以下を確認する。

```text
Business Dataの表示
Permissionによる表示差
Form Interaction
Error State
Empty State
```

---

## 96. Implementation Detail Testを避ける

以下のような内部実装への過剰依存を避ける。

```text
内部Stateがtrueになった
内部関数が呼ばれた
特定Class Nameが存在する
```

User Interaction / Visible Behaviorを中心にTestする。

---

## 97. Storybook等

Shared UI Componentが増え、独立確認のBenefitが明確になった場合はStorybook等を検討する。

MVP開始時点では必須としない。

---

## 98. Visual Regression

UI規模・変更頻度が増加しBenefitが明確になった場合、Visual Regression Testを検討する。

MVPから過剰なTest Infrastructureを追加しない。

---

## 99. UI Architecture判断フロー

```text
UIが必要
   │
   ▼
Feature固有の意味を持つ？
   │
   ├── Yes
   │    ↓
   │ features/<feature>/components
   │
   └── No
        │
        ▼
Application Layout？
        │
        ├── Yes
        │    ↓
        │ components/layout
        │
        └── No
             │
             ▼
複数箇所で使うGeneric UI？
             │
             ├── Yes
             │    ↓
             │ components/ui
             │
             └── No
                  ↓
             使用箇所の近くへ配置
```

---

## 100. Server / Client判断フロー

```text
Component
   │
   ▼
Client State / Event / Browser APIが必要？
   │
   ├── No
   │    ↓
   │ Server Component
   │
   └── Yes
        ↓
   Client Component
        ↓
   Boundaryを可能な限り小さくする
```

---

## 101. Architecture全体像

```text
┌─────────────────────────────────────┐
│ app/                                │
│                                     │
│ Routing                             │
│ Layout                              │
│ Page Entry                          │
│ Feature Composition                 │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│ features/                           │
│                                     │
│ Employee UI                         │
│ Skill UI                            │
│ Access Control UI                   │
│ Feature Forms / Tables / Dialogs    │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│ components/                         │
│                                     │
│ ui/                                 │
│ ├── Button                          │
│ ├── Input                           │
│ ├── Dialog                          │
│ └── Table                           │
│                                     │
│ layout/                             │
│ ├── Header                          │
│ ├── Sidebar                         │
│ └── Page Container                  │
└─────────────────────────────────────┘
```

Dependency：

```text
app
 ↓
features
 ↓
components/ui

app
 ↓
components/layout
 ↓
components/ui
```

---

## 102. 責務境界

```text
app
=
Framework / Route / Composition

Feature Component
=
Feature-specific Presentation / Interaction

Shared UI
=
Generic UI Primitive

Layout Component
=
Application Structure

Server Component
=
Server-side Rendering / Read-oriented UI

Client Component
=
Interaction / Local UI State

Laravel
=
Business Correctness
```

---

## 103. 決定事項

Frontend UI Architectureとして、以下を正式採用する。

- UIをApp-level / Feature / Sharedの3種類へ分類する
- Feature固有UIは`features/<feature>/components/`へ配置する
- Generic UI Primitiveは`components/ui/`へ配置する
- Application Layout Componentは`components/layout/`へ配置する
- `app/`はRouting / Layout / Feature Compositionを中心とする
- `page.tsx`を薄く保つ
- `components/`を巨大な共有Component置き場にしない
- Shared UIはEmployee / Skill等のFeature Conceptへ依存しない
- Feature ComponentはFeature Conceptを知ってよい
- Feature間の内部Component直接利用を原則避ける
- 複数FeatureのCompositionは`app/`側で行う
- Shared化を急がずFeature内部から開始する
- 明確な再利用性とFeature非依存性が確認された場合のみShared化する
- Server ComponentをDefaultとする
- Client ComponentはInteractionが必要な箇所だけ利用する
- `"use client"` Boundaryを可能な限り小さくする
- Server → Client Propsは必要最小限かつ安全なDataに限定する
- Shared UIからAPI通信を行わない
- Client ComponentからLaravelへ直接アクセスしない
- UI ComponentへBusiness Invariantを置かない
- Business Ruleに基づくUX ControlはFrontendで実施してよい
- Frontend Permission UIをSecurity Boundaryとは扱わない
- Shared Layout ComponentをFeature Logicから独立させる
- Shared UIは意味のあるPrimitiveを中心とする
- `div`等の過度な低Level抽象化を避ける
- Design TokenによってVisual Consistencyを維持する
- MVPで巨大な独自Design Systemを構築しない
- Accessibilityが難しいInteractive Primitiveは既存Library利用を優先する
- shadcn/ui等をUI基盤候補とするが、実装開始時に現行仕様を確認して正式決定する
- UI Libraryをすべて独自Wrapperする構成を採用しない
- Styling方式をApplication全体で統一する
- Global CSSへFeature固有Styleを大量に置かない
- Generic Table PrimitiveとFeature Tableを分離する
- Search / Filter / Sort / PaginationはURL State方針に従う
- Server-side PaginationをBusiness Data一覧の基本とする
- Client-side Table LibraryはRequirementが複雑化した場合のみ検討する
- Form UIは`09_フォーム・Validation.md`に従う
- Generic Form PrimitiveとFeature Formを分離する
- Dialog PrimitiveとFeature Dialogを分離する
- 複雑な編集WorkflowをModalへ詰め込まない
- 軽い確認・小規模入力はDialog、主要編集WorkflowはPageを基本とする
- Toastを補助Feedbackとして扱う
- 重要ErrorをToastだけで通知しない
- 画面変化自体が明確な場合は不要なSuccess Toastを表示しない
- Empty / Loading / Error / Pending Stateを明確に分ける
- Mutation Pendingは局所的UIで表現する
- Navigation表示はRole / Capabilityに応じて制御してよい
- Navigation DefinitionをFeatureへ散在させない
- AccessibilityをUI Architectureの標準Requirementとする
- Semantic HTMLを優先する
- ActionはButton、NavigationはLinkを基本とする
- Focus / Keyboard Navigationを考慮する
- Desktop業務Applicationを主用途としつつ最低限Responsive対応する
- Page Layout / Width / Spacingを共通化する
- Componentは責務単位で分割する
- 巨大Componentと過剰な細分化の両方を避ける
- Propsを明確に型付けする
- Boolean Propsが増えすぎた場合はComponent設計を見直す
- Shared UIのVariantへBusiness Role等を持ち込まない
- 複雑なConfiguration PropsよりCompositionを優先する
- 高度なReact PatternはRequirementが出た場合のみ利用する
- UI Stateは可能な限り最も近いClient Componentが所有する
- Derived UI Stateを重複保持しない
- Theme切替をMVP必須要件とはしない
- Icon LibraryはApplication全体で統一する
- Date / Number FormattingをComponentへ散在させない
- API Enum ValueとUser-facing Labelを分離する
- Shared Badge等のPrimitiveはFeature Enumを知らない
- Feature外からの利用はFeature Public APIを基本とする
- Feature内部へのDeep Importを抑える
- DependencyはFeature → Shared UIの一方向とする
- Shared UIからFeatureへ依存させない
- UI TestはUser-visible Behaviorを中心とする
- Storybook / Visual Regressionは必要性が明確になった時点で検討する

以上をFrontend UI Architectureとする。
