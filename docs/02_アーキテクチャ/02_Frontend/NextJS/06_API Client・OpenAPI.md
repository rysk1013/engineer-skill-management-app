# 06_API Client・OpenAPI

## 1. 目的

本プロジェクトでは、Laravel APIとの契約をOpenAPIで定義し、FrontendからのAPI通信を共通化する。

目的は以下とする。

- OpenAPIをAPI ContractのSource of Truthとする
- Request / Response Typeの重複定義を防ぐ
- Generated Codeと手書きCodeを明確に分離する
- Laravel APIへの通信処理を共通API Clientへ集約する
- FeatureへHTTP実装詳細を漏らさない
- Sanctum TokenやServer SecretをBrowserへ流出させない
- API ErrorをFrontendで一貫して扱えるようにする
- OpenAPI変更による影響をType Systemで検知する
- Generatorの再現性を確保する
- API変更とGenerated Codeの整合性をCIで保証する

基本構造を以下とする。

```text
OpenAPI
   ↓
Generated Client / Generated Types
   ↓
Handwritten API Client
   ↓
Feature Server Query / Server Action / Route Handler
   ↓
Laravel API
```

OpenAPIを以下の位置付けとする。

```text
OpenAPI
=
API Contract Source of Truth
```

---

# 2. OpenAPI First

Laravel APIのRequest / Response ContractはOpenAPIを正とする。

FrontendまたはBackend実装からOpenAPIを後付け生成する方式は採用しない。

基本Flowを以下とする。

```text
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

概念的には以下となる。

```text
             OpenAPI
            /       \
           ↓         ↓
      Frontend     Laravel
```

FrontendとBackendは同一のContractを基準として実装する。

---

# 3. API Contractの重複定義を禁止する

OpenAPIですでに定義されているRequest / Response TypeをFrontendで手書き再定義しない。

例えばOpenAPIに`EmployeeResponse`が存在する場合、以下のような重複Typeは作らない。

```ts
type EmployeeResponse = {
  id: number;
  name: string;
};
```

API Contract TypeのSourceはGenerated Codeへ統一する。

---

# 4. API関連ディレクトリ

API関連は以下を基本構成とする。

```text
src/
└── lib/
    └── api/
        ├── generated/
        ├── client.ts
        ├── errors.ts
        └── index.ts
```

責務を以下とする。

```text
generated/
=
OpenAPI Generated Code

client.ts
=
Laravel API共通通信設定

errors.ts
=
API Error共通表現・変換

index.ts
=
API Layer Public API
```

必要になるまでは過度に細分化しない。

---

# 5. `generated/`

`lib/api/generated/`にはOpenAPIから自動生成されたCodeのみ配置する。

生成対象にはGeneratorに応じて以下が含まれる。

- API Client
- Request Type
- Response Type
- Schema Type
- Enum
- Endpoint Function
- Runtime
- Endpoint Metadata

具体的なDirectory構造は採用するGeneratorに従う。

---

# 6. Generated Codeの手動編集禁止

Generated Codeは手動編集しない。

```text
generated/
↓
DO NOT EDIT
```

Generated Codeに修正が必要な場合は、以下のいずれかを修正する。

```text
OpenAPI
Generator Config
Generator Version
Generator Template
```

その後、再生成する。

以下の運用は禁止する。

```text
Generated Code
      ↓
手動修正
      ↓
次回Generateで消失
```

---

# 7. Generated Codeと手書きCodeを分離する

Generated CodeとFrontend固有の手書きCodeを同じDirectoryへ混在させない。

避ける構成：

```text
api/
├── employee.ts
├── client.ts
├── skill.ts
└── errors.ts
```

どれがGeneratedか判別できない構成は採用しない。

以下のように分離する。

```text
api/
├── generated/
│   └── ...
├── client.ts
├── errors.ts
└── index.ts
```

---

# 8. API通信の基本Flow

Laravel APIへの通信は以下を基本とする。

```text
Feature Server Code
       ↓
Handwritten API Client
       ↓
Generated Client
       ↓
Laravel API
```

Frontend各所にRaw `fetch()`を散在させない。

---

# 9. FeatureからRaw `fetch()`を直接利用しない

以下のような実装を標準としない。

```ts
const response = await fetch(
  `${process.env.LARAVEL_API_URL}/employees`
);
```

Featureごとに通信処理を書くと、以下が分散する。

```text
Base URL
Authentication
Common Header
Error Handling
Timeout
Logging
Tracing
Generated Type
Transport設定
```

Laravel APIへの通常通信は共通API Layerへ集約する。

---

# 10. Generated Clientへの依存

Generated ClientをFeatureから無秩序に直接利用することを避ける。

基本方向は以下とする。

```text
Feature
   ↓
lib/api
   ↓
generated
```

Generator固有のRuntimeやCalling ConventionをFeature全体へ広げない。

Generator変更時の影響範囲を`lib/api`周辺へ閉じ込める。

---

# 11. Handwritten API Client

`client.ts`はGenerated ClientとFrontend Server CodeのAdapterとして扱う。

```text
Feature
   ↓
client.ts
   ↓
Generated Client
   ↓
Laravel API
```

主な責務は以下とする。

```text
Base URL
Authentication
Sanctum Token付与
Common Header
Generated Client設定
Request Context
HTTP Error normalization
Timeout
Transport設定
Observability
```

---

# 12. API ClientへBusiness Ruleを置かない

API ClientはTechnical Infrastructureとして扱う。

```text
API Client
=
Technical Infrastructure
```

以下のようなBusiness Ruleは置かない。

```text
未経験ならSkill Levelを1へ変更する
```

Business CorrectnessのAuthorityはLaravel Domainとする。

---

# 13. Server-only API Client

Laravel API Clientは原則Server専用とする。

必要に応じて以下を利用する。

```ts
import "server-only";
```

API Clientは以下へアクセスする可能性がある。

```text
Sanctum Token
Internal API URL
Auth.js Server Session
Server-only Environment Variable
Authentication Header
Trace Context
```

そのためClient Componentから利用させない。

---

# 14. API Clientを利用できる場所

共通API Clientを直接利用できるのはNext.js Server側とする。

主な利用箇所：

```text
Feature Server Query
Server Action
Route Handler
Server-only BFF Module
```

例：

```text
features/employees/server/
features/employees/actions/
app/api/
```

---

# 15. Client ComponentからAPI Clientを利用しない

以下は禁止する。

```ts
"use client";

import { apiClient } from "@/lib/api";
```

Client-side Readでは、

```text
Client Component
      ↓
Route Handler
      ↓
API Client
```

とする。

Mutationでは、

```text
Client Component
      ↓
Server Action
      ↓
API Client
```

とする。

---

# 16. 認証境界

BrowserとLaravel APIではAuthentication Boundaryを分離する。

```text
Browser
   │
   │ Auth.js Session
   ▼
Next.js Server
   │
   │ Laravel Sanctum Token
   ▼
Laravel API
```

BrowserはLaravel Sanctum Tokenを扱わない。

---

# 17. Sanctum Token付与

Laravel APIへのSanctum Token付与はAPI Clientへ集約する。

Feature側が毎回Tokenを受け取る設計は採用しない。

避ける例：

```ts
getEmployees(token);
getSkills(token);
getDepartments(token);
```

FeatureはAuthentication Transportを意識しない。

```text
Feature
 ↓
API Client
 ↓
Credential付与
 ↓
Laravel API
```

---

# 18. Authentication Context

API ClientはNext.js Server上のAuthentication ContextからLaravel用Credentialを取得する。

概念的には以下とする。

```text
Auth.js Session
      ↓
Next.js Server
      ↓
Laravel Credential
      ↓
API Client
      ↓
Laravel API
```

Tokenの具体的な保存・取得方法は`08_認証・認可.md`で定義する。

---

# 19. Authorization Header

Feature側でAuthorization Headerを構築しない。

以下をFeatureごとに実装しない。

```ts
headers: {
  Authorization: `Bearer ${token}`,
}
```

API Clientへ集約する。

```text
Feature
 ↓
API Client
 ↓
Authorization Header
 ↓
Laravel
```

---

# 20. Common Header

Authentication以外の共通Headerも必要に応じてAPI Clientへ集約する。

候補：

```text
Accept
Content-Type
Request ID
Trace ID
Locale
```

ただし、必要性のないHeaderを最初から導入しない。

---

# 21. Base URL

Laravel APIのBase URLはServer側Configurationとして管理する。

概念例：

```text
LARAVEL_API_URL
```

FeatureはBase URLを知らない。

```text
Feature
 ↓
API Client
 ↓
Base URL
 ↓
Laravel API
```

---

# 22. Server ConfigurationをBrowserへ公開しない

Laravel内部API URLやCredentialを必要なくPublic Environment Variableへしない。

Server専用値はServer環境に閉じ込める。

```text
Server Configuration
       ↓
API Client
```

Clientへ公開する必要がある値のみ、明示的なPublic Configurationとして設計する。

---

# 23. Request Type

API Request TypeはOpenAPI Generated Typeを使用する。

概念例：

```ts
import type {
  CreateEmployeeRequest,
} from "@/lib/api/generated";
```

OpenAPIに存在する同一DTOをFeature側で再定義しない。

---

# 24. Form ModelとAPI Request DTO

Form StateとAPI Request DTOは同一である必要はない。

例えばFormでは、

```text
experienceYears = "1"
experienceMonths = "6"
```

のようにStringとして扱う場合がある。

一方API RequestではNumberを要求する場合がある。

この場合は、

```text
Form Model
    ↓
Validation / Conversion
    ↓
API Request DTO
```

とする。

したがって、

```text
Form Model
≠
API Request DTO
```

を許可する。

---

# 25. Response Type

API ResponseもGenerated TypeをContract Typeとして使用する。

```text
Laravel API
    ↓
Generated Response Type
    ↓
Frontend
```

Frontend表示上の変換が必要な場合だけView Modelへ変換する。

```text
Generated DTO
      ↓
Mapper
      ↓
View Model
```

---

# 26. Generated Typeの位置付け

Generated TypeはAPI Contractを表す。

```text
Generated Type
=
API Contract
```

Frontend Domain Modelとは扱わない。

本Frontendでは以下を基本とする。

```text
Generated DTO
+
Form Model
+
View Model
+
UI State
```

Backend Domain ModelをFrontendへ再構築しない。

---

# 27. DTOの不要なコピーを作らない

以下のようにほぼ同一のTypeを再定義しない。

```text
Generated EmployeeResponse
         ↓
ほぼ同一
         ↓
FrontendEmployeeResponse
```

表示上の意味が変わらない場合はGenerated Typeをそのまま利用する。

---

# 28. View Modelを作る基準

Frontend固有のPresentation Transformationが必要な場合のみView Modelを作る。

例えば、

```text
last_used_year = 2026
last_used_month = 8
       ↓
"2026年8月"
```

のような変換である。

以下の場合は不要。

```text
API DTO
 ↓
そのままUI表示可能
```

---

# 29. API ClientのReturn Type

API Clientは可能な限りGenerated Response Typeを維持する。

```text
Generated Client
      ↓
Generated Response
      ↓
API Client
      ↓
Feature
```

API Client内部でFrontend Presentation都合の変換を行わない。

Presentation変換はFeature Mapper側で行う。

---

# 30. Error normalization

Generator固有またはTransport固有のErrorをFeatureへ直接漏らさない。

例えば以下をFeatureで直接扱わない。

```text
FetchError
Generator固有Error
Raw Response
Transport Error
```

基本Flowを以下とする。

```text
Laravel Error Response
        ↓
Generated Client / Transport Error
        ↓
API Error normalization
        ↓
Frontend API Error
```

---

# 31. `errors.ts`

Frontend共通のAPI Error表現は`lib/api/errors.ts`へ集約する。

概念例：

```ts
type ApiError = {
  status: number;
  code?: string;
  message: string;
  details?: unknown;
};
```

具体的なStructureはLaravel API Error Formatと整合させる。

詳細は`10_エラーハンドリング.md`で定義する。

---

# 32. HTTP Statusを保持する

Error normalization後も必要なHTTP情報を失わない。

例えば以下を識別可能にする。

```text
401
403
404
409
422
429
500
```

すべてのFailureを単一の、

```text
API Error
```

へ潰さない。

---

# 33. Validation Error

Laravel Validation ErrorはFrontend FormへMapping可能な情報を維持する。

基本Flow：

```text
Laravel
 ↓
422 Validation Error
 ↓
API Error
 ↓
Server Action
 ↓
Form Error
```

Field Error / Global Error等へのMappingは`09_フォーム・Validation.md`および`10_エラーハンドリング.md`で定義する。

---

# 34. Raw HTTP ResponseをFeatureへ漏らさない

通常のFeatureでは以下を直接扱わない。

```ts
response.status;
response.headers;
response.json();
```

FeatureがApplication Dataを直接扱えるInterfaceを目指す。

概念例：

```ts
const employee = await apiClient.employees.get(...);
```

HTTP Responseそのものが必要な特殊処理のみ例外とする。

---

# 35. `operationId`

Generated ClientのFunction Namingを安定させるため、OpenAPIの`operationId`を明示的に管理する。

例：

```yaml
operationId: getEmployees
```

```yaml
operationId: getEmployee
```

```yaml
operationId: createEmployee
```

Generator任せの不安定なFunction Namingを避ける。

---

# 36. `operationId` Naming

基本Namingは以下とする。

```text
getEmployees
getEmployee
createEmployee
updateEmployee
deleteEmployee
```

原則、

```text
verb + resource
```

とする。

具体的なNaming ConventionはAPI設計文書と統一する。

---

# 37. Schema Naming

Request / Response Schemaも一貫したNamingを利用する。

例：

```text
EmployeeResponse
EmployeeListResponse
CreateEmployeeRequest
UpdateEmployeeRequest
```

API全体でNaming Conventionを統一する。

---

# 38. Optional / Nullable

OpenAPI上のOptionalとNullableをFrontendでも区別する。

概念的には以下となる。

```text
undefined
=
Field自体が存在しない

null
=
Fieldは存在するが値がない
```

実際の意味はOpenAPI Contractに従う。

Frontend都合で安易に同一視しない。

---

# 39. Enum

API ContractでEnumとして表現される値はGenerated Typeを利用する。

例えば以下がAPIへ公開される場合：

```text
EmploymentStatus
SkillLevel
WorkExperience
UserRole
```

同一EnumをFrontendで契約型として再定義しない。

---

# 40. API EnumとUI Labelを分離する

API Valueと表示Labelは別責務とする。

```text
API Value
=
ACTIVE

UI Label
=
在籍
```

Presentation MappingはFrontend側に置いてよい。

```text
Contract Value
≠
Presentation Label
```

を維持する。

---

# 41. 日付・日時

APIで扱う日付・日時・年月FormatはOpenAPI Schema上で明示する。

Frontend側でFormatを推測しない。

例えば、

```text
date-time
date
year-month
```

等の意味をAPI Contractで明確にする。

Frontend表示時のFormattingはFrontend側で行う。

---

# 42. OpenAPI変更と再生成

OpenAPI変更時はGenerated Codeを必ず再生成する。

基本Flowを以下とする。

```text
OpenAPI変更
    ↓
Generate
    ↓
Type Check
    ↓
Lint
    ↓
Test
```

Generated Code更新忘れを防ぐ仕組みをCIへ導入する。

---

# 43. Generated CodeをGit管理する

本プロジェクトではGenerated Client / Generated TypesをGit管理する。

理由は以下とする。

- PR上でAPI Contract変更の影響を確認できる
- Generated DiffをReviewできる
- Generatorを実行せずFrontendをBuildしやすい
- CIで再現性を検証できる
- OpenAPI変更による型変更を明示できる

---

# 44. OpenAPI変更時のCommit

OpenAPIを変更した場合はGenerated Codeも同時に更新する。

```text
OpenAPI変更
    ↓
Generated Code再生成
    ↓
同じChange SetでCommit
```

PRでは以下を同時に確認する。

```text
OpenAPI Diff
Generated Diff
Frontend変更
Backend変更
```

---

# 45. CIでGenerated Code整合性を検証する

CIではOpenAPIからGenerated Codeを再生成し、Repository上の生成結果と一致することを確認する。

概念的には以下とする。

```text
OpenAPI
+
Generator Config
       ↓
Generate
       ↓
Repository上のgenerated/
       ↓
差分確認
```

差分が存在する場合はCI Failureとすることを推奨する。

これにより以下を検知する。

```text
OpenAPI変更
+
Generated Code更新忘れ
```

---

# 46. Generator設定のVersion管理

Generatorに関する以下をRepositoryで管理する。

```text
Generator Tool
Generator Version
Generator Config
Generator Script
必要に応じてTemplate
```

Developer Local固有設定へ依存させない。

---

# 47. Generator Versionを固定する

Generator Versionを固定する。

毎回無条件で`latest`を使用しない。

Package ManagerのLockfile等を利用し、同一Inputから同一Generated Codeを得られる状態を維持する。

目的は不要なGenerated Diffを防ぐことである。

---

# 48. Generation Command

Generated Codeは単一Commandで再生成できる状態にする。

概念例：

```bash
pnpm api:generate
```

実際のCommand名はPackage ManagerおよびGenerator Tool決定後に確定する。

重要なのは、

```text
Developerが
生成手順の詳細を覚える必要がない
```

状態とすることである。

---

# 49. API Contract用手動Typeを増やさない

OpenAPI Contractに存在するTypeについて、Frontend側に以下のようなファイルを増やさない。

```text
api-types.ts
backend-types.ts
employee-api-types.ts
```

API ContractはGenerated Codeへ集約する。

Frontend固有TypeだけをFeatureの`types/`または共通`types/`へ配置する。

---

# 50. Generated Codeの内部構造へ依存しすぎない

Generatorが例えば以下を生成したとしても、

```text
generated/
├── api/
├── models/
├── runtime/
└── ...
```

Frontend全体からGenerator内部構造へ直接依存する状態を避ける。

可能な範囲で`lib/api`をPublic Boundaryとする。

---

# 51. Public APIとBarrel Export

API Layerの`index.ts`で無秩序にすべてを再Exportしない。

特に、

```text
Server-only API Client
Generated Runtime
Generated Types
Client-safe Utility
```

を同一Barrelへ集約するとServer / Client境界が曖昧になる可能性がある。

必要に応じてPublic Entry Pointを分離する。

例：

```text
lib/api/
├── generated/
├── client.ts
├── errors.ts
├── server.ts
└── types.ts
```

ただし必要になるまでは過度に分割しない。

---

# 52. Generated RuntimeとGenerated Typeの境界

Generated Runtimeと純粋なGenerated Typeを概念的に分けて考える。

```text
Generated Types
→ Client / Serverで利用可能

Generated API Runtime
→ Server側のみ
```

純粋なTypeでありSecretやRuntime依存を持たない場合、Client Componentから`import type`することを許可する。

Generated API Client RuntimeはServer側に限定する。

---

# 53. Feature Server Queryからの利用

Readでは以下を基本とする。

```text
features/employees/server/get-employees.ts
        ↓
lib/api/client.ts
        ↓
lib/api/generated/
        ↓
Laravel API
```

Feature Server Queryでは必要に応じて以下を担当できる。

```text
Feature固有Query Parameter
Frontend向けMapper
View Model生成
```

---

# 54. Server Actionからの利用

Mutationでは以下を基本とする。

```text
features/employees/actions/update-employee.ts
        ↓
lib/api/client.ts
        ↓
lib/api/generated/
        ↓
Laravel API
```

Form DataはServer ActionでValidation / Conversion後にAPI Request DTOへ変換する。

```text
Form Data
 ↓
Validation
 ↓
Conversion
 ↓
Generated Request DTO
 ↓
API Client
```

---

# 55. Route Handlerからの利用

Client-side Read等では以下とする。

```text
app/api/...
   ↓
API Client
   ↓
Generated Client
   ↓
Laravel API
```

Route HandlerごとにAuthentication HeaderやBase URL処理を再実装しない。

---

# 56. Raw `fetch()`を許可する例外

Laravel APIへのRaw `fetch()`は原則としてFeatureへ直接書かない。

例外として以下を許可する。

```text
Generatorでは扱いづらい特殊API
Streaming
File Download
特殊なHTTP Response
Generator固有制約
```

その場合でもRaw HTTP処理は可能な限り`lib/api/`内へ閉じ込める。

---

# 57. Timeout

API Requestには必要に応じてTimeoutを設定する。

Timeout PolicyはFeatureごとへ分散させずAPI Layerへ集約する。

すべてのEndpointへ一律の短いTimeoutを設定するのではなく、非機能要件およびEndpoint特性に基づいて決定する。

---

# 58. Retry

API ClientでMutationを無条件Retryしない。

特に、

```text
POST
PUT
PATCH
DELETE
```

では二重実行や意図しない更新の可能性を考慮する。

ReadのRetryについてもError Type、Idempotency、UXを踏まえて決定する。

具体的なRetry Policyは`10_エラーハンドリング.md`で定義する。

---

# 59. Observability

API ClientはNext.js → Laravel通信の共通観測点として利用する。

必要に応じて以下をObservabilityへ連携する。

```text
Request ID
Trace Context
Endpoint
HTTP Method
Status
Duration
```

具体的なLogging / Tracing仕様は非機能要件およびObservability設計に従う。

---

# 60. Sensitive Data

API ClientやError normalizationでSensitive Dataを不用意にLogへ残さない。

例：

```text
Sanctum Token
Session Token
Password
Secret
Credential
Sensitive Request Body
```

Authentication情報をError Objectへ不要に保持しない。

---

# 61. OpenAPI変更によるCompile Error

OpenAPI変更によってGenerated Typeが変わり、FrontendでCompile Errorが発生した場合、それをContract変更検知として扱う。

```text
OpenAPI変更
 ↓
Generated Type変更
 ↓
Frontend Compile Error
 ↓
影響箇所を修正
```

Type Errorを回避するために`any`へ逃がすことを基本対応としない。

---

# 62. API Clientの責務

API Clientに置いてよい責務を以下とする。

```text
Base URL
Authentication
Common Header
Generated Client設定
HTTP Error normalization
Timeout
Transport設定
Observability
```

以下は置かない。

```text
Business Rule
Feature固有Validation
UI State
Form State
View Model
Presentation Logic
```

---

# 63. 全体Architecture

API Client / OpenAPI周辺の全体像を以下とする。

```text
                    OpenAPI
                       │
                       ▼
              ┌─────────────────┐
              │ generated/      │
              │ Client / Types  │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ lib/api         │
              │ Handwritten     │
              │ API Client      │
              └────────┬────────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
    Server Query  Server Action  Route Handler
          │            │            │
          └────────────┴────────────┘
                       │
                       ▼
                   Feature UI
```

実際のLaravel通信方向は以下とする。

```text
Feature Server Code
       ↓
Handwritten API Client
       ↓
Generated Client
       ↓
Laravel API
```

---

# 64. 責務境界

各要素の責務を以下とする。

```text
OpenAPI
=
API契約

Generated Code
=
契約から生成された型・通信Code

Handwritten API Client
=
Frontend共通通信基盤

Feature
=
Frontendでの利用・表示・Form変換

Laravel Application / Domain
=
Business Correctness
```

Frontend側でこれらの責務を混在させない。

---

# 65. 決定事項

FrontendのAPI Client・OpenAPI設計として、以下を正式採用する。

- OpenAPI Firstを採用する
- OpenAPIをLaravel API ContractのSource of Truthとする
- FrontendでAPI DTOを重複定義しない
- OpenAPIからTypeScript Client / Typeを生成する
- Generated Codeは`lib/api/generated/`へ配置する
- Generated Codeの手動編集を禁止する
- Generated Codeと手書きCodeを明確に分離する
- Laravel APIへの通常通信は共通API Clientへ集約する
- Feature内へRaw `fetch()`を散在させない
- Generated Client固有のRuntime依存をFeatureへ極力漏らさない
- Handwritten API ClientをGenerated ClientとのAdapterとして扱う
- API ClientをTechnical Infrastructureとして扱う
- API ClientへBusiness Ruleを置かない
- Laravel API ClientはServer-onlyを基本とする
- Client ComponentからAPI Clientを直接利用しない
- Server Query / Server Action / Route HandlerからAPI Clientを利用する
- Laravel Sanctum Token付与はAPI Clientへ集約する
- FeatureへSanctum Tokenを引数として流さない
- Authorization Header生成をFeatureへ分散させない
- Base URL / Common Header / Transport設定をAPI Clientへ集約する
- Server-only ConfigurationをBrowserへ不要に公開しない
- API Request / Response Contract TypeはGenerated Typeを利用する
- Form ModelとAPI Request DTOは必要に応じて分離する
- Generated DTOをFrontend Domain Modelとして扱わない
- API DTOをそのまま使える場合は不要なView Modelを作らない
- Presentation変換が必要な場合のみMapper / View Modelを利用する
- API ClientではGenerated Response Typeを可能な限り維持する
- Generator固有Error / Transport ErrorをFeatureへ直接漏らさない
- ErrorをFrontend共通API Errorへnormalizeする
- Error normalization後もHTTP Statusを保持する
- Laravel Validation ErrorをFormへMapping可能な形で維持する
- FeatureへRaw HTTP Responseを不要に漏らさない
- OpenAPIの`operationId`を明示的に管理する
- `operationId`のNaming ConventionをAPI全体で統一する
- Request / Response Schema Namingを統一する
- Optional / Nullableの意味をOpenAPI Contractどおり維持する
- API EnumはGenerated Typeを利用する
- API ValueとUI Labelを分離する
- 日付・日時・年月FormatをOpenAPIで明示する
- OpenAPI変更時はGenerated Codeを必ず再生成する
- Generated CodeをGit管理する
- OpenAPI変更とGenerated Code更新を同一Change Setへ含める
- CIでGenerated Codeの生成結果との一致を検証する
- Generator Tool / Version / Config / ScriptをRepositoryで管理する
- Generator Versionを固定する
- Generated Codeを単一Commandで再生成できるようにする
- API Contract用の手動Typeを増やさない
- Generated内部構造への依存をFrontend全体へ広げない
- Barrel ExportによってServer / Client境界を曖昧にしない
- Generated API RuntimeはServer側で利用する
- 純粋なGenerated Typeは必要に応じてClientから`import type`可能とする
- Raw HTTP処理が必要な特殊ケースでも可能な限り`lib/api/`へ閉じ込める
- Timeout / Retry / Observability等の横断的Transport処理をAPI Layerへ集約する
- Mutationを無条件Retryしない
- Sensitive DataをLogging / Errorへ不用意に含めない
- OpenAPI変更によるType ErrorをContract変更検知として活用する
- Type Error回避のための安易な`any`利用を行わない

以上をFrontendのAPI Client・OpenAPI方針とする。
