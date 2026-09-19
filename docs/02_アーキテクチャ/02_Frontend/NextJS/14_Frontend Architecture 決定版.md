# 14_Frontend Architecture 決定版

## 1. 目的

本ドキュメントは、Frontend Architectureに関する各設計書の決定事項を統合し、Next.js Frontend / BFF全体の最終Architectureを定義する。

対象となる設計書は以下とする。

```text id="v4xs2z"
01_Frontend Architecture 全体方針.md
02_ディレクトリ構成.md
03_レイヤー・依存関係.md
04_Server・Client 境界.md
05_データ取得・更新.md
06_API Client・OpenAPI.md
07_状態管理.md
08_認証・認可.md
09_フォーム・Validation.md
10_エラーハンドリング.md
11_キャッシュ戦略.md
12_UI Architecture.md
13_テスト戦略.md
```

本ドキュメントをFrontend Architecture全体の最上位方針とし、個別設計書は各論の詳細を定義する。

---

## 2. Architectureの基本方針

本Frontend Architectureは以下を中核とする。

```text id="aosbia"
Server Component First
        +
Feature-based Architecture
        +
BFF Boundary
        +
OpenAPI Generated Client
```

Frontend全体のOrientationは以下とする。

```text id="y7o8w0"
Backend
=
Domain-oriented Architecture

Frontend
=
Feature-oriented Architecture
```

BackendのClean Architecture / DDD LayerをFrontendへそのまま複製しない。

---

## 3. Next.jsの責務

Next.jsはFrontend + BFFとして利用する。

Next.jsの主な責務：

```text id="rwi2so"
UI Rendering
Routing
Layout
Authentication Session
Frontend Authorization
BFF
Laravel API Communication
Frontend-specific Transformation
Frontend-specific Orchestration
Loading / Error UI
```

Next.jsをBusiness DomainのAuthorityとはしない。

---

## 4. Laravelとの責務境界

責務を以下のように分ける。

```text id="ti7opq"
Next.js
=
Frontend Convenience
UX
Presentation
BFF

Laravel Application / Domain
=
Business Correctness
Authorization Authority
Business Invariant
Source of Truth
```

FrontendでBusiness RuleをUXへ反映することは許可するが、最終保証はLaravelで行う。

---

## 5. 全体Architecture

```text id="vhmiwa"
┌──────────────────────────────────────┐
│ Browser                              │
│                                      │
│ UI Interaction                      │
│ Auth.js Session                     │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│ Next.js                              │
│                                      │
│ App Router                           │
│ Server Components                   │
│ Client Components                   │
│ Server Actions                       │
│ Route Handlers                       │
│ Auth.js                              │
│ Frontend Authorization               │
│ BFF                                  │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│ API Client                           │
│                                      │
│ OpenAPI Generated Client             │
│ Handwritten Adapter                  │
│ Error Normalization                  │
│ Sanctum Token Injection              │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│ Laravel                              │
│                                      │
│ Application                          │
│ Domain                               │
│ Authorization                        │
│ Business Invariant                   │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│ PostgreSQL                           │
│                                      │
│ Business Data Source of Truth        │
└──────────────────────────────────────┘
```

---

## 6. BrowserからLaravelへの直接Access

BrowserからLaravel APIを直接呼び出す構成は禁止する。

禁止：

```text id="nwb1hx"
Browser
  ↓
Laravel API
```

基本：

```text id="0s2y02"
Browser
  ↓
Next.js
  ↓
Laravel API
```

Laravel Credential / Sanctum TokenをBrowserへ露出させない。

---

## 7. Authentication Boundary

Authentication Boundaryを以下の2つに分離する。

```text id="jvl2bu"
Browser
   │
   │ Auth.js Session
   ▼
Next.js
   │
   │ Laravel Sanctum Token
   ▼
Laravel API
```

責務：

```text id="k0evzb"
Browser ↔ Next.js
=
Auth.js Session

Next.js ↔ Laravel
=
Sanctum Token
```

Sanctum TokenはServer-sideのみで扱う。

---

## 8. Authorization Boundary

Authorizationは二段階とする。

```text id="u3dqq9"
Next.js Authorization
=
UX / Early Rejection

Laravel Authorization
=
Security Authority
```

Frontendでは、

```text id="er390b"
Buttonを見せない
Navigationを見せない
Read-onlyにする
Forbidden UIを表示する
```

等を行ってよい。

ただしLaravel側で必ず再Authorizationする。

---

## 9. AuthenticationとAuthorizationを分離する

```text id="yv26q8"
Authentication
=
誰か

Authorization
=
何ができるか
```

を明確に分離する。

Auth.js SessionをAuthenticationのSource of Truthとする。

Frontend独自の、

```text id="kn7nj6"
isLoggedIn Store
currentUser Store
authStore
```

を作らない。

---

## 10. Server Component First

Server ComponentをDefaultとする。

```text id="7yrlui"
Component
 ↓
Client機能が必要？
   │
   ├── No
   │    ↓
   │ Server Component
   │
   └── Yes
        ↓
   Client Component
```

Page全体を安易にClient Component化しない。

---

## 11. Client Componentの利用条件

Client Componentは主に以下で利用する。

```text id="f8a81k"
useState
useEffect
useReducer
Event Handler
Browser API
Form Interaction
Dialog
Dropdown
Autocomplete
Local UI State
```

`"use client"` Boundaryは可能な限り小さくする。

---

## 12. Read Flow

通常のRead Flowは以下とする。

```text id="f1eqap"
Server Component
      ↓
Feature Server Query
      ↓
API Client
      ↓
Laravel API
```

Server ComponentからLaravelへアクセスするためにRoute Handlerを経由しない。

避ける：

```text id="wcfjsm"
Server Component
      ↓
Route Handler
      ↓
Laravel API
```

---

## 13. Client-side Read

Client Interaction後に追加Readが必要な場合は以下とする。

```text id="ig70ih"
Client Component
      ↓
Route Handler
      ↓
API Client
      ↓
Laravel API
```

代表例：

```text id="emkjj7"
Autocomplete
Infinite Scroll
Polling
Browser Interaction後の追加取得
```

MVPではClient-side Readを必要最小限とする。

---

## 14. Mutation Flow

MutationはServer Actionを第一候補とする。

```text id="bfo01c"
UI
 ↓
Server Action
 ↓
Authentication / Authorization
 ↓
Validation / Normalization
 ↓
API Client
 ↓
Laravel API
 ↓
Revalidation
```

Server ActionはBusiness LayerではなくTrust Boundaryとして扱う。

---

## 15. Route Handlerの利用条件

Route HandlerはHTTP Endpoint自体が必要な場合のみ利用する。

代表例：

```text id="01ubj0"
Client-side Fetch
Auth Endpoint
External Callback
Webhook
File Download
Streaming
Custom Header
Proxy Response
```

万能Proxyとして利用しない。

---

## 16. Feature-based Architecture

FrontendはFeature単位で構成する。

```text id="zpsgm4"
features/
├── employees/
├── skills/
├── skill-categories/
└── access-control/
```

BackendのLayer構造をFrontendへ複製しない。

---

## 17. 基本Directory

```text id="xkpx3l"
src/
├── app/
├── features/
├── components/
├── lib/
├── types/
└── styles/
```

責務：

```text id="kzghw5"
app/
=
Framework Boundary

features/
=
Feature-specific Implementation

components/
=
Feature-independent UI

lib/
=
Feature-independent Technical Foundation

types/
=
Application-wide Frontend Types

styles/
=
Global Style
```

---

## 18. Feature Directory

Feature内部では必要に応じて以下を利用する。

```text id="yn0hh6"
features/<feature>/
├── components/
├── server/
├── actions/
├── schemas/
├── mappers/
├── types/
└── index.ts
```

すべてのSubdirectoryを必須にはしない。

---

## 19. Feature Public API

Feature外から利用する場合、原則としてFeature Public APIを利用する。

```text id="apnwbh"
features/employees/index.ts
```

Feature内部への無制限なDeep Importを避ける。

Server-only ExportはClient-safe Public APIと分離する。

---

## 20. Server-only Public API

必要に応じて、

```text id="ag0ijp"
features/employees/
├── index.ts
└── server/
    ├── index.ts
    └── get-employees.ts
```

とする。

`server/index.ts`では`server-only` Boundaryを明示できる。

---

## 21. Dependency Rule

最終Dependency Graphを以下とする。

```text id="6s1ggd"
app
 ├──→ features
 ├──→ components
 ├──→ lib
 └──→ types

features
 ├──→ components
 ├──→ lib
 └──→ types

components
 ├──→ lib
 └──→ types

lib
 └──→ types

types
 └──→ 原則依存なし
```

---

## 22. Dependency原則

以下を正式なRuleとする。

```text id="w0n3p6"
Feature does not know app

Shared does not know Feature

Generated Code does not know App Code

Server-only Code does not flow to Client

Type Dependencyも同じ方向

Circular Dependencyは禁止
```

---

## 23. Feature間Dependency

Feature AからFeature Bの内部実装へ直接依存することを原則避ける。

```text id="wzsrpy"
Feature A
  ×
Feature B Internal
```

複数FeatureのCompositionは`app/`で行う。

---

## 24. OpenAPI First

Laravel API ContractはOpenAPIをSource of Truthとする。

```text id="l7y40w"
OpenAPI
 ↓
Generated Client / Types
 ↓
Frontend
```

LaravelからFrontend型を生成する方式にはしない。

---

## 25. OpenAPI変更Flow

```text id="sr4chp"
OpenAPI変更
 ↓
Contract Review
 ↓
Generated Code再生成
 ↓
Laravel実装
 ↓
Frontend実装
```

Contract変更を先に明示する。

---

## 26. Generated Code

Generated Codeは以下へ配置する。

```text id="48nwbc"
lib/
└── api/
    └── generated/
```

Generated Codeは手動編集禁止とする。

---

## 27. Handwritten API Client

```text id="r93a95"
lib/
└── api/
    ├── generated/
    ├── client.ts
    ├── errors.ts
    └── index.ts
```

Handwritten ClientをGenerated ClientとFrontend Featureの間のAdapterとする。

---

## 28. API Clientの責務

API Clientは以下を担当する。

```text id="y8xwzs"
Base URL
Common Header
Sanctum Token Injection
Transport
Timeout
Error Normalization
Request ID / Trace Context
```

Business Ruleは持たない。

---

## 29. Raw Fetch禁止

Laravel API CommunicationをFeatureごとのRaw `fetch`へ散在させない。

```text id="fhlq4y"
Feature
 ↓
Common API Client
 ↓
Generated Client
```

とする。

---

## 30. Credential Injection

Sanctum Token InjectionはAPI Clientへ集約する。

禁止：

```text id="2bx0kf"
getEmployee(token, employeeId)
```

FeatureがCredentialを引数として扱う構成を避ける。

---

## 31. API DTO

Generated API DTOをAPI Contractとして利用する。

Frontendで同じAPI DTOを再定義しない。

ただしForm Model / View Modelは必要に応じて別途定義できる。

---

## 32. Frontend Model方針

Frontendでは、

```text id="qq8t0h"
API DTO
+
View Model
+
UI State
```

を基本とする。

Backendの、

```text id="kg98bj"
Aggregate
Entity
Value Object
Domain Policy
```

をFrontendへ複製しない。

---

## 33. View Model

Presentation上意味のある変換がある場合のみView Modelを利用する。

例：

```text id="jb9mvt"
Date Formatting
Label Mapping
Status Presentation
Table Row
Grouping
```

単なるDTO Copyは作らない。

---

## 34. Mapper

DTO → View Model変換が意味を持つ場合のみMapperを配置する。

```text id="cz8dnv"
features/<feature>/mappers/
```

Business RuleをMapperへ置かない。

---

## 35. State Management

Stateは以下の優先順位で扱う。

```text id="md4qt6"
1. Server State
2. URL State
3. Form State
4. Local UI State
5. Context
6. Global State Library
```

まず「Stateとして持たなくてよいか」を検討する。

---

## 36. Server State

以下はServer Stateとする。

```text id="w90bdg"
Employee
Skill
SkillCategory
Department
EmployeeSkill
User
Permission
Assignment
```

Laravel API / PostgreSQLをSource of Truthとする。

---

## 37. URL State

以下はURL Stateを優先する。

```text id="bvv0k0"
Search
Filter
Sort
Pagination
Navigationに意味のあるTab
```

例：

```text id="hy1aqv"
/employees?keyword=php&department=3&page=2
```

---

## 38. Form State

Form StateはFeature / Form Scopeへ閉じ込める。

```text id="r9xk1e"
Input
Touched
Dirty
Field Error
Submitting
```

Global Storeへ置かない。

---

## 39. Local UI State

以下は最も近いClient Componentが所有する。

```text id="t4dxwr"
Dialog
Dropdown
Accordion
Popover
Temporary Selection
Preview
```

---

## 40. Context

ContextはClient Tree内で本当に共有が必要なStateだけに利用する。

Server StateやAuth.js Sessionを独自Contextへ複製しない。

---

## 41. Global State Library

Redux / Zustand等はMVPでは採用しない。

以下が明確になった場合に再検討する。

```text id="p1qzws"
多数の離れたClient Component間共有
RouteをまたぐClient State
複雑なClient Workflow
ContextのScale問題
```

---

## 42. Client Server-State Library

TanStack Query / SWR等はMVPでは採用しない。

以下が増えた場合に再検討する。

```text id="ic4qry"
Polling
Background Refetch
Infinite Scroll
Client Cache
Optimistic Update
複雑なRetry
```

---

## 43. Validation全体像

```text id="r25efn"
Browser
 ↓
Form State
 ↓
Frontend Schema Validation
 ↓
Server Action
 ↓
Server-side Validation / Normalization
 ↓
Laravel API
 ↓
Laravel Request Validation
 ↓
Laravel Domain
```

---

## 44. Validation責務

```text id="ux5gh4"
Frontend Validation
=
UX / Input Assistance

Laravel Request Validation
=
Request Correctness

Laravel Domain
=
Business Correctness
```

Frontend ValidationをSecurity Boundaryにはしない。

---

## 45. Frontend Schema

Frontend SchemaはFeature内へ配置する。

```text id="vy57cm"
features/<feature>/schemas/
```

Zod等を候補とする。

SchemaはFrontend UX / Parsing用であり、OpenAPI Schemaの機械的複製ではない。

---

## 46. Form Model

Form ModelとAPI Request DTOが異なることを許可する。

```text id="u648rs"
Form State
 ↓
Validation
 ↓
Normalization
 ↓
API Request DTO
```

とする。

---

## 47. Server ActionのValidation

Client-side Validationが存在しても、Server Actionで必ず再Validationする。

`FormData`をUntrusted Inputとして扱う。

---

## 48. EmployeeSkill UX Rule

Frontendでは以下をUXとして反映する。

```text id="d78xtp"
未経験
→ Level 1のみ

未経験
→ Experience Period不要

未経験
→ Last Used不要

実務経験あり
→ Experience Period必須

実務経験あり
→ Last Used必須
```

ただし最終InvariantはLaravel Domainで保証する。

---

## 49. Error Handling

Errorを大きく以下へ分ける。

```text id="pdl6gz"
Expected Error
Unexpected Error
```

Expected ErrorはApplication Flowとして処理する。

Unexpected ErrorはError Boundary + Loggingへ流す。

---

## 50. HTTP Error Mapping

```text id="d4p3r9"
400
→ Bad Request / Contract Error

401
→ Authentication

403
→ Authorization

404
→ Not Found

409
→ Conflict

422
→ Validation

429
→ Rate Limit

5xx
→ Backend / Infrastructure
```

Status Semanticを維持する。

---

## 51. Error Normalization

```text id="e6d4yd"
Laravel Error
      ↓
Generated Client / Transport Error
      ↓
lib/api/errors.ts
      ↓
Frontend ApiError
```

Transport固有ErrorをFeatureへ漏らさない。

---

## 52. Application Error Code

可能な場合、

```text id="djm4lm"
EMPLOYEE_NOT_FOUND
PERMISSION_DENIED
EMPLOYEE_SKILL_CONFLICT
VALIDATION_FAILED
```

等のStable Error Codeを利用する。

Raw Message StringでControl Flowを分岐しない。

---

## 53. Error UI

用途ごとに使い分ける。

```text id="cl0s59"
Field Error
Inline Error
Forbidden UI
Not Found
Conflict UI
Error Boundary
Global Error
```

すべてをToastやGeneric Errorへ変換しない。

---

## 54. Error Boundary

```text id="2yct9c"
error.tsx
=
Route Segment Unexpected Error

global-error.tsx
=
Application-level Unexpected Error

not-found.tsx
=
Not Found
```

として利用する。

---

## 55. Retry

Mutationへ無条件Retryを行わない。

ReadについてのみTransient Failure時にBounded Retryを検討できる。

```text id="c00vmk"
400 / 401 / 403 / 404 / 409 / 422
→ 原則Retryしない
```

---

## 56. Cache基本方針

```text id="a5ghqp"
Default
=
Dynamic / Fresh Data

Cache
=
明確なBenefitがあるReadのみOpt-in
```

LaravelをSource of Truthとする。

---

## 57. Cacheの責務

```text id="4o434a"
Laravel
=
Business Data Source of Truth

Next.js Cache
=
Performance Optimization
```

CacheをAuthorization / Business CorrectnessのAuthorityにはしない。

---

## 58. MVP Cache Strategy

MVPでは以下を基本Dynamicとする。

```text id="oo9suf"
Employee
EmployeeSkill
Permission
Assignment
Skill
SkillCategory
Department
```

まずFreshnessと単純性を優先する。

---

## 59. Cache候補

Performance Measurement後、最初の候補は比較的StableなMaster Dataとする。

```text id="kfii14"
SkillCategory
Skill Master
Department
```

Cache導入時はInvalidation Strategyも同時に設計する。

---

## 60. Cache Security

User / Permissionに依存するDataを安全性確認なしで共有Cacheへ入れない。

以下をCache Key / Cache Dataへ利用しない。

```text id="pafcvo"
Sanctum Token
Session Token
Cookie
Authorization Header
Secret
Credential
```

---

## 61. Cache Invalidation

```text id="86ydh8"
Mutation
 ↓
Laravel Success
 ↓
Affected CacheのみInvalidate / Revalidate
 ↓
Fresh Read
```

Laravel Success前にInvalidationしない。

---

## 62. Cache Invalidation責務

API ClientではなくFeature Action / Mutation BoundaryがAffected Cacheを判断する。

```text id="rc51j0"
Feature Action
 ↓
API Client
 ↓
Laravel Success
 ↓
Cache Invalidation
```

---

## 63. Cache API

Next.jsの、

```text id="flr5y4"
use cache
revalidatePath
revalidateTag
updateTag
```

等は利用候補とする。

具体的Semanticは採用Next.js Versionの公式仕様に従う。

---

## 64. UI Architecture

UIを以下の3種類へ分類する。

```text id="7xla4n"
App-level UI
Feature UI
Shared UI
```

---

## 65. Feature UI

Feature固有UIは以下へ配置する。

```text id="xgxu4c"
features/<feature>/components/
```

例：

```text id="621ig9"
EmployeeTable
EmployeeForm
SkillSelector
PermissionMatrix
```

---

## 66. Shared UI

Feature非依存UIは以下へ配置する。

```text id="ewz63l"
components/ui/
```

例：

```text id="jm445a"
Button
Input
Select
Dialog
Table
Badge
Alert
Pagination
```

---

## 67. Shared UI Rule

Shared UIは以下を知らない。

```text id="me587j"
Employee
Skill
Permission
Laravel API
Feature State
```

Generic Presentationへ限定する。

---

## 68. Layout UI

Application Layoutは以下へ配置する。

```text id="b420b7"
components/layout/
```

例：

```text id="6pxfjr"
Header
Sidebar
PageContainer
PageHeader
```

---

## 69. UI Composition

```text id="748nc0"
app
 ↓
Feature Component
 ↓
Shared UI
```

を基本とする。

Feature間の横断Compositionは`app/`で行う。

---

## 70. Table Strategy

Generic Table PrimitiveとFeature Tableを分離する。

```text id="ncr8hu"
components/ui/table
        ↓
features/employees/employee-table
```

Search / Filter / Sort / PaginationはURL Stateへ置く。

Server-side Paginationを基本とする。

---

## 71. Form UI

Generic Input等はShared UI、Employee Form等はFeature UIへ置く。

```text id="2iqfuh"
Shared Form Primitive
        ↓
Feature Form
        ↓
Server Action
```

---

## 72. Dialog

Generic Dialog PrimitiveはShared UIとする。

Feature固有DialogはFeature内へ置く。

複雑な主要WorkflowをModalへ詰め込まない。

---

## 73. Accessibility

AccessibilityをArchitecture上の標準Requirementとする。

```text id="683z5q"
Semantic HTML
Keyboard Navigation
Focus
ARIA
Label
Screen Reader
Contrast
Error Association
```

---

## 74. Button / Link

```text id="jz6c66"
Action
→ Button

Navigation
→ Link
```

とし、Semanticを守る。

---

## 75. UI Library

Accessible Primitiveを自前で一から作らず、既存Libraryを利用候補とする。

shadcn/ui等を有力候補とするが、正式採用は実装開始時の現行Version / Maintenance状況を確認して決定する。

---

## 76. Design System

MVPでは巨大な独自Design Systemを構築しない。

```text id="s18lnk"
Consistent UI Primitive
+
Reusable Pattern
```

程度を目標とする。

---

## 77. Styling

Styling方式はApplication全体で統一する。

Featureごとに複数Styling方式を混在させない。

Tailwind CSS等を候補とする。

---

## 78. Loading / Empty / Error / Pending

以下を明確に区別する。

```text id="uktruw"
Loading
Empty
Error
Pending
```

Empty StateをErrorとして扱わない。

Mutation中は局所的Pending UIを基本とする。

---

## 79. Testing全体方針

Testを以下へ分類する。

```text id="a4q69r"
Static Analysis
Unit Test
Component Test
Integration Test
Contract Test
E2E Test
```

FastでFocusedなTestを中心にし、E2EをCritical Flowへ限定する。

---

## 80. Static Analysis

以下をQuality Gateとして利用する。

```text id="nz0bof"
TypeScript
ESLint
Import Boundary
Circular Dependency Check
Generated Code Drift
Production Build
```

---

## 81. Unit Test

Pure Logicを中心にTestする。

```text id="9vwnh6"
Formatter
Mapper
Schema
Permission Helper
Utility
Query Parameter Conversion
```

単純なFramework Wrapper等を機械的にTestしない。

---

## 82. Component Test

User-visible Behaviorを中心にTestする。

```text id="ub3jbx"
Form Interaction
Dialog
Table
Permissionによる表示差
Validation Error
Empty State
Accessibility
```

Implementation Detailを中心にしない。

---

## 83. Integration Test

Frontend Module間のBoundaryを確認する。

```text id="wpg7ip"
Server Query
+
API Client

Server Action
+
Validation
+
API Client

Route Handler
+
API Client
```

---

## 84. Contract Test

OpenAPIを中心にFrontend / Laravel Contractを保証する。

```text id="57mc0o"
OpenAPI
 ↓
Laravel
+
Generated Frontend Client
```

CIでGenerated Code Driftを検出する。

---

## 85. E2E

Critical User Flowへ集中する。

主な候補：

```text id="ciwrto"
Login / Logout
Employee一覧
Employee登録 / 編集
EmployeeSkill登録 / 更新
Skill Master管理
Permission管理
Authorization
```

---

## 86. Critical Flow

最優先Flow：

```text id="5epcue"
Login
 ↓
Employee Search
 ↓
Employee Detail
 ↓
EmployeeSkill登録 / 更新
```

本ApplicationのCore Use Caseとして重点的に保証する。

---

## 87. E2E Environment

重要E2Eでは可能な限り、

```text id="f5u26l"
Browser
 ↓
Next.js
 ↓
Laravel
 ↓
PostgreSQL
```

を実際に組み合わせる。

Docker方針とTest Environmentを整合させる。

---

## 88. Frontend / Backend Test責務

```text id="1o61zf"
Frontend Test
=
UX Behavior

Laravel Test
=
Business Correctness
Authorization
Domain Invariant
```

同じRuleを意味なくすべてのLevelで重複Testしない。

---

## 89. CI Pipeline

基本Flow：

```text id="1gziwd"
Install
 ↓
Generated Code Check
 ↓
Format
 ↓
Lint
 ↓
Type Check
 ↓
Unit / Component / Integration
 ↓
Production Build
 ↓
Critical E2E
```

必要に応じてParallel化する。

---

## 90. Production Build

Production Build成功をFrontend Quality Gateとする。

特に以下を確認する。

```text id="7g8pl4"
Server / Client Boundary
Caching
Rendering
Environment Variable
Build-time Error
```

---

## 91. Server-only Security

以下をClient Bundleへ流さない。

```text id="6hltr0"
Sanctum Token
Auth Secret
Internal Credential
Private API Configuration
```

`server-only` / Build / Static Analysisを利用して防御する。

---

## 92. Logging / Observability

Frontend Server-sideでは必要に応じて以下を記録する。

```text id="02ch9m"
Request ID
Trace ID
User ID
Route
Operation
Status
Error Code
Duration
```

以下を記録しない。

```text id="a56vf2"
Password
Session Token
Sanctum Token
Cookie
Authorization Header
Secret
Sensitive Form Data
```

---

## 93. Request ID

可能な限り、

```text id="dethpn"
Browser
 ↓
Next.js
 ↓
Laravel
```

のRequest / Trace Contextを追跡可能にする。

具体的Observability Toolは別途Infrastructure設計に従う。

---

## 94. Performance Strategy

Performance問題では以下の順で検討する。

```text id="h7ezwe"
1. Query / API改善
2. Fetch回数削減
3. Parallel Fetch
4. Next.js Cache
5. Laravel Cache
6. Dedicated Cache Infrastructure
```

Cacheを最初の対策にしない。

---

## 95. Over-engineeringを抑える対象

MVPでは以下を採用しない。

```text id="m3037n"
Frontend DDD Model
Frontend Repository Pattern
Frontend CQRS Framework
Global Redux / Zustand
Full Client Server-state Cache
Huge Design System
Huge Cache Framework
Huge Form Framework
Universal API Proxy
Premature Storybook Infrastructure
Premature Redis Cache
```

必要性が明確になった時点で再評価する。

---

## 96. 採用しないFrontend Repository Pattern

FrontendでBackend Repository Patternを再現しない。

```text id="b5z4c8"
Feature
 ↓
Repository
 ↓
API
```

ではなく、

```text id="trn8xr"
Feature Server Query / Action
 ↓
API Client
 ↓
Generated Client
```

を利用する。

---

## 97. Frontend CQRSの扱い

Command / QueryをArchitecture FrameworkとしてFrontendへ導入しない。

ただしRead / Mutationの役割は明確に分ける。

```text id="exwppo"
Read
→ Server Query

Mutation
→ Server Action
```

これはLightweightな責務分離でありFull CQRSではない。

---

## 98. BFFの責務

BFFで許可する処理：

```text id="uh6wem"
Authentication
API Aggregation
Request Adaptation
Response Adaptation
Frontend-specific Transformation
Frontend-specific Orchestration
```

BFFで禁止するBusiness Rule：

```text id="3ee0xl"
EmployeeSkill Invariant
Permission管理者最低1人Rule
Skill Deactivation Rule
退職Employee保持Rule
```

---

## 99. Security全体像

```text id="n6z5yk"
Proxy
=
未認証Userを粗く止める

Next.js Authorization
=
できない操作を見せない

Server Boundary
=
Client入力を信用しない

Laravel Authorization
=
できない操作を実行させない

Laravel Domain
=
Business Invariantを破らせない
```

---

## 100. Data Flow全体像

### Read

```text id="fdqn8g"
URL
 ↓
Server Component
 ↓
Feature Server Query
 ↓
API Client
 ↓
Laravel
 ↓
DTO
 ↓
View Model
 ↓
UI
```

### Mutation

```text id="5xa9u6"
Form / UI
 ↓
Client-side UX Validation
 ↓
Server Action
 ↓
Server-side Validation
 ↓
Normalization
 ↓
API Client
 ↓
Laravel
 ↓
Mutation Success
 ↓
Affected Revalidation
 ↓
Fresh UI
```

---

## 101. Authentication Flow

```text id="0rjn8f"
Browser
 ↓
Auth.js Session
 ↓
Next.js Server
 ↓
Sanctum Token
 ↓
Laravel
```

TokenをBrowserへ返さない。

---

## 102. Authorization Flow

```text id="5p1o7m"
Route Access
 ↓
Authentication Check
 ↓
Frontend Capability Check
 ↓
Server Boundary
 ↓
Laravel Authorization
 ↓
Domain / Application Processing
```

---

## 103. Error Flow

```text id="yrgf51"
Laravel
 ↓
API Error Contract
 ↓
Generated Client
 ↓
lib/api/errors
 ↓
Expected Error?
   │
   ├── Yes
   │    ↓
   │ Feature / Action / Pageで処理
   │
   └── No
        ↓
   Error Boundary + Logging
```

---

## 104. Cache Flow

```text id="4rm39s"
Read
 ↓
Cache必要性あり？
   │
   ├── No
   │    ↓
   │ Dynamic
   │
   └── Yes
        ↓
   Scope / Freshness / Invalidation確認
        ↓
      Cache
```

Mutation時：

```text id="0xzlxy"
Laravel Success
 ↓
Affected Cached Data?
   │
   ├── No
   │    ↓
   │ Nothing
   │
   └── Yes
        ↓
   Invalidate / Revalidate
```

---

## 105. State Flow

```text id="8iairv"
Stateが必要
 ↓
Backend Data？
→ Server State

URLで表現可能？
→ URL State

Form Editing？
→ Form State

局所Interaction？
→ Local UI State

Tree内共有？
→ Context

Application-wide Complex Client State？
→ Global Library検討
```

---

## 106. UI Placement判断

```text id="48hpu6"
UI
 ↓
Feature固有？
   │
   ├── Yes
   │    ↓
   │ features/<feature>/components
   │
   └── No
        ↓
Application Layout？
   │
   ├── Yes
   │    ↓
   │ components/layout
   │
   └── No
        ↓
Generic Reusable UI？
   │
   ├── Yes
   │    ↓
   │ components/ui
   │
   └── No
        ↓
   使用箇所の近く
```

---

## 107. Final Directory Image

```text id="27ddls"
src/
├── app/
│   ├── (auth)/
│   ├── (dashboard)/
│   ├── api/
│   ├── error.tsx
│   ├── global-error.tsx
│   ├── layout.tsx
│   ├── loading.tsx
│   └── not-found.tsx
│
├── features/
│   ├── employees/
│   │   ├── components/
│   │   ├── server/
│   │   ├── actions/
│   │   ├── schemas/
│   │   ├── mappers/
│   │   ├── types/
│   │   └── index.ts
│   │
│   ├── skills/
│   ├── skill-categories/
│   └── access-control/
│
├── components/
│   ├── ui/
│   └── layout/
│
├── lib/
│   ├── api/
│   │   ├── generated/
│   │   ├── client.ts
│   │   ├── errors.ts
│   │   └── index.ts
│   ├── auth/
│   ├── cache/
│   ├── validation/
│   ├── navigation/
│   └── utils/
│
├── types/
└── styles/
```

Directoryは必要性が発生したものだけ作成する。

---

## 108. Architecture Decision Summary

Frontend Architectureとして以下を正式採用する。

### Architecture

- Next.js App Routerを利用する
- Next.jsをFrontend + BFFとして利用する
- Server Component Firstを採用する
- Feature-based Architectureを採用する
- BackendのClean Architecture / DDD LayerをFrontendへ複製しない
- FrontendをFeature-oriented、BackendをDomain-orientedとする
- Business CorrectnessはLaravel Application / Domainが所有する
- BrowserからLaravel APIへの直接Accessを禁止する
- BFFへBusiness Ruleを持ち込まない

### Server / Client

- Server ComponentをDefaultとする
- Client Componentを必要最小限とする
- `"use client"` Boundaryを小さく保つ
- Server ReadはServer Query経由でLaravel APIへAccessする
- Server ComponentからRoute Handlerを経由しない
- MutationはServer Actionを第一候補とする
- Client-side Readが必要な場合はRoute Handlerを利用する
- Route HandlerをUniversal Proxyとして利用しない

### Dependency

- Dependencyを`app → features → shared`の方向にする
- Shared LayerからFeatureへ依存しない
- Featureから`app/`へ依存しない
- Feature間の内部依存を原則禁止する
- Feature横断Compositionを`app/`で行う
- Circular Dependencyを禁止する
- Type Dependencyにも同じRuleを適用する
- Server-only CodeをClientへ流さない

### API / OpenAPI

- OpenAPI Firstを採用する
- OpenAPIをLaravel API ContractのSource of Truthとする
- TypeScript Client / TypesをOpenAPIから生成する
- Generated Codeを手動編集しない
- Generated CodeとHandwritten Codeを分離する
- Common API Clientを利用する
- Raw `fetch`をFeatureへ散在させない
- Sanctum Token InjectionをAPI Clientへ集約する
- API DTOをFrontendで重複定義しない
- DTO / View Model / UI Stateを用途に応じて分離する
- Frontend DDD Modelを構築しない

### Authentication / Authorization

- Browser ↔ Next.jsはAuth.js Sessionを利用する
- Next.js ↔ LaravelはSanctum Tokenを利用する
- Sanctum TokenをServer-onlyとする
- Auth.js SessionをFrontend Authentication Source of Truthとする
- Frontend独自Auth Storeを作らない
- Frontend AuthorizationをUX / Early Rejectionとする
- Laravel AuthorizationをSecurity Authorityとする
- Permission管理最低1人等のInvariantをLaravelで保証する
- Session CapabilityをSecurity Authorityとしない

### State

- State PriorityをServer → URL → Form → Local → Context → Globalとする
- Business DataをServer Stateとする
- Search / Filter / Sort / PaginationをURL Stateとする
- Form StateをForm Scopeへ閉じ込める
- UI Stateを最も近いClient Componentが所有する
- Auth.js Sessionを独自Stateへ複製しない
- Redux / ZustandをMVPでは採用しない
- TanStack Query / SWRをMVPでは採用しない
- Requirement発生時に段階的に再検討する

### Validation

- Frontend ValidationをUX / Input Assistanceとする
- Server Actionで必ず再Validationする
- Laravel Request ValidationをAPI Input Correctnessとする
- Laravel DomainをBusiness Invariant Authorityとする
- Frontend Form SchemaをOpenAPI Schemaと同一視しない
- Form ModelとAPI Request DTOの差異を許可する
- FormDataをUntrusted Inputとして扱う
- EmployeeSkill RuleをFrontend UXへ反映しつつBackendで最終保証する

### Error

- Expected / Unexpected Errorを分離する
- HTTP Status Semanticを維持する
- API Errorを`lib/api/errors.ts`でNormalizeする
- Raw Error MessageをControl Flowへ利用しない
- Application Error Codeを利用候補とする
- Validation / Forbidden / Not Found / Conflict / System Errorを分離する
- Unexpected ErrorをError Boundaryへ流す
- Mutationへ無条件Retryを行わない
- Sensitive Error DetailをUser / Logへ漏らさない

### Cache

- Dynamic / Fresh DataをDefaultとする
- CacheをOpt-inとする
- CacheをBusiness Correctness / Authorization Authorityにしない
- MVPでは主要Business DataをDynamicとする
- Stable Master Dataを最初のCache候補とする
- User / Permission Scopeを無視した共有Cacheを禁止する
- CredentialをCacheへ保存しない
- Mutation成功後のみAffected CacheをInvalidateする
- API ClientへInvalidation責務を持たせない
- Feature ActionがAffected Cacheを判断する
- Exact Next.js Cache API Semanticは採用Versionの公式仕様に従う

### UI

- UIをApp-level / Feature / Sharedへ分類する
- Feature固有UIをFeature内へ配置する
- Generic UIを`components/ui/`へ配置する
- Layout UIを`components/layout/`へ配置する
- Shared UIをFeature Conceptから独立させる
- Shared化を急がない
- Server ComponentをUIでもDefaultとする
- Accessibilityを標準Requirementとする
- Generic TableとFeature Tableを分離する
- Server-side Paginationを基本とする
- Generic Form PrimitiveとFeature Formを分離する
- Dialogを軽量Interactionへ利用する
- 主要編集WorkflowはPageを基本とする
- 巨大な独自Design SystemをMVPでは構築しない
- UI Library / Styling方式をApplication全体で統一する

### Testing

- Static / Unit / Component / Integration / Contract / E2EへTest責務を分離する
- User-visible BehaviorをTestの中心とする
- Implementation Detail Testを避ける
- TypeScript / ESLintをQuality Gateとする
- OpenAPI Generated Code DriftをCIで検出する
- Pure LogicをUnit Testする
- Interactive UIをComponent Testする
- Server BoundaryをIntegration Testする
- OpenAPI ContractをContract Testで保証する
- Critical User FlowをE2Eで保証する
- Browser → Next.js → Laravel → PostgreSQLの実E2Eを重要Flowで行う
- Laravel TestでBusiness Correctness / Authorization / Domain Invariantを保証する
- Coverage Percentage自体を目的化しない
- Production Build成功をCI Quality Gateとする

---

## 109. 最終Architecture原則

本Frontend Architectureでは、以下を最重要原則とする。

```text id="vp09io"
Render on Server by Default

Interact on Client only when necessary

Organize by Feature

Keep Shared truly Shared

Keep Browser away from Laravel Credentials

Use OpenAPI as Contract

Keep Business Correctness in Laravel

Keep State close to its Source of Truth

Treat Cache as Optimization

Treat Frontend Authorization as UX

Treat Laravel Authorization as Security

Test Behavior, not Implementation
```

---

## 110. 最終結論

本ProjectのFrontend Architectureを以下で確定する。

```text id="ztaija"
Next.js App Router
        +
Server Component First
        +
Feature-based Architecture
        +
Next.js BFF
        +
Auth.js
        +
Laravel Sanctum
        +
OpenAPI First
        +
Generated API Client
        +
Minimal Client State
        +
Dynamic-first Cache Strategy
        +
Behavior-oriented Testing
```

FrontendはUI / UX / BFF / Presentationへ集中し、Business Correctness・Authorization・InvariantはLaravelへ集約する。

これにより、

```text id="h8a5tz"
Frontend
=
変更しやすいPresentation Layer

Laravel
=
安定したBusiness Core
```

という責務分離を維持する。

以上を本ProjectのFrontend Architecture最終決定版とする。
