# API Client・OpenAPI

## 1. 目的

本ドキュメントでは、Frontend / BFFからLaravel Backend APIへアクセスするためのAPI Client、およびOpenAPIを利用したTypeScript型・Client Code生成の技術選定と運用方針を定義する。

対象：

- OpenAPI Code Generation
- TypeScript型生成
- API Client生成
- HTTP Transport
- TanStack Query連携
- Server-side API Access
- Error Handling
- Runtime Validation
- Generated Code管理
- Code Generation Workflow

API Contractそのものの管理方針については `07_API・OpenAPI.md`、Frontend Architecture上の配置・依存方向についてはFrontend Architectureドキュメントに従う。

---

# 2. 基本方針

API ContractのSource of TruthにはOpenAPIを利用する。

Frontend側でBackend APIのRequest / Response TypeやAPI Clientを重複して手書きしない。

基本構成：

    OpenAPI
       ↓
      Orval
       ↓
    TypeScript Types
       +
    API Client
       ↓
    Next.js / BFF
       ↓
    Laravel API

以下を基本原則とする。

- OpenAPI First
- API ContractはOpenAPIをSource of Truthとする
- TypeScript型をOpenAPIから生成する
- API ClientをOpenAPIから生成する
- HTTP TransportはFetch APIへ統一する
- Client-side Server StateにはTanStack Queryを利用する
- Server-sideではGenerated Request Functionを利用する
- Generated Codeは手動編集しない
- Application固有LogicをGenerated Codeへ持たせない
- SchemaやDTOの二重管理を避ける
- BrowserからLaravel APIを直接呼び出さない

---

# 3. OpenAPI Code Generator

## 3.1 候補

候補：

- Orval
- Hey API
- openapi-typescript
- OpenAPI Generator

本プロジェクトでは **Orval** を採用する。

---

## 3.2 Orval

Orvalを利用してOpenAPIからFrontend向けCodeを生成する。

主な生成対象：

- TypeScript Types
- API Request Functions
- Fetch API Client
- TanStack Query Query Functions
- Query Keys
- Query Hooks
- Mutation Hooks

基本：

    OpenAPI
       ↓
      Orval
       ↓
    Generated Types
       +
    Generated API Client

---

## 3.3 採用理由

Orvalを採用する主な理由：

- OpenAPI Firstとの親和性
- TypeScript型生成
- API Client生成
- Fetch API対応
- TanStack Query Integration
- Query Key生成
- Query / Mutation Hook生成
- Next.jsとの親和性
- Frontend API Boilerplate削減

Type GenerationとAPI Client Generationを
複数Toolへ分散させず、Orvalへ集約する。

---

## 3.4 HTTP Transport

HTTP TransportにはFetch APIを利用する。

Axiosは採用しない。

    Orval
      ↓
    Fetch API
      ↓
    Laravel API

---

## 3.5 Client-side

Client-sideではOrvalのTanStack Query Integrationを利用する。

    Orval
      ↓
    TanStack Query Integration
      ↓
    TanStack Query

---

## 3.6 Server-side

Server-sideではTanStack Query Hookへ依存せず、
Generated Request Functionを利用する。

    Server Component / BFF
            ↓
    Generated Request Function
            ↓
         Fetch API

---

## 3.7 不採用候補

### Hey API

型安全なSDKやTanStack Query連携など、
本プロジェクトに適した機能を持つ。

ただしMVPではGeneratorをOrvalへ統一するため採用しない。

将来的な再評価候補とする。

### openapi-typescript

軽量でTypeScriptとの親和性が高いが、
本プロジェクトではType Generationだけでなく、

- Request Function
- TanStack Query Integration
- Query Key
- Mutation Hook

までまとめて生成するためOrvalを優先する。

### OpenAPI Generator

多言語・多Platformへ対応する汎用Generatorである。

本プロジェクトのFrontend TypeScript用途では、
Orvalの方が目的に特化しているため採用しない。

---

# 4. TypeScript型生成

## 4.1 基本方針

API Boundaryで利用するTypeScript型は、
OpenAPIからOrvalで生成する。

    OpenAPI
       ↓
      Orval
       ↓
    Generated Types
       ↓
    API Boundary

Frontend側で同一Contractを手書きしない。

---

## 4.2 生成対象

主に以下を生成する。

- Request Body
- Response Body
- Path Parameters
- Query Parameters
- Header Parameters
- Error Responses
- Enums
- Nested Schema
- Nullable / Optional Fields

---

## 4.3 DTOの重複禁止

以下のような重複を避ける。

    OpenAPI EmployeeResponse
             +
    手書き EmployeeResponse interface

API DTOについてはGenerated Typeを利用する。

---

## 4.4 Frontend Model

Generated TypeはAPI Boundaryの表現であり、
必ずしもFrontend内部Modelと同一とは限らない。

必要な場合のみ、

    EmployeeResponse
          ↓
        Mapper
          ↓
    EmployeeViewModel

のように変換する。

ただし、
すべてのDTOにFrontend Model / Mapperを作らない。

以下の場合のみ検討する。

- API ResponseとUIの形が大きく異なる
- 複数Responseを統合する
- Derived Valueが必要
- Date変換が必要
- API NamingをUIから分離したい
- API変更の影響を局所化したい

MVPでは必要な箇所だけ変換する。

---

## 4.5 Request Type

Create / Update Requestについても
OpenAPI Generated Typeを利用する。

手書きRequest DTOを重複定義しない。

---

## 4.6 Form State

Form StateとAPI Request Typeは分離する。

    Form State
        ↓
    Validation
        ↓
    Transform
        ↓
    Generated Request Type
        ↓
    API Client

Formでは、

- Input中のString
- 未入力状態
- Confirm Field
- UI専用Field

などが存在するため、
API Request TypeをそのままForm Stateとして強制しない。

---

## 4.7 Enum

API EnumはOpenAPIから生成する。

同じEnum ValueをFrontendで重複定義しない。

UI LabelはFrontend側で管理する。

例えば、

    ACTIVE
      ↓
    "在籍"

とする。

---

## 4.8 Nullable / Optional

OpenAPIの、

- required
- optional
- nullable

を正確にTypeScript型へ反映する。

`undefined` / `null` / 値ありを
Frontend側で曖昧に扱わない。

---

## 4.9 Date / DateTime

HTTP Boundary上のDate / DateTimeは
基本的にStringとして扱う。

例えば、

    2026-09-11

    2026-09-11T10:30:00+09:00

などである。

自動的にJavaScript `Date` へ変換せず、
必要なBoundaryで明示的にParse / Formatする。

---

## 4.10 Generated Code

Generated Typeは手動編集しない。

変更が必要な場合は、

    OpenAPI
       ↓
    Orval Config
       ↓
    Regenerate

で対応する。

---

# 5. API Client生成

## 5.1 基本方針

Laravel Backend APIへアクセスするAPI Clientは、
OpenAPIからOrvalで生成する。

EndpointごとのRequest Functionを
大量に手書きしない。

    OpenAPI
       ↓
      Orval
       ↓
    Generated API Client
       ↓
     Fetch API
       ↓
    Laravel API

Generated API Clientは、
API Contractに対応するHTTP Access Layerとして扱う。

---

## 5.2 生成対象

主に以下を生成する。

- Endpoint Request Function
- Request Parameter Type
- Request Body Type
- Response Type
- Error Response Type
- Path Parameter処理
- Query Parameter処理
- HTTP Method
- URL構築

---

## 5.3 Generated Clientの責務

責務：

- HTTP Request生成
- URL構築
- Parameter設定
- Request Body送信
- Response受信
- OpenAPIに基づく型付け

責務外：

- UI State
- Navigation
- Toast
- Business Rule
- Form State
- Application Workflow

Generated ClientをApplication Serviceの代わりにしない。

---

## 5.4 Common Fetch Layer

Generated Clientから利用するFetch処理について、
必要な共通処理をCommon Fetch Layerへ配置する。

主な候補：

- Base URL
- Authentication Header
- Common Header
- Credentials
- Error Normalization
- Request ID
- Trace Context
- Timeout
- Abort Signal

Generated Codeそのものを直接編集しない。

---

## 5.5 Authentication

Laravel APIへのAuthentication情報付与は、
共通処理として管理する。

EndpointごとにAuthentication処理を重複させない。

詳細は `05_認証方式.md` に従う。

---

## 5.6 Base URL

Laravel API Base URLを
Request Functionへ直接記述しない。

Development / Staging / Productionごとの差は
Configurationとして管理する。

Generated CodeへEnvironment固有URLを埋め込まない。

---

## 5.7 Wrapper

Generated Functionへ
無条件にWrapper Functionを作らない。

Wrapperは以下の場合のみ検討する。

- 複数Endpointを組み合わせる
- Response変換
- Application固有Parameter変換
- Application Workflow
- API ContractをUIから明確に分離する必要がある

単純なPass-through Wrapperは作らない。

---

## 5.8 operationId

Frontend利用対象Endpointには
明示的で安定した `operationId` を定義する。

例えば、

    getEmployees
    getEmployee
    createEmployee
    updateEmployee
    deleteEmployee

とする。

Framework実装に依存した命名を避ける。

---

# 6. TanStack Queryとの関係

## 6.1 基本方針

Client-side Server StateにはTanStack Queryを利用する。

OrvalのTanStack Query Integrationを有効にする。

    OpenAPI
       ↓
      Orval
       ↓
    Generated Query Function
       +
    Generated Query Key
       +
    Generated Hook
       ↓
    TanStack Query

---

## 6.2 生成対象

主に以下を生成する。

- Query Function
- Query Key
- `useQuery`
- `useMutation`
- 必要に応じて `useInfiniteQuery`
- Prefetch関連Helper

---

## 6.3 Query Hook

通常のClient-side Read処理では、
Generated Query Hookを利用できる。

同じQuery Function / Query Keyを
Application側で毎回手書きしない。

---

## 6.4 Mutation Hook

Create / Update / Deleteについても、
Generated Mutation Hookを利用する。

Mutation後のCache Invalidationは
Application側で管理する。

---

## 6.5 Invalidation

どのQueryをInvalidationするかは
Application固有の知識として扱う。

    Mutation
       ↓
    Generated Mutation Hook
       ↓
    onSuccess
       ↓
    Application-defined Invalidation

Generatorへ過度に持たせない。

---

## 6.6 Query Key

同じEndpointでは
Orval Generated Query Keyを可能な限り利用する。

独自Query Key体系を重複定義しない。

複数Endpointを合成したApplication固有Queryについては、
Frontend側で独自Keyを定義できる。

---

## 6.7 Application固有Query

OpenAPI Endpointと1対1で対応しないQueryは、
Application側で定義する。

例えば、

- 複数API Responseの合成
- Derived Data
- Fetch Sequence
- 複数Resourceの統合

などである。

---

## 6.8 Query Option

以下のOptionはUse Caseに応じて調整する。

- `staleTime`
- `gcTime`
- `enabled`
- `retry`
- `refetchOnWindowFocus`
- `refetchOnReconnect`

Application全体で共通化できるもののみ
QueryClient Defaultへ設定する。

---

## 6.9 Wrapper Hook

単純なPass-through Hookは作らない。

Wrapper Hookは、

- 複数Query
- Application固有Option
- Data Transformation
- Error Handling
- Mutation Workflow

などが必要な場合のみ利用する。

---

## 6.10 Optimistic Update

Optimistic UpdateをDefaultとしない。

基本：

    Mutation
       ↓
    invalidateQueries

明確なUX上のメリットがあるUse Caseのみ
Optimistic Updateを検討する。

---

# 7. Server-sideとの関係

## 7.1 基本方針

Server Component / BFFからLaravel APIへアクセスする場合も、
Generated API Clientを利用する。

    Server Component / BFF
            ↓
    Generated API Client
            ↓
      Common Fetch Layer
            ↓
         Fetch API
            ↓
       Laravel API

---

## 7.2 Server Component

Server Componentでは
Generated Request Functionを直接利用する。

TanStack Query Hookは利用しない。

---

## 7.3 BFF

BrowserからLaravel APIを直接呼び出さず、
必要に応じてNext.jsをBFFとして利用する。

    Browser
       ↓
    Next.js
       ↓
    Laravel API

---

## 7.4 Route Handler

Client-side RequestでServer Boundaryが必要な場合は、
Route HandlerをBFF Endpointとして利用できる。

    Client Component
          ↓
    Next.js Route Handler
          ↓
    Generated API Client
          ↓
    Laravel API

---

## 7.5 不要なNetwork Hopを避ける

Server ComponentからLaravel APIへアクセスするためだけに、
Next.js Route Handlerを経由しない。

避ける：

    Server Component
          ↓
    Route Handler
          ↓
    Laravel API

基本：

    Server Component
          ↓
    Generated API Client
          ↓
    Laravel API

---

## 7.6 Authentication

Authentication CredentialはServer-sideで管理する。

    Better Auth Session
          ↓
      Next.js Server
          ↓
    Laravel API Authentication

Laravel Sanctum向けCredentialを
Local Storage等へ保存しない。

---

## 7.7 Cache

Server-side CacheはNext.js側で管理する。

Generated ClientへApplication固有Cache Policyを
過度に埋め込まない。

User / PermissionによってResponseが変わるDataは
共有Cacheを慎重に扱う。

安全性が不明な場合はCacheしない。

---

## 7.8 Hydration

Serverで取得したDataをClientでも
継続的にTanStack Queryで管理する必要がある場合のみ、
Prefetch / Hydrationを検討する。

すべてのServer DataをHydrationしない。

---

## 7.9 Server-only

以下はServer-sideへ限定する。

- Secret
- Laravel API Credential
- Internal API Base URL
- Sensitive Header

Client Bundleへ含めない。

---

# 8. Error Handling

## 8.1 基本方針

API Client ErrorをFrontendで
一貫して扱える形へ正規化する。

    Laravel API
         ↓
    HTTP Response
         ↓
    Common Fetch Layer
         ↓
    Error Normalization
         ↓
    Application / TanStack Query

ComponentごとにHTTP Responseを解析しない。

---

## 8.2 Error分類

主に以下へ分類する。

- API Error
- Validation Error
- Authentication Error
- Authorization Error
- Not Found
- Conflict
- Rate Limit
- Network Error
- Timeout
- Unexpected Error

HTTP Responseを取得できなかったErrorと
HTTP Error Responseを区別する。

---

## 8.3 Error Response

API Error Responseは
OpenAPIへSchemaとして定義する。

概念：

    ApiErrorResponse
    ├── code
    ├── message
    ├── errors
    └── requestId

具体的なSchemaはAPI Error設計に従う。

---

## 8.4 HTTP Status / Error Code

HTTP StatusとApplication Error Codeを分離する。

例えば、

    HTTP 409
       ↓
    ADMINISTRATOR_REQUIRED

HTTP StatusはProtocol-level classification、
Error CodeはApplication-level classificationとして扱う。

Message文字列からBusiness Errorを判定しない。

---

## 8.5 Validation Error

Validation ErrorはField単位で扱えるSchemaとする。

    Validation Error
        ↓
    Field Errors
        ↓
    Form

Form LibraryへMappingできる構成とする。

---

## 8.6 401 / 403

`401` と `403` を区別する。

    401
     ↓
    Authentication

    403
     ↓
    Authorization

Permission不足をAuthentication失敗として扱わない。

---

## 8.7 404 / 409 / 429 / 5xx

`404`：

Resource Not Foundとして扱う。

`409`：

Business Rule / State Conflictとして利用できる。

`429`：

Rate Limitとして扱い、
必要に応じて `Retry-After` 等を考慮する。

`5xx`：

Server Errorとして扱い、
内部実装情報をUserへ表示しない。

---

## 8.8 Network Error

HTTP Responseを取得できない場合は
Network Errorとして扱う。

HTTP Statusを持つAPI Errorと区別する。

---

## 8.9 Normalized Error

Frontend内部では
共通Error Typeへ正規化する。

概念：

    ApiClientError
    ├── kind
    ├── status
    ├── code
    ├── message
    ├── fieldErrors
    ├── requestId
    └── cause

Discriminated Union等を利用して
型安全にError種別を判別できる構成を推奨する。

---

## 8.10 Retry

Retry PolicyはError種別を考慮する。

原則：

    Temporary Network Error
        → Retry検討

    5xx
        → 条件付きRetry検討

    401 / 403 / 404 / 409 / 422
        → 原則自動Retryしない

    429
        → Retry-After等を考慮

すべてのErrorを無条件にRetryしない。

---

## 8.11 User Message

API `message` を
無条件にそのまま利用者へ表示しない。

User-facing Messageと
Developer / Observability情報を分離する。

---

# 9. Runtime Validation

## 9.1 基本方針

Generated TypeScript型は
Compile-time Type Safetyとして利用する。

Runtime Validationとは責務を分離する。

    OpenAPI
       ↓
    Generated Type
       ↓
    Compile-time Safety

    Untrusted Data
       ↓
    Runtime Validation
       ↓
    Runtime Safety

---

## 9.2 全Response Validation

MVPではLaravel APIの
すべてのResponseにRuntime Validationを適用しない。

Frontend / Backendが同一OpenAPI Contractを利用するため、
主に以下で整合性を保証する。

- OpenAPI
- Generated Type
- Backend Test
- Contract Test
- CI

---

## 9.3 Runtime Validation対象

主に以下へ利用する。

- User Input
- URL / Search Params
- Environment Variable
- Browser Storage
- External API
- Unknown JSON
- Trust Boundaryを越えるData

---

## 9.4 `unknown`

Validation前の信頼できないDataは
可能な限り `unknown` として扱う。

安易な、

    data as EmployeeResponse

によってValidationを回避しない。

---

## 9.5 Schema二重管理

以下のような三重管理を避ける。

    OpenAPI Schema
         +
    手書きRuntime Schema
         +
    手書きTypeScript Interface

API ContractのSource of TruthはOpenAPIとする。

Response Runtime Validationが必要な場合は、
可能であればOpenAPIからRuntime Schemaを生成する。

---

# 10. Generated Code

## 10.1 基本方針

Generated Codeは
手書きCodeと専用Directoryで分離する。

概念：

    src/
    ├── generated/
    │   └── api/
    │
    ├── lib/
    │   └── api/
    │
    └── features/

正確な配置はFrontend Architectureに従う。

---

## 10.2 手動編集禁止

Generated Codeは手動編集しない。

変更：

    OpenAPI
       ↓
    Orval Config
       ↓
    Custom Fetcher / Mutator
       ↓
    Regenerate

---

## 10.3 Git管理

Generated CodeはGitへCommitする。

`.gitignore` へ追加しない。

理由：

- API変更をDiff確認できる
- Code Review可能
- Generation忘れを検知できる
- Clone直後でもBuild可能
- Generator差異を検知できる

---

## 10.4 Source of Truth

Generated CodeをCommitしても、
Source of TruthはOpenAPIである。

Generated CodeからOpenAPIを逆生成しない。

---

## 10.5 Generator Version

Orval Versionを
`package.json` / `pnpm-lock.yaml` で固定する。

Local / CIで同一Versionを利用する。

---

## 10.6 Resource単位の整理

Generated CodeはResource単位で整理する。

例えば、

- Employees
- Skills
- Skill Categories
- Departments
- Users

OpenAPI TagをGeneration構造にも利用する。

Bounded ContextとTagを完全な1対1にはしない。

---

## 10.7 PR

OpenAPI変更とGenerated Code更新は
原則として同じPull Requestへ含める。

    OpenAPI変更
        +
    Generated Code
        ↓
    Same Pull Request

---

## 10.8 CI差分検知

CIで再生成し、
Commit済みGenerated Codeとの差分を確認する。

    Generate
       ↓
    git diff
       ↓
    Difference?
       ├── Yes → Failure
       └── No  → OK

CIがGenerated Codeを自動Commitする構成にはしない。

---

# 11. Code Generation

## 11.1 Generation Command

Project標準Commandとして、

    pnpm api:generate

を用意する。

Orval CLIを直接入力する運用を基本としない。

---

## 11.2 Local Workflow

基本：

    OpenAPI変更
         ↓
    pnpm api:generate
         ↓
    Generated Diff確認
         ↓
    Type Check
         ↓
    Test
         ↓
    Commit

---

## 11.3 自動生成

以下のタイミングで
無条件にGenerationしない。

- `pnpm dev`
- `pnpm install`
- Git Pre-commit
- Docker Build

Generationは明示的な開発作業とする。

---

## 11.4 Watch Mode

OpenAPIを頻繁に編集する場合は、
必要に応じて、

    pnpm api:generate:watch

のようなCommandを追加できる。

MVPでは必須としない。

---

## 11.5 Monorepo

Repository内で管理されるOpenAPIを
Generation Inputとする。

概念：

    repository/
    ├── frontend/
    ├── backend/
    └── openapi/

稼働中のStaging Serverから
OpenAPIを取得して生成する方式をDefaultとしない。

---

## 11.6 OpenAPI First Workflow

基本Workflow：

    1. OpenAPI変更
          ↓
    2. OpenAPI Review
          ↓
    3. Code Generation
          ↓
    4. Frontend / Backend並行実装
          ↓
    5. Contract / Integration Test

Backend実装からOpenAPIを生成する
Code First運用にはしない。

---

## 11.7 CI

基本Pipeline：

    OpenAPI
       ↓
    Lint / Validation
       ↓
    Breaking Change Check
       ↓
    Orval Generation
       ↓
    Generated Diff Check
       ↓
    Type Check
       ↓
    Test

Generation忘れやContract不整合を
CIで検知する。

---

## 11.8 Docker

Production Docker Build時に
Generated Codeを必ず再生成する構成にはしない。

CIで整合性確認済みの
Commit済みGenerated Codeを利用する。

---

## 11.9 Version固定

以下をProjectで固定する。

- Node.js
- pnpm
- Orval

Local / CI / Dockerで
再現可能なGenerationを維持する。

---

## 11.10 IDE

Code GenerationをEditor / IDEへ依存させない。

Project標準InterfaceはCLIとする。

Neovim / VS Code / CI / Dockerなど、
環境によらず同じWorkflowを利用できる状態とする。

---

# 12. 採用技術一覧

| 分類 | 採用技術 |
|---|---|
| API Contract | OpenAPI |
| Code Generator | Orval |
| Type Generation | Orval |
| API Client Generation | Orval |
| HTTP Transport | Fetch API |
| Client Server State | TanStack Query |
| TanStack Query Generation | Orval |
| Common HTTP処理 | Common Fetch Layer |
| Server Data Fetching | Generated Request Function + Fetch API |
| Client Data Fetching | Generated TanStack Query Hook |
| Error Contract | OpenAPI Error Schema |
| Error Normalization | Common Fetch Layer |
| Runtime Validation | 必要なTrust Boundaryのみ |
| Package Manager | pnpm |
| Generated Code管理 | Git |
| Generation整合性 | CI Regeneration Check |

不採用：

| 技術 / 方針 | 理由 |
|---|---|
| Axios | Fetch APIへ統一 |
| Hey API | OrvalへGeneratorを統一 |
| openapi-typescript | OrvalでType / Client / Query生成を統合 |
| OpenAPI Generator | Frontend TypeScript用途ではOrvalを優先 |
| 手書きAPI Client | OpenAPIとの二重管理を回避 |
| 手書きAPI DTO | Generated Typeとの重複を回避 |
| 全Response Runtime Validation | MVPでは過剰 |
| Browser → Laravel直接通信 | BFF Architectureを維持 |
| Generated Code手動編集 | 再生成可能性を維持 |
| Generated CodeのGit除外 | Review / CI整合性確認のためCommitする |
| Dev / Install時の強制Generation | 不要なGenerationを回避 |

---

# 13. 決定事項

Frontend API ContractのSource of Truthには
OpenAPIを利用する。

OpenAPI Code Generatorには
**Orval** を採用する。

HTTP Transportには
**Fetch API** を採用する。

Client-side Server Stateには
**TanStack Query** を採用する。

基本構成：

    OpenAPI
       ↓
      Orval
       ↓
    +-------------------------------+
    |                               |
    v                               v
Generated Types             Generated API Client
                                    ↓
                             Common Fetch Layer
                                    ↓
                                Fetch API
                                    ↓
                               Laravel API

Client-side：

    Client Component
          ↓
     TanStack Query
          ↓
    Generated Query Hook
          ↓
      Next.js BFF
          ↓
      Laravel API

Server-side：

    Server Component / BFF
            ↓
    Generated Request Function
            ↓
      Common Fetch Layer
            ↓
         Fetch API
            ↓
       Laravel API

以下をProject標準方針とする。

1. OpenAPIをAPI ContractのSource of Truthとする。
2. TypeScript API TypeをOrvalで生成する。
3. API ClientをOrvalで生成する。
4. HTTP TransportをFetch APIへ統一する。
5. Axiosは採用しない。
6. Client-side Server StateにはTanStack Queryを利用する。
7. OrvalのTanStack Query Integrationを利用する。
8. Server-sideではGenerated Request Functionを利用する。
9. Server ComponentからLaravel APIへアクセスするためだけにRoute Handlerを経由しない。
10. BrowserからLaravel APIを直接呼び出さない。
11. Authentication CredentialはServer-sideで管理する。
12. Base URL / Authentication / Common Header / Error NormalizationなどはCommon Fetch Layerへ集約する。
13. Generated ClientへBusiness Logicを持たせない。
14. Generated Functionへの単純なPass-through Wrapperを作らない。
15. Generated Hookへの単純なPass-through Hookを作らない。
16. Mutation後のInvalidation対象はApplication側で管理する。
17. Query KeyはOrval Generated Keyを可能な限り利用する。
18. API Error ResponseをOpenAPIへ定義する。
19. HTTP StatusとApplication Error Codeを分離する。
20. Message文字列からBusiness Errorを判定しない。
21. Network ErrorとHTTP Errorを区別する。
22. Error NormalizationをCommon Fetch Layerへ集約する。
23. Runtime ValidationはTrust Boundaryを中心に利用する。
24. MVPではLaravel APIの全ResponseへRuntime Validationを強制しない。
25. API ContractのSchemaをFrontendで重複定義しない。
26. Generated Codeは手動編集しない。
27. Generated CodeはGitへCommitする。
28. Source of TruthはGenerated CodeではなくOpenAPIとする。
29. OpenAPI変更とGenerated Code更新を同じPull Requestへ含める。
30. Code Generation Commandを `pnpm api:generate` へ統一する。
31. `pnpm dev` / `pnpm install` / Pre-commitで無条件Generationしない。
32. Repository管理のOpenAPIをGeneration Inputとする。
33. CIでOpenAPI Validation → Breaking Change Check → Generation → Diff Check → Type Check → Testを行う。
34. Node.js / pnpm / Orval Versionを固定する。
35. Code GenerationをIDEへ依存させない。

以上を `Frontend/05_API-Client・OpenAPI.md` の決定版とする。
