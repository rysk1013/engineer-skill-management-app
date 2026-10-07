# Presentation Layer設計

## 1. 目的

Presentation Layerは、外部からのHTTP Requestを受け取り、Application LayerへUseCaseの実行を依頼し、その結果をHTTP Responseへ変換するLayerとする。

Presentation Layerでは主に以下を扱う。

- HTTP
- Routing
- Request Validation
- AuthenticationとのHTTP境界
- Authorization
- RequestからCommand / Queryへの変換
- Application ResultからHTTP Responseへの変換
- API Error表現

Presentation Layerは、

> LaravelのHTTP機能を積極的に利用しながら、HTTP固有の責務をApplication / Domainへ漏らさない境界

として設計する。

Business RuleやPersistence LogicはPresentation Layerへ持たせない。

---

## 2. 基本方針

Presentation Layerでは以下を基本方針とする。

- Laravel Routingを利用する
- Single Action Controllerを基本とする
- Controllerは薄く保つ
- Form RequestでHTTP入力Validationを行う
- Laravel PolicyでHTTP入口のAuthorizationを行う
- RequestをCommand / Queryへ変換する
- Application Handlerを直接DIして呼び出す
- Application ResultをAPI Resourceへ変換する
- API ContractはOpenAPIを正とする
- API JSONは `camelCase` とする
- Eloquent ModelをControllerから直接操作しない
- Eloquent ModelをHTTP Responseへ直接返さない
- Domain EntityをHTTP Responseへ直接公開しない
- TransactionをControllerで管理しない
- Business InvariantをControllerへ実装しない
- Domain / Application ExceptionをHTTP ErrorへMappingする
- Machine-readableなError Codeを返す

---

## 3. 基本フロー

HTTP RequestからHTTP Responseまでの基本フローは以下とする。

```text id="34bg2s"
HTTP Request
    ↓
Route
    ↓
Middleware
    ↓
Form Request
    ↓
Laravel Policy / Authorization
    ↓
Controller
    ↓
Command / Query
    ↓
Application Handler
    ↓
Application Result
    ↓
API Resource
    ↓
HTTP Response
```

Presentation Layerは主に以下の境界を担当する。

```text id="19zw8m"
HTTP
    ↓
Presentation
    ↓
Application
```

ControllerはHTTPとApplicationの橋渡しに集中する。

---

## 4. Route

Route定義はLaravel標準の `routes/` を利用する。

MVPでは基本的に以下を利用する。

```text id="7ejdgv"
routes/
└── api.php
```

API Versionは `/api/v1` をMVPの基本とする。

例:

```php id="ov6vtc"
Route::prefix('v1')->group(function () {
    Route::post(
        '/employees/{employeeId}/skills',
        RegisterEmployeeSkillController::class,
    );

    Route::put(
        '/employee-skills/{employeeSkillId}',
        UpdateEmployeeSkillController::class,
    );

    Route::get(
        '/employee-skills/{employeeSkillId}',
        GetEmployeeSkillController::class,
    );
});
```

RouteにはBusiness Logicを書かない。

Route Fileが肥大化した場合は、必要に応じてVersion / Bounded Context単位で分割する。

例:

```text id="o06qkg"
routes/
├── api.php
└── api/
    └── v1/
        ├── employees.php
        ├── skills.php
        └── access-control.php
```

ただし、将来の規模拡大を理由としてMVP開始時から過剰に分割しない。

---

## 5. Single Action Controller

Controllerは原則としてSingle Action Controllerとする。

```text id="eozqgr"
1 Controller
    =
1 HTTP Action
```

例:

```php id="u72iqi"
final class RegisterEmployeeSkillController
{
    public function __construct(
        private RegisterEmployeeSkillHandler $handler,
    ) {}

    public function __invoke(
        RegisterEmployeeSkillRequest $request,
        int $employeeId,
    ): JsonResponse {
        // ...
    }
}
```

以下のようなResource Controllerへ多数のUseCaseを集約する構成は原則として採用しない。

```text id="4c13ri"
EmployeeSkillController
├── index()
├── show()
├── store()
├── update()
└── destroy()
```

代わりにUseCase単位でControllerを分離する。

```text id="zzyjgn"
RegisterEmployeeSkillController

UpdateEmployeeSkillController

GetEmployeeSkillController

SearchEmployeeSkillsController
```

これによりApplication Handlerとの対応関係を明確にする。

---

## 6. Controllerの責務

Controllerは主に以下を担当する。

- Route Parameterの受け取り
- Validated Request Dataの取得
- Command / Queryの生成
- Application Handlerの呼び出し
- Application ResultからResponseへの変換
- 成功時のHTTP Status決定

例:

```php id="jru1tb"
final class RegisterEmployeeSkillController
{
    public function __construct(
        private RegisterEmployeeSkillHandler $handler,
    ) {}

    public function __invoke(
        RegisterEmployeeSkillRequest $request,
        int $employeeId,
    ): JsonResponse {
        $command = new RegisterEmployeeSkillCommand(
            employeeId: $employeeId,
            skillId: $request->integer('skillId'),
            skillLevel: $request->integer('skillLevel'),
            workExperience: $request
                ->string('workExperience')
                ->toString(),
            experienceMonths: $request->input('experienceMonths'),
            lastUsedMonth: $request->input('lastUsedMonth'),
        );

        $result = $this->handler->handle($command);

        return response()->json(
            new RegisterEmployeeSkillResource($result),
            201,
        );
    }
}
```

ControllerはUseCaseのBusiness Logicを実装しない。

---

## 7. Controllerで避ける処理

Controllerでは以下を原則として行わない。

- Eloquent Query
- EloquentによるWrite処理
- Repository Implementationの直接利用
- Transaction制御
- Business Invariant判定
- Domain Policyの代替となるBusiness Logic
- Database Lock
- DB Facade利用
- PostgreSQL固有処理
- ID生成
- External APIの直接呼び出し

避ける例:

```php id="v95ftr"
$employee = EmployeeModel::findOrFail($employeeId);

if (
    $request->input('workExperience') === 'none'
    && $request->integer('skillLevel') > 1
) {
    throw new ...
}

DB::transaction(function () {
    // ...
});
```

これらはApplication / Domain / Infrastructureなど適切なLayerへ配置する。

---

## 8. Form Request

HTTP Requestの入力ValidationにはLaravel Form Requestを利用する。

例:

```php id="25m0zh"
final class RegisterEmployeeSkillRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'skillId' => [
                'required',
                'integer',
            ],
            'skillLevel' => [
                'required',
                'integer',
            ],
            'workExperience' => [
                'required',
                'string',
            ],
            'experienceMonths' => [
                'nullable',
                'integer',
            ],
            'lastUsedMonth' => [
                'nullable',
                'date_format:Y-m',
            ],
        ];
    }
}
```

Form Requestでは主に以下を検証する。

- 必須 / 任意
- Data Type
- String Length
- 数値範囲
- Date / Time Format
- Enumとして受け付ける入力値
- HTTP入力としての構造
- Request Bodyとしての妥当性

---

## 9. HTTP ValidationとDomain Invariant

Form RequestによるHTTP ValidationとDomain LayerによるBusiness Invariantの保証を明確に分離する。

例えば、

```text id="5ihgso"
skillLevelがintegerである
```

という条件はHTTP ValidationとしてForm Requestで確認する。

一方、

```text id="ibq72x"
実務未経験の場合は
Skill Level 1のみ選択可能
```

という条件はDomain InvariantとしてDomain Layerで保証する。

基本的な責務分担は以下とする。

```text id="3tmhrm"
形式として正しいか
    ↓
Form Request

業務上正しいか
    ↓
Domain
```

UX向上や早期Error Responseのため、Domain Invariantと同等の条件をForm Request側でも事前Validationすることは許容する。

ただし、Business Invariantの最終的な保証地点はDomain Layerとする。

---

## 10. RequestからCommand / Queryへの変換

HTTP RequestをApplication Handlerへ直接渡さない。

```text id="uyfwzy"
HTTP Request
    ↓
Controller
    ↓
Command / Query
    ↓
Handler
```

以下のような実装は行わない。

```php id="n9b5qk"
$this->handler->handle($request);
```

Commandの場合:

```php id="k01ffx"
$command = new RegisterEmployeeSkillCommand(
    // ...
);

$result = $this->handler->handle($command);
```

Queryの場合:

```php id="sk4rge"
$query = new GetEmployeeSkillQuery(
    employeeSkillId: $employeeSkillId,
);

$result = $this->handler->handle($query);
```

これによりApplication LayerをHTTPから分離する。

---

## 11. Authorization

HTTP入口のAuthorizationにはLaravel Policyを利用する。

Laravel Policyでは、

> 現在のActorが、このHTTP操作を実行する権限を持っているか

を確認する。

本システムでは例えば以下のアクセス制御が存在する。

- Administratorは管理対象を操作できる
- Managerは全社員を操作できる
- Sub Managerは担当社員のみ操作できる
- Team Leaderは担当社員のみ閲覧できる
- 一般社員はApplicationを利用できない
- Permission管理可能なAdministratorのみPermissionを変更できる

ただし、重要なAuthorizationはApplication Layerでも必要に応じて確認する。

Presentation LayerのLaravel PolicyだけをSecurity上の唯一の保証地点としない。

---

## 12. Laravel PolicyとApplication Authorization

AuthorizationについてはPresentationとApplicationで役割を分ける。

### Presentation

Laravel Policyを利用し、

```text id="i22vpr"
HTTP入口として
このActorが操作可能か
```

を確認する。

### Application

UseCaseとして、

```text id="rcvq0s"
このActorが
この対象Resourceに対して
このUseCaseを実行可能か
```

を確認する。

Application LayerではLaravel Authへ直接依存せず、ActorContextなどのApplication Portを利用する。

---

## 13. Laravel PolicyとDomain Policy

Laravel PolicyとDomain Policyは明確に区別する。

### Laravel Policy

アクセス制御を担当する。

```text id="dbybjk"
このActorが操作可能か
```

### Domain Policy

Business Ruleを担当する。

```text id="3mt32x"
この状態変更が
業務上許されるか
```

例えばPermission管理では以下のように分担する。

```text id="s4d1eh"
Permissionを変更できるActorか？
        ↓
Laravel Policy
+
Application Authorization

Permission Managerを
0人にしてよいか？
        ↓
Domain Policy
```

AuthorizationとBusiness Invariantを混同しない。

---

## 14. Middleware

MiddlewareはHTTP Request全体に共通するCross-cutting Concernへ利用する。

主な例:

- Authentication
- Request ID / Correlation ID
- Logging Context
- Rate Limit
- CORS
- Security Header

Middlewareへ個別UseCaseのBusiness Logicを書かない。

以下のような判断はMiddlewareの責務としない。

```text id="idw05h"
EmployeeSkillを登録可能か

Permission Managerを解除可能か

Skill Levelを変更可能か
```

これらはApplication / Domainへ配置する。

---

## 15. API Resource

Application ResultからHTTP Responseへの変換にはLaravel API Resourceを利用する。

例:

```php id="kyfj95"
final class GetEmployeeSkillResource extends JsonResource
{
    public function toArray(
        Request $request,
    ): array {
        return [
            'id' => $this->resource->id,
            'employeeId' => $this->resource->employeeId,
            'skillId' => $this->resource->skillId,
            'skillLevel' => $this->resource->skillLevel,
            'workExperience' => $this->resource->workExperience,
            'experienceMonths' => $this->resource->experienceMonths,
            'lastUsedMonth' => $this->resource->lastUsedMonth,
        ];
    }
}
```

API ResourceはPresentation上の表現への変換を担当する。

Business Logicは持たせない。

---

## 16. Response変換

基本的なResponse変換フローは以下とする。

```text id="vvl6c9"
Domain
    ↓
Application Result
    ↓
API Resource
    ↓
HTTP Response
```

Domain Entityを直接API Resourceへ渡す構成は原則として採用しない。

Application LayerがPresentationへ公開するResultを明確に定義する。

---

## 17. API JSON命名規則

API JSONでは `camelCase` を基本とする。

例:

```json id="z9srrh"
{
  "employeeId": 1,
  "skillId": 10,
  "skillLevel": 3,
  "workExperience": "experienced",
  "experienceMonths": 24,
  "lastUsedMonth": "2026-08"
}
```

Database上の `snake_case` をそのままAPI Contractへ露出しない。

```text id="2s3j75"
Database
snake_case
    ↓
Boundary
    ↓
API
camelCase
```

変換を明示的に行う。

---

## 18. Date / Time表現

API上のTimestampはISO 8601形式のUTCを基本とする。

例:

```text id="lj4h7y"
2026-09-04T03:15:00Z
```

日付のみを表す場合は以下とする。

```text id="n2qucz"
2026-09-04
```

年月のみを表す場合は以下とする。

```text id="fnn8cr"
2026-08
```

`LastUsedMonth` などの年月値は `YYYY-MM` とする。

Frontendでは必要に応じてUTCから `Asia/Tokyo` へ変換して表示する。

---

## 19. Domain Entityを直接返さない

Domain EntityをHTTP Responseとして直接Serializationしない。

以下のような実装は行わない。

```php id="pcrve7"
return response()->json($employeeSkill);
```

基本形を以下とする。

```text id="tbbq5c"
Domain Entity
    ↓
Application Result
    ↓
API Resource
    ↓
JSON
```

これによりDomain Modelの内部構造とAPI Contractを分離する。

---

## 20. Eloquent Modelを直接返さない

Eloquent ModelをHTTP Responseとして直接返さない。

以下のような実装は行わない。

```php id="vx9ob3"
return EmployeeSkillModel::find($employeeSkillId);
```

Eloquent Modelを直接返すと、

- Database SchemaがAPIへ漏れる
- ORM RelationがAPIへ影響する
- Cast設定がAPI Contractへ影響する
- `hidden` / `visible` などORM設定がAPIへ影響する
- OpenAPIとの境界が曖昧になる
- Application Layerを迂回できてしまう

ため避ける。

Read処理でも原則として、

```text id="al01c6"
Query Service
    ↓
Application Result / Read Model
    ↓
API Resource
```

とする。

---

## 21. OpenAPIとの関係

API ContractはOpenAPI Specificationを正とする。

```text id="v4psrw"
OpenAPI Specification
        ↓
Presentation Layer
        ↓
Application
```

以下はOpenAPIと整合するよう実装する。

- Route
- HTTP Method
- Request Parameter
- Request Body
- Response Body
- HTTP Status
- Error Response
- JSON Property Name
- Date / Time Format

Laravel ImplementationからOpenAPIを自動生成し、それをAPI仕様の正とする方式は採用しない。

OpenAPI Firstを維持する。

---

## 22. HTTP Status

HTTP StatusはPresentation Layerで決定する。

MVPでは主に以下を利用する。

| Status | 用途 |
|---|---|
| `200 OK` | 取得・更新成功 |
| `201 Created` | 新規作成成功 |
| `204 No Content` | Response Body不要の成功 |
| `400 Bad Request` | HTTP Requestとして不正 |
| `401 Unauthorized` | Authentication失敗 |
| `403 Forbidden` | Authorization失敗 |
| `404 Not Found` | 対象Resourceが存在しない |
| `409 Conflict` | Business Conflict |
| `422 Unprocessable Entity` | Request Validation失敗 |
| `500 Internal Server Error` | 想定外のServer Error |

HTTP StatusはDomain / Application Layerへ持ち込まない。

---

## 23. Exception Mapping

Domain ExceptionおよびApplication ExceptionはPresentation境界でHTTP ErrorへMappingする。

例:

```text id="zclib8"
Domain Exception

InvalidSkillLevelForNoExperience
        ↓
Exception Mapping
        ↓
409 Conflict
        ↓
API Error Response
```

Application Exceptionの場合:

```text id="adf8jl"
Application Exception

EmployeeNotFound
        ↓
Exception Mapping
        ↓
404 Not Found
        ↓
API Error Response
```

Domain / Application Exception自身はHTTP Statusを持たない。

具体的なException分類とMapping Ruleは `10_Exception設計.md` で定義する。

---

## 24. API Error Response

API ErrorはMachine-readableなError Codeを持つ統一形式とする。

基本形:

```json id="d0c4we"
{
  "error": {
    "code": "INVALID_SKILL_LEVEL_FOR_NO_EXPERIENCE",
    "message": "Skill level is invalid for an employee without work experience."
  }
}
```

Frontendが `message` の文字列解析によって処理を分岐する設計は避ける。

必要な場合は `code` を利用する。

Validation Errorなど複数項目の詳細が必要な場合については、OpenAPIおよびException設計で別途定義する。

---

## 25. Authenticationとの境界

Browser SessionはNext.js / Better Auth側で管理する。

Application User AuthenticationはLaravel Backendが担当し、
Backend APIではBFFから渡されたLaravel Sanctum Tokenを検証する。

概念的な流れは以下とする。

```text
Browser
    ↓
Next.js / Better Auth Session
    ↓
BFF
    ↓
Sanctum Token
    ↓
Laravel Authentication Middleware
    ↓
Presentation
    ↓
Application
```

Application / Domain LayerへSanctum Tokenそのものを渡さない。

認証済みActorの情報がUseCaseで必要な場合は、
ActorContextなどのApplication Portへ変換する。

---

## 26. ControllerとApplication Handlerの対応

ControllerとApplication HandlerはUseCase単位で対応させる。

Write:

```text id="k04z0c"
RegisterEmployeeSkillController
        ↓
RegisterEmployeeSkillCommand
        ↓
RegisterEmployeeSkillHandler
```

Read:

```text id="mytdgk"
GetEmployeeSkillController
        ↓
GetEmployeeSkillQuery
        ↓
GetEmployeeSkillHandler
```

PresentationからApplicationのUseCaseを追跡しやすい構造を維持する。

---

## 27. Dependency Injection

ControllerはApplication HandlerをConstructor Injectionで受け取る。

例:

```php id="w01b85"
final class GetEmployeeSkillController
{
    public function __construct(
        private GetEmployeeSkillHandler $handler,
    ) {}
}
```

ControllerからService Containerを直接利用しない。

以下のようなService Locator形式は避ける。

```php id="ptl94f"
$handler = app(GetEmployeeSkillHandler::class);

$handler = resolve(GetEmployeeSkillHandler::class);
```

Dependency ResolutionはLaravel Service Containerへ任せ、Composition RootでBindingを管理する。

---

## 28. Presentation Layerで扱わないもの

Presentation Layerでは以下を原則として実装しない。

```text id="ukf85w"
Business Invariant
Aggregateの内部状態管理
Repository Implementation
EloquentによるBusiness Write
Transaction Boundary
Database Lock
PostgreSQL固有処理
ID生成
Domain Policyの代替となるBusiness Rule
External Serviceの具体実装
```

Presentation LayerはHTTPとの境界へ集中する。

---

## 29. ディレクトリ構成

Presentation Layerは以下を基本とする。

```text id="b30tyz"
Presentation/
└── Http/
    ├── Controllers/
    │   ├── EmployeeManagement/
    │   ├── SkillManagement/
    │   └── AccessControl/
    │
    ├── Requests/
    │   ├── EmployeeManagement/
    │   ├── SkillManagement/
    │   └── AccessControl/
    │
    ├── Resources/
    │   ├── EmployeeManagement/
    │   ├── SkillManagement/
    │   └── AccessControl/
    │
    └── Middleware/
```

Controller / Request / ResourceはBounded Contextとの対応を意識して配置する。

例えばSkill Managementでは以下のように構成する。

```text id="lvh0w7"
Presentation/
└── Http/
    ├── Controllers/
    │   └── SkillManagement/
    │       ├── RegisterEmployeeSkillController.php
    │       ├── UpdateEmployeeSkillController.php
    │       ├── GetEmployeeSkillController.php
    │       └── SearchEmployeeSkillsController.php
    │
    ├── Requests/
    │   └── SkillManagement/
    │       ├── RegisterEmployeeSkillRequest.php
    │       └── UpdateEmployeeSkillRequest.php
    │
    └── Resources/
        └── SkillManagement/
            ├── RegisterEmployeeSkillResource.php
            └── GetEmployeeSkillResource.php
```

---

## 30. Presentation Layer設計原則

Presentation Layer全体では以下の原則を維持する。

```text id="ujckof"
HTTP Request
        ↓
Route / Middleware

HTTP入力形式の検証
        ↓
Form Request

HTTP入口のアクセス制御
        ↓
Laravel Policy

Application入力への変換
        ↓
Command / Query

UseCase実行
        ↓
Application Handler

Application出力
        ↓
Result / Read Model

HTTP表現への変換
        ↓
API Resource

Domain / Application Error
        ↓
Exception Mapping
        ↓
HTTP Status + Error Code
```

Presentation LayerではLaravelの標準的なHTTP機能を積極的に利用する。

```text id="d97yy4"
Routing
Form Request
Policy
Middleware
API Resource
Exception Handling
Dependency Injection
```

これらをClean Architectureのためだけに独自実装へ置き換えない。

一方で、

```text id="bsdmvz"
Controller
    ↓
Eloquent / Database
```

というShortcutは作らない。

基本的な境界を、

```text id="st9gq5"
HTTP
    ↓
Presentation
    ↓
Application
    ↓
Domain
```

として維持する。

Laravelの利便性を活用しながら、HTTP固有の関心事をPresentation Layerへ閉じ込め、Application / DomainをHTTPから独立させる。
