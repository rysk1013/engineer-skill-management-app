# Backend 技術・Library選定 - HTTP・API

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend における HTTP / API 実装方式と関連技術・Libraryを定義する。

本Projectでは以下を前提とする。

- Next.jsをFrontend / BFFとして利用する
- LaravelをBackend APIとして利用する
- API StyleはRESTを基本とする
- OpenAPI Firstを採用する
- Presentation LayerはLaravelを積極的に利用する
- ControllerはSingle Action Controllerとする
- HTTP ValidationとDomain Validationを分離する
- Laravel APIからDomain Model / Eloquent Modelを直接公開しない

基本的な通信構成は以下とする。

```text
Browser
    ↓
Next.js
    ↓
BFF
    ↓
Laravel REST API
    ↓
Application Layer
    ↓
Domain / Infrastructure
```

---

## 2. API設計方針

APIはResource-orientedなREST APIとして設計する。

基本的なEndpointは以下の形式とする。

```text
GET    /api/v1/employees
GET    /api/v1/employees/{employeeId}
POST   /api/v1/employees
PUT    /api/v1/employees/{employeeId}
DELETE /api/v1/employees/{employeeId}
```

原則としてAction名をURLへ含めない。

以下のようなEndpointは避ける。

```text
POST /api/v1/employees/create
POST /api/v1/employees/update
POST /api/v1/employees/delete
```

API ContractはOpenAPIをSource of Truthとする。

```text
OpenAPI
    ↓
API Contract
    ↓
Frontend / Backend双方が実装
```

LaravelのControllerやAttributeからOpenAPI Documentを生成するCode First方式は採用しない。

---

## 3. Routing

### 3.1 採用技術

Laravel標準Routingを採用する。

追加Packageは導入しない。

```text
採用
└── Laravel Routing

不採用
└── Routing専用外部Package
```

### 3.2 Routing方針

API VersionをRouteに含める。

```text
/api/v1
```

例：

```php
Route::prefix('v1')->group(function (): void {
    Route::get('/employees', ListEmployeesController::class);
    Route::get('/employees/{employeeId}', GetEmployeeController::class);
    Route::post('/employees', CreateEmployeeController::class);
    Route::put('/employees/{employeeId}', UpdateEmployeeController::class);
    Route::delete('/employees/{employeeId}', DeleteEmployeeController::class);
});
```

`routes/api.php` にLaravel側の `/api` prefixが設定される場合は、Application側で `/api` を重複定義しない。

---

## 4. Controller

### 4.1 Single Action Controller

ControllerはSingle Action Controllerを採用する。

```php
final class CreateEmployeeController
{
    public function __invoke(
        CreateEmployeeRequest $request,
        CreateEmployeeHandler $handler,
    ): JsonResponse {
        // ...
    }
}
```

1つのControllerは原則として1つのHTTP Actionのみ担当する。

### 4.2 Controllerの責務

Controllerの責務は以下に限定する。

```text
HTTP Request受信
    ↓
Form RequestによるValidation
    ↓
Command / Queryへの変換
    ↓
Handler / Query Service呼び出し
    ↓
HTTP Responseへの変換
```

Controllerには以下を実装しない。

- Domain Logic
- 複雑なApplication Logic
- SQL / Eloquent Query
- Transaction制御
- Authorization Ruleそのもの
- 複雑なResponse組み立て

ControllerはPresentation LayerのAdapterとして薄く保つ。

---

## 5. Request / Validation

### 5.1 採用技術

HTTP Request ValidationにはLaravel Form Requestを採用する。

外部Validation Libraryは原則導入しない。

```text
採用
└── Laravel Form Request

原則不採用
└── 外部Validation Library
```

例：

```php
final class CreateEmployeeRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => [
                'required',
                'string',
                'max:100',
            ],
            'department_id' => [
                'required',
                'integer',
            ],
        ];
    }
}
```

### 5.2 Validationの責務分離

Validationを以下の4段階に分離する。

```text
Presentation
Form Request
    ↓
HTTP入力として妥当か

Application
    ↓
UseCaseとして実行可能か

Domain
    ↓
Domain Invariantを満たしているか

Database
    ↓
DB Constraintによる最終防衛
```

Form RequestはHTTP入力Validationのみ担当する。

例えば、

```text
skill_levelが1〜5の整数である
```

という入力制約はForm Requestで検証できる。

一方、

```text
実務未経験の場合はSkill Level 1のみ登録可能
```

という制約はDomain Invariantとして扱う。

Domain RuleをForm Requestへ実装しない。

---

## 6. Command / Queryへの変換

Form Request自体をApplication Layerへ渡さない。

ControllerでApplication用Command / Queryへ変換する。

```text
HTTP Request
    ↓
Form Request
    ↓
Command / Query
    ↓
Application Handler
```

例：

```php
$command = new CreateEmployeeCommand(
    name: $request->string('name')->toString(),
    departmentId: new DepartmentId(
        $request->integer('department_id'),
    ),
);

$employeeId = $handler->handle($command);
```

これによりApplication LayerをHTTP / Laravel Requestから分離する。

---

## 7. Response

### 7.1 Response形式

API ResponseはJSONとする。

基本的なContent-Typeは以下とする。

```text
application/json
```

成功Responseでは必要に応じてLaravel API ResourceまたはJsonResponseを使用する。

### 7.2 Domain Modelを直接公開しない

以下を直接HTTP Responseとして返さない。

- Eloquent Model
- Domain Entity
- Aggregate
- Value Object

以下の流れでResponseへ変換する。

```text
Application Result / Read Model
    ↓
API Resource
    ↓
JSON Response
```

これによりHTTP RepresentationをDomain / Infrastructureから分離する。

---

## 8. API Resource

### 8.1 採用技術

Laravel標準API Resourceを採用する。

```text
採用
└── Laravel JsonResource

現時点では不採用
└── JSON:API
```

例：

```php
final class EmployeeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'department_id' => $this->departmentId,
        ];
    }
}
```

Laravel 13にはFirst-partyのJSON:API Resourceも存在するが、本ProjectではJSON:API Specification自体を採用しないため、通常のAPI Resourceを使用する。

### 8.2 API Resourceの責務

API Resourceは主に以下を担当する。

- API Response Structure
- Field Name変換
- Date / Enum等のSerialization
- Nullable Field表現
- Collection Representation
- Pagination Metadataとの連携

Business Logicは実装しない。

---

## 9. HTTP Status Code

HTTP Status Codeは意味に沿って利用する。

| ケース | Status Code |
|---|---:|
| GET成功 | `200 OK` |
| POSTによるResource作成 | `201 Created` |
| PUT / PATCH成功 | `200 OK` |
| Response Bodyなしの更新成功 | `204 No Content` |
| DELETE成功 | `204 No Content` |
| Authentication Error | `401 Unauthorized` |
| Authorization Error | `403 Forbidden` |
| Resource Not Found | `404 Not Found` |
| State Conflict | `409 Conflict` |
| Validation Error | `422 Unprocessable Content` |
| Unexpected Server Error | `500 Internal Server Error` |

Status Codeを独自用途で再定義しない。

例えばEmployeeSkillの重複登録や、現在の状態と競合して処理できない場合は`409 Conflict`を候補とする。

---

## 10. Error Response

API Error Responseは全Endpointで統一する。

基本形は以下とする。

```json
{
    "error": {
        "code": "EMPLOYEE_NOT_FOUND",
        "message": "Employee not found."
    }
}
```

Validation Errorでは必要に応じてField単位の詳細を含める。

```json
{
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "The request is invalid.",
        "details": {
            "name": [
                "The name field is required."
            ]
        }
    }
}
```

Application / Domain ExceptionをControllerごとに個別処理するのではなく、LaravelのException Handling機構でHTTP Error Responseへ変換する。

```text
Domain / Application Exception
    ↓
Exception Handler
    ↓
HTTP Status
    ↓
統一Error Response
```

RFC 9457 Problem Detailsの正式採用については `07_Exception・Error-Handling.md` で最終決定する。

---

## 11. API Versioning

API VersioningはURL Path方式を採用する。

```text
/api/v1
```

例：

```text
/api/v1/employees
/api/v1/skills
/api/v1/skill-categories
/api/v1/departments
```

Header Versioningは採用しない。

URL Versioningを採用する理由は以下。

- Endpointを理解しやすい
- Routingが単純
- OpenAPIとの対応が明確
- Debugしやすい
- BFF側で扱いやすい

ただしAPI Versionを頻繁に増やす運用は行わない。

Breaking Changeが必要になった場合のみ新Versionを検討する。

---

## 12. OpenAPI

### 12.1 OpenAPI First

OpenAPI Firstを採用する。

OpenAPI DocumentをAPI ContractのSource of Truthとする。

```text
OpenAPI
    ↓
┌─────────────────────┐
│                     │
Frontend / BFF     Laravel Backend
│                     │
└──── Contract ────────┘
```

Controller / PHP Attribute / AnnotationからOpenAPIを生成する方式は採用しない。

### 12.2 採用Version

OpenAPI 3.1系を採用する。

```text
OpenAPI 3.1.x
```

SpecificationはYAMLを基本とする。

```text
openapi.yaml
```

### 12.3 Specification構成

小規模な段階では単一ファイルから開始してよい。

規模拡大後は以下のように分割する。

```text
openapi/
├── openapi.yaml
├── paths/
│   ├── employees.yaml
│   ├── skills.yaml
│   └── departments.yaml
├── schemas/
│   ├── employee.yaml
│   ├── skill.yaml
│   └── error.yaml
├── parameters/
└── responses/
```

過度な分割は行わず、可読性が低下した段階で分割する。

---

## 13. OpenAPI生成Library

Code First型のOpenAPI生成Libraryは採用しない。

以下は不採用とする。

| Library /方式 | 判断 | 理由 |
|---|---|---|
| `zircote/swagger-php` | 不採用 | Code First方式になるため |
| L5-Swagger | 不採用 | Laravel CodeからSpecificationを生成するため |
| Controller AttributeによるSchema定義 | 不採用 | Source of TruthがCode側へ移るため |
| PHP AnnotationによるSchema定義 | 不採用 | OpenAPI Firstと重複するため |
| Laravel OpenAPI Generator系 | 不採用 | OpenAPI First方針と責務が重複するため |

OpenAPI SpecificationとPHP Codeを二重管理しない。

---

## 14. OpenAPI Contract Test

### 14.1 採用Library

以下をDevelopment Dependencyとして採用する。

```text
kirschbaum-development/laravel-openapi-validator
```

Production Runtime Dependencyとしては利用しない。

2026年9月時点でLaravel 13をサポートしている。citeturn566210search0

### 14.2 目的

OpenAPI SpecificationとLaravel実装の乖離をCIで検出する。

```text
OpenAPI
    ↓
Feature / Integration Test
    ↓
Laravel Request
    ↓
Laravel Response
    ↓
OpenAPI Contract Validation
```

RequestとResponseの両方をOpenAPIに対してValidationする。

### 14.3 Dependency区分

ComposerではDev Dependencyとして管理する。

```bash
composer require --dev kirschbaum-development/laravel-openapi-validator
```

OpenAPI ValidationはProduction Requestごとには実行しない。

CI / Automated Testで検証する。

---

## 15. Pagination

一覧APIではLaravel標準Paginationを使用する。

MVPではOffset-based Paginationを基本とする。

例：

```text
GET /api/v1/employees?page=1&per_page=20
```

Response例：

```json
{
    "data": [],
    "meta": {
        "current_page": 1,
        "per_page": 20,
        "total": 100
    }
}
```

Cursor Paginationは以下のような必要性が発生した場合に再検討する。

- 大量データ
- Infinite Scroll
- Offset PaginationのPerformance問題
- 更新頻度が高い一覧

MVP段階では導入しない。

---

## 16. Filtering

FilteringはQuery Parameterで表現する。

例：

```text
GET /api/v1/employees?department_id=10&skill_id=5
```

HTTP RequestからApplication Query Objectへ変換する。

```text
Query Parameters
    ↓
Form Request
    ↓
Query DTO
    ↓
Query Service
```

Eloquent Query BuilderをPresentation Layerへ露出させない。

---

## 17. Sorting

SortingもQuery Parameterで表現する。

例：

```text
GET /api/v1/employees?sort=name&order=asc
```

APIが許可するSort Fieldを明示的に定義する。

Clientから任意のDatabase Column名を直接指定できる設計にはしない。

例：

```php
'sort' => [
    'nullable',
    Rule::in([
        'name',
        'created_at',
        'updated_at',
    ]),
],
```

---

## 18. Search

Keyword SearchもQuery Parameterを利用する。

例：

```text
GET /api/v1/employees?keyword=laravel
```

Search条件の解釈やQuery組み立てはPresentation LayerではなくQuery Service側で担当する。

---

## 19. Query Builder Package

Filtering / Sorting用の外部Query Builder PackageはMVPでは採用しない。

例えば以下のようなPackageは現時点では導入しない。

```text
spatie/laravel-query-builder
```

まずは以下の構造で実装する。

```text
Form Request
    ↓
Query DTO
    ↓
Query Handler / Query Service
    ↓
Eloquent / Query Builder
```

Filter / Sort条件が大規模化し、重複実装が問題になった場合のみ再検討する。

---

## 20. Request / Responseの命名

HTTP固有ClassはPresentation Layerに配置する。

例：

```text
Presentation/
└── Http/
    ├── Controllers/
    ├── Requests/
    └── Resources/
```

Class名は役割が明確になるようにする。

```text
CreateEmployeeController
CreateEmployeeRequest
EmployeeResource

ListEmployeesController
ListEmployeesRequest
EmployeeCollection
```

Application LayerのCommand / QueryとHTTP Requestを区別する。

```text
CreateEmployeeRequest
        ↓
Presentation Layer

CreateEmployeeCommand
        ↓
Application Layer
```

---

## 21. HTTP層とApplication Layerの境界

HTTP固有情報をApplication / Domainへ流さない。

Application Handlerへ以下を直接渡さない。

- `Request`
- `FormRequest`
- `JsonResponse`
- HTTP Status Code
- HTTP Header
- Route Parameter Object
- Eloquent Model

境界は以下のようにする。

```text
Laravel HTTP
    ↓
Controller
    ↓
Command / Query
    ↓
Application
```

これによりApplication UseCaseをHTTP以外からも呼び出せる構造を維持する。

---

## 22. API Contract変更フロー

API変更は原則としてOpenAPIから開始する。

```text
1. 要件変更
    ↓
2. OpenAPI更新
    ↓
3. Contract Review
    ↓
4. Backend実装
    ↓
5. Frontend / BFF実装
    ↓
6. Contract Test
    ↓
7. CI
```

実装後にOpenAPIを合わせる運用にはしない。

Breaking Changeについては特に慎重に扱う。

---

## 23. 採用技術・方針一覧

| 項目 | 決定 |
|---|---|
| API Style | REST |
| API接続 | Next.js BFF → Laravel API |
| API Contract | OpenAPI |
| API設計方式 | OpenAPI First |
| OpenAPI Version | 3.1.x |
| OpenAPI Format | YAML |
| Routing | Laravel Routing |
| Controller | Single Action Controller |
| HTTP Validation | Laravel Form Request |
| Application入力 | Command / Query |
| Response | JSON |
| Serialization | Laravel API Resource |
| JSON:API | 不採用 |
| API Versioning | URL Path方式 |
| Version Prefix | `/api/v1` |
| Error Response | 統一形式 |
| RFC 9457 | Exception設計で最終決定 |
| HTTP Status | 標準Semanticsに従う |
| Pagination | Laravel標準 Offset Pagination |
| Cursor Pagination | 必要時再検討 |
| Filtering | Query Parameter |
| Sorting | Query Parameter |
| Search | Query Parameter |
| Query Builder外部Package | MVPでは不採用 |
| OpenAPI自動生成 | 不採用 |
| `swagger-php` | 不採用 |
| L5-Swagger | 不採用 |
| OpenAPI Contract Test | 採用 |
| Contract Test Library | `kirschbaum-development/laravel-openapi-validator` |
| Contract Test実行場所 | Test / CI |
| Eloquent Model直接Response | 禁止 |
| Domain Model直接Response | 禁止 |
| Form RequestのApplicationへの受け渡し | 禁止 |

---

## 24. 最終方針

HTTP / APIについては、

> Laravel標準機能でHTTP Adapterを薄く実装し、OpenAPIをSource of TruthとしてFrontend / Backend間のContractを管理する

ことを基本方針とする。

Architectureは以下とする。

```text
OpenAPI Contract
        │
        │
        ▼
HTTP Request
        │
        ▼
Laravel Routing
        │
        ▼
Single Action Controller
        │
        ▼
Form Request
        │
        ▼
Command / Query
        │
        ▼
Application Handler / Query Service
        │
        ▼
Domain / Infrastructure
        │
        ▼
Application Result / Read Model
        │
        ▼
API Resource
        │
        ▼
JSON Response
        │
        ▼
OpenAPI Contract Validation
```

HTTP FrameworkとしてLaravelの生産性を活用しながら、HTTP / Laravel固有型をApplication / Domainへ侵入させない。

OpenAPIについては「Laravel Codeから生成する」のではなく、

```text
OpenAPI
    ↓
実装
    ↓
Contract Testで検証
```

という流れを徹底する。

これにより、OpenAPI First・Clean Architecture・Lightweight CQRSを矛盾なく組み合わせる。
