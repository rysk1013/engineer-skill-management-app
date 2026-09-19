# Frontend 技術選定

## 1. 概要

本ディレクトリでは、
Engineer Skill Management AppのFrontend / BFFで利用する
Technology StackおよびTechnology Selection方針を管理する。

対象：

- Runtime
- Framework
- UI / Styling
- Data Fetching
- Server State
- API Client
- OpenAPI
- Form
- Validation
- State Management
- Table
- Date / Utility
- Feedback / Error UI
- UI Development
- Test
- Code Quality
- Developer Experience

Frontend / BFFには
**Next.js + React + TypeScript** を採用する。

基本構成：

    Browser
       ↓
    Next.js
    Frontend + BFF
       ↓
    Laravel API
       ↓
    PostgreSQL

BrowserからLaravel APIへ
直接Accessしない。

Next.jsからBusiness Databaseへ
直接Accessしない。

---

## 2. 本ディレクトリの目的

本ディレクトリでは主に、

> Frontendで何を使うか

を定義する。

一方、

> Frontendをどう設計するか

についてはFrontend Architectureで定義する。

基本：

    Frontend Architecture
        → How

    Frontend Technology Selection
        → What

ArchitectureとTechnology Selectionを分離し、
同じ内容を複数Documentへ重複して定義しない。

---

## 3. Document構成

```text
Frontend/
├── 01_基本方針.md
├── 02_基本技術・Runtime.md
├── 03_UI・Styling.md
├── 04_データ取得・Server-State.md
├── 05_API-Client・OpenAPI.md
├── 06_Form・Validation.md
├── 07_状態管理.md
├── 08_Table・一覧UI.md
├── 09_Date・Utility.md
├── 10_Feedback・Error-UI.md
├── 11_UI開発.md
├── 12_テスト.md
├── 13_コード品質・Developer-Experience.md
├── 14_採用技術一覧.md
└── README.md
```

---

## 4. Document一覧

| Document | 主な内容 |
|---|---|
| `01_基本方針.md` | Technology Selection全体の原則 |
| `02_基本技術・Runtime.md` | Node.js / TypeScript / React / Next.js / pnpm |
| `03_UI・Styling.md` | Tailwind CSS / shadcn/ui / Base UI / Design Token |
| `04_データ取得・Server-State.md` | fetch / TanStack Query / Cache |
| `05_API-Client・OpenAPI.md` | OpenAPI / Orval / Fetch API / API Error |
| `06_Form・Validation.md` | React Hook Form / Zod |
| `07_状態管理.md` | Server / URL / Form / Local / Global State |
| `08_Table・一覧UI.md` | TanStack Table / Pagination / Sort / Filter |
| `09_Date・Utility.md` | date-fns / Intl / Date / DateTime / Year-Month |
| `10_Feedback・Error-UI.md` | Toast / Alert / Dialog / Error UI |
| `11_UI開発.md` | Storybook / Mock / UI State / Accessibility |
| `12_テスト.md` | Vitest / RTL / MSW / Playwright |
| `13_コード品質・Developer-Experience.md` | ESLint / Prettier / Knip / Husky / Renovate |
| `14_採用技術一覧.md` | Frontend Technology Stack一覧 |

---

## 5. 推奨する読み方

### 5.1 初めてProjectへ参加する場合

まず以下を読む。

    README.md
        ↓
    01_基本方針.md
        ↓
    02_基本技術・Runtime.md
        ↓
    14_採用技術一覧.md

これにより、

- Frontend全体構成
- Technology Selection方針
- Runtime / Framework
- 採用Technology Stack

を把握できる。

その後、
担当Featureに応じて個別Documentを参照する。

---

### 5.2 UIを実装する場合

    03_UI・Styling.md
        ↓
    10_Feedback・Error-UI.md
        ↓
    11_UI開発.md

必要に応じて、

    08_Table・一覧UI.md
    09_Date・Utility.md

も参照する。

---

### 5.3 API連携を実装する場合

    04_データ取得・Server-State.md
        ↓
    05_API-Client・OpenAPI.md
        ↓
    07_状態管理.md

Formの場合は、

    06_Form・Validation.md

も参照する。

---

### 5.4 一覧画面を実装する場合

    04_データ取得・Server-State.md
        ↓
    07_状態管理.md
        ↓
    08_Table・一覧UI.md

を参照する。

---

### 5.5 Formを実装する場合

    05_API-Client・OpenAPI.md
        ↓
    06_Form・Validation.md
        ↓
    10_Feedback・Error-UI.md

を参照する。

---

### 5.6 Testを実装する場合

    11_UI開発.md
        ↓
    12_テスト.md
        ↓
    13_コード品質・Developer-Experience.md

を参照する。

---

## 6. Frontend Technology Stack

主要Technology Stack：

| 分類 | 採用 |
|---|---|
| Runtime | Node.js 24 LTS |
| Language | TypeScript |
| UI | React 19 |
| Framework | Next.js |
| Router | App Router |
| Package Manager | pnpm |
| Styling | Tailwind CSS v4 |
| UI Component | shadcn/ui |
| Primitive | Base UI |
| Icon | Lucide |
| Class Utility | `cn` |
| Server Fetch | Next.js / React標準 `fetch` |
| Server State | TanStack Query |
| API Contract | OpenAPI |
| API Generator | Orval |
| HTTP Client | Fetch API |
| Form | React Hook Form |
| Validation | Zod |
| Table | TanStack Table |
| Date | date-fns |
| Locale Format | `Intl` |
| Toast | Sonner |
| UI Development | Storybook |
| Unit Test | Vitest |
| Component Test | React Testing Library |
| User Interaction | `@testing-library/user-event` |
| HTTP Mock | MSW |
| E2E | Playwright |
| Lint | ESLint |
| Formatter | Prettier |
| Dead Code | Knip |
| Git Hook | Husky |
| Staged Check | lint-staged |
| Dependency Update | Renovate |

詳細は `14_採用技術一覧.md` を参照する。

---

## 7. Technology Stack 全体像

```text
Browser
   ↓
┌─────────────────────────────────────────┐
│ Next.js                                 │
│                                         │
│ React                                   │
│ TypeScript                              │
│ App Router                              │
│                                         │
│ Tailwind CSS                            │
│ shadcn/ui                               │
│ Base UI                                 │
│                                         │
│ React Hook Form                         │
│ Zod                                     │
│                                         │
│ TanStack Query                          │
│ TanStack Table                          │
│                                         │
│ date-fns / Intl                         │
│ Sonner                                  │
└────────────────────┬────────────────────┘
                     │
                     ↓
                 Orval Client
                     │
                     ↓
                  Fetch API
                     │
                     ↓
                 Next.js BFF
                     │
                     ↓
                 Laravel API
                     │
                     ↓
                 PostgreSQL
```

---

## 8. State Management

Stateは種類ごとに管理方法を分離する。

```text
Application State
   │
   ├── Server State
   │      └── TanStack Query
   │
   ├── URL State
   │      └── Next.js URL / Search Params
   │
   ├── Form State
   │      └── React Hook Form
   │
   ├── Local UI State
   │      └── useState / useReducer
   │
   └── Shared UI State
          └── React Context
```

MVPでは専用Global State Libraryを導入しない。

将来Global Client Stateが必要になった場合の
第一候補はZustandとする。

詳細は `07_状態管理.md` を参照する。

---

## 9. API Development

OpenAPIを
API ContractのSource of Truthとする。

```text
OpenAPI
   ↓
Validation
   ↓
Breaking Change Check
   ↓
Orval
   ↓
Generated Type
   +
Generated Client
   +
TanStack Query Integration
   ↓
Frontend
```

Generated Codeを
手動編集しない。

API TypeをFrontendで
手書き重複定義しない。

詳細：

- `05_API-Client・OpenAPI.md`
- 親Directoryの `04_API・OpenAPI.md`

---

## 10. UI Development

UI Stack：

```text
CSS Variables
   ↓
Semantic Design Token
   ↓
Tailwind CSS
   ↓
shadcn/ui
   ↓
Base UI
   ↓
Application Component
   ↓
Storybook
```

Storybookは、

- Component単体確認
- UI State
- Mock Data
- Interaction
- Accessibility
- Visual確認

に利用する。

すべてのComponentへの
Story作成は義務付けない。

MVPでは独立Design Systemを構築しない。

---

## 11. Test Strategy

基本Test Stack：

```text
Pure Logic
    → Vitest

UI Behavior
    → React Testing Library
      + user-event

HTTP Boundary
    → MSW

UI State
    → Storybook

Critical User Flow
    → Playwright
```

基本原則：

> Implementation Detailではなく
> User-visible BehaviorをTestする。

E2EはCritical User Flowへ限定する。

Coverage 100%を目標にしない。

詳細：

- `12_テスト.md`

---

## 12. Code Quality

基本構成：

```text
TypeScript
    → Type Safety

ESLint
    → Code Quality

Prettier
    → Formatting

Knip
    → Dead Code / Unused Dependency

Husky
    → Git Hook

lint-staged
    → Changed File Check

Renovate
    → Dependency Update

CI
    → Final Quality Gate
```

Local / Git Hook / CIの責務：

```text
Editor
    → Immediate Feedback

Git Hook
    → Changed File Early Check

Local Command
    → Developer Check

CI
    → Repository-wide Final Check
```

Git Hookで重いTestを実行しない。

Final Quality GateはCIとする。

詳細：

- `13_コード品質・Developer-Experience.md`

---

## 13. Cross-cutting Documentとの関係

Frontend Directoryだけで
すべてのTechnology Selectionを完結させない。

Cross-cuttingなTechnologyについては
親DirectoryのDocumentをSourceとする。

主な関係：

```text
Frontend/
    ↓
Frontend固有Technology

../03_認証方式.md
    ↓
Authentication

../03_認証方式.md
    ↓
Session Store

../04_API・OpenAPI.md
    ↓
API Contract / OpenAPI全体方針

12_テスト.md
    ↓
Frontend Test Tool

13_コード品質・Developer-Experience.md
    ↓
Frontend Code Quality
```

Frontend Documentでは
Frontend側の利用方法のみ定義する。

---

## 14. Architectureとの関係

Technology SelectionとArchitectureの責務を分離する。

例えば：

```text
Technology Selection

TanStack Queryを使う
        ↓
Frontend Architecture

どのLayerから利用するか
どこへQueryを配置するか
Server / Client Boundaryをどうするか
```

同様に：

```text
Technology Selection

React Hook Form + Zod
        ↓
Frontend Architecture

Form Componentをどこへ配置するか
Validation Schemaをどこへ配置するか
```

Architecture上のRuleを
Technology Selection Documentへ過剰に重複記載しない。

---

## 15. Technology Selectionの原則

新しいTechnology / Libraryを導入する場合は
以下を確認する。

1. 解決すべきRequirementが存在するか
2. Next.js / React標準機能で解決できないか
3. 既存Libraryと責務が重複しないか
4. TypeScript Supportは十分か
5. Maintenance状況に問題がないか
6. Documentationは十分か
7. Ecosystemは安定しているか
8. Accessibilityへの影響は問題ないか
9. Performance / Bundleへの影響は許容できるか
10. Developer Experienceは改善するか
11. Test可能か
12. Security Riskは許容できるか
13. Lock-in / Migration Costは許容できるか
14. MVPで本当に必要か

基本：

> Standard機能を優先し、
> Libraryの責務を重複させず、
> 必要なTechnologyだけを導入する。

---

## 16. Version管理

Documentでは原則として
Major Version / Technology Generationを記載する。

Exact Patch Versionは
Repository ConfigurationをSource of Truthとする。

主な管理場所：

```text
package.json
pnpm-lock.yaml
Dockerfile
CI Configuration
```

例えば、

```text
Document
    → React 19

Repository
    → Exact Version
```

とする。

Version Upgrade時に
すべてのArchitecture / Technology Documentへ
Patch Version修正を要求しない。

---

## 17. Dependency追加Rule

新しいFrontend Dependencyを追加する場合は、

```text
Requirement
   ↓
Platform Standardで解決可能か
   ↓
既存Dependencyで解決可能か
   ↓
新規Libraryが必要か
   ↓
責務重複Check
   ↓
Maintenance / Security / Size確認
   ↓
導入
```

の順に判断する。

「便利そうだから」という理由だけで
Dependencyを追加しない。

---

## 18. MVP方針

MVPでは、

- 必要なTechnologyのみ導入する
- 将来Requirementだけを理由にLibraryを導入しない
- 過度なGeneric Abstractionを避ける
- 独立Design Systemを構築しない
- 専用Global State Libraryを導入しない
- Visual Regression SaaSを必須化しない
- Architecture Boundary Toolを過剰に導入しない

とする。

一方で、

- Type Safety
- API Contract
- Testability
- Accessibility
- Code Quality
- Maintainability

についてはMVP段階から考慮する。

---

## 19. Frontend Technology Selection 決定事項

Frontend / BFFでは、

```text
Runtime
    → Node.js 24 LTS

Language
    → TypeScript

Framework
    → Next.js

UI
    → React 19

Package Manager
    → pnpm

Styling
    → Tailwind CSS v4

UI Component
    → shadcn/ui

Primitive
    → Base UI

Server State
    → TanStack Query

API Contract
    → OpenAPI

API Generator
    → Orval

HTTP
    → Fetch API

Form
    → React Hook Form

Validation
    → Zod

Table
    → TanStack Table

Date
    → date-fns

Locale
    → Intl

Feedback
    → Sonner + shadcn/ui

UI Development
    → Storybook

Unit Test
    → Vitest

Component Test
    → React Testing Library

HTTP Mock
    → MSW

E2E
    → Playwright

Lint
    → ESLint

Formatter
    → Prettier

Dead Code
    → Knip

Git Hook
    → Husky + lint-staged

Dependency Update
    → Renovate

Final Quality Gate
    → CI
```

を採用する。

Frontend Technology Selectionでは、

> 何を使うか

を定義し、

Frontend Architectureでは、

> どう設計するか

を定義する。

各Technologyには明確な責務を持たせ、
同一責務を持つLibraryを複数導入しない。

RequirementやProject Scaleが変化した場合は
既存の決定を絶対視せず、
Technology Selectionの原則に基づいて再評価する。

以上を `Frontend/README.md` の決定版とする。
