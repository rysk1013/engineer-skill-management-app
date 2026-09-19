# Presentation Layer 設計

## 1. 基本方針

Presentation Layerは、

    HTTP Request / Response

を扱う外側のLayerとする。

主な責務：

- Route
- Controller
- Form Request
- API Resource
- Middleware
- Laravel Policy
- HTTP Status
- Error Response

Business RuleはPresentation Layerへ置かない。

---

## 2. 全体Flow

    Browser / Next.js BFF
        ↓
    Laravel Route
        ↓
    Middleware
        ↓
    Controller
        ↓
    Form Request
        ↓
    Command / Query
        ↓
    Application Handler
        ↓
    Domain / Infrastructure
        ↓
    Application Result
        ↓
    API Resource
        ↓
    JSON Response

---

## 3. Controller

Controllerは薄く保つ。

主な責務：

- Requestを受け取る
- Form RequestからValidation済みDataを取得する
- Command / Queryを生成する
- Handlerを呼び出す
- Application ResultをResourceへ渡す
- HTTP Statusを決定する

ControllerへBusiness Logicを書かない。

---

## 4. Controllerで行わないこと

以下は避ける。

- Eloquent Queryを直接書く
- DB Transactionを開始する
- Domain Ruleをif文で実装する
- Repositoryを直接大量に呼ぶ
- 複数Modelを更新する
- Sanctum Tokenを直接操作する
- Response Shapeを手書きで毎回組み立てる

---

## 5. Controller例

概念：

    final class RegisterEmployeeController
    {
        public function __invoke(
            RegisterEmployeeRequest $request,
            RegisterEmployeeHandler $handler,
        ): EmployeeResource {
            $command = new RegisterEmployeeCommand(
                employeeNumber:
                    $request->string('employeeNumber')->toString(),
                name:
                    $request->string('name')->toString(),
                departmentId:
                    $request->integer('departmentId'),
            );

            $result = $handler->handle($command);

            return new EmployeeResource($result);
        }
    }

ControllerではApplication Layerの呼び出しに集中する。

---

## 6. Single Action Controller

UseCase単位のControllerでは、

    __invoke()

を利用することを第一候補とする。

例：

    RegisterEmployeeController
    RetireEmployeeController
    RegisterEmployeeSkillController
    DisableEmployeeSkillController

理由：

- 1 Controller = 1 HTTP Action
- UseCaseとの対応が明確
- Controller肥大化を防ぎやすい

---

## 7. Resource Controllerとの比較

Laravel標準の、

    EmployeeController
    ├── index()
    ├── show()
    ├── store()
    ├── update()
    └── destroy()

も利用可能。

ただし今回の学習目的では、

    UseCase
        ↔
    Controller

を明確に対応させるため、
Single Action Controllerを推奨する。

---

## 8. Form Request

Form Requestは、

    HTTP Input Validation

を担当する。

例：

    RegisterEmployeeRequest

    UpdateEmployeeRequest

    RegisterEmployeeSkillRequest

    ChangeUserRoleRequest

---

## 9. Form Requestの責務

担当：

- required
- nullable
- integer
- string
- boolean
- max length
- date format
- YYYY-MM format
- enum形式
- HTTP Inputの相関Validation

Domain Ruleの最終保証は行わない。

---

## 10. Form RequestとDomainの違い

例えばEmployeeSkill登録：

Presentation：

    hasWorkExperience
        → boolean

    experienceMonths
        → integer

    skillLevel
        → integer 1〜5

    lastUsedMonth
        → YYYY-MM

Domain：

    実務経験なしならLevel1のみ

    実務経験ありなら経験月数1以上

    実務経験ありならLastUsedMonth必須

というBusiness Invariantを保証する。

---

## 11. 重複Validation

例えば：

    employeeNumber unique

をForm Requestの、

    unique:employees

だけで完結させない。

理由：

Application LayerでもBusiness Ruleとして
重複確認するため。

Form RequestでDB Queryを大量に行わないことを第一候補とする。

---

## 12. Form RequestのDatabase依存

Laravelの`exists` / `unique` Ruleは便利だが、
今回はClean Architecture学習目的なので使い分ける。

### 使用してよい

単純なInput補助Validation。

### Applicationへ寄せる

Businessとして意味のある、

- Employee Number重複
- Skill Name重複
- Department有効確認
- Assignment対象Role確認

等。

---

## 13. Authorization

Authorizationの入口としてLaravel Policyを利用する。

ただしPolicyへBusiness Ruleを全部書かない。

構成：

    Laravel Policy
        ↓
    AccessControlService
        ↓
    Assignment Repository
        ↓
    Domain / Application Rule

---

## 14. Policyの責務

PolicyはLaravelとのAdapterとして扱う。

例：

    EmployeePolicy::view()

    EmployeePolicy::update()

    SkillPolicy::manage()

    UserPolicy::managePermissions()

---

## 15. Policyで行わないこと

以下は避ける。

- 複雑なEloquent JOIN
- Permission Manager最低人数判定
- Role変更Transaction
- Assignment追加・削除
- Domain状態変更

Policyは、

    このActorがこの操作を開始できるか

を判定する入口とする。

---

## 16. Application側のAuthorization

重要操作では、
Policyを通ったからといってApplication Handler側の確認を省略しない。

例：

    ChangeUserRoleHandler

では、

    actor.canManagePermissions()

相当のRuleをApplication側でも確認する。

理由：

- HTTP以外のEntry Pointから呼ばれる可能性
- CLI / Job / Test
- Defense in Depth

---

## 17. Middleware

MiddlewareはCross CuttingなHTTP処理に利用する。

候補：

- Sanctum Authentication
- Request ID
- Rate Limit
- Logging
- Content-Type確認

Business AuthorizationはMiddlewareへ寄せすぎない。

---

## 18. Authentication Middleware

Laravel Backend APIではSanctumを利用する。

Request：

    Authorization: Bearer <token>

Middleware：

    auth:sanctum

で認証する。

認証済みUserをPresentation / Applicationへ渡す。

---

## 19. Actor変換

Laravel Auth User ModelをそのままDomainへ渡さない。

例えば：

    AuthenticatedActor

または、

    ActorContext

のようなApplication DTOへ変換する案を採用する。

例：

    ActorContext
    ├── UserId
    ├── EmployeeId
    ├── UserRole
    └── canManagePermissions

---

## 20. ActorContext

Application Handlerが操作実行者を必要とする場合に利用する。

例：

    ChangeUserRoleCommand
    ├── actor
    ├── targetUserId
    └── newRole

これによりApplication LayerがLaravel Authへ直接依存しない。

---

## 21. API Resource

API Resourceは、

    Application Result
        ↓
    OpenAPI Response

への変換を担当する。

Eloquent Modelを直接Resourceへ渡さないことを第一候補とする。

---

## 22. Resource例

    EmployeeResource
        ↓
    EmployeeResult

例：

    {
        "id": 100,
        "employeeNumber": "EMP001",
        "name": "Example",
        "department": {
            "id": 1,
            "name": "Development"
        },
        "employmentStatus": "ACTIVE",
        "retirementDate": null
    }

OpenAPI Contractに合わせる。

---

## 23. API Resourceの責務

担当：

- Field Name変換
- Date Format
- Nullable表現
- Nested Response
- OpenAPI Response Shape

担当しない：

- DB Query
- Business Rule
- Authorization
- Domain Mutation

---

## 24. Eloquent Lazy Loading

API Resource内でLazy Loadingを発生させない。

避ける：

    $this->resource->department->name

が裏で追加Queryを実行する構成。

Resourceには必要情報が揃ったApplication Result / Read Modelを渡す。

---

## 25. Date / Time変換

API Resourceでは決定済み形式へ変換する。

Timestamp：

    ISO 8601 UTC

例：

    2026-08-20T14:00:00Z

Date：

    YYYY-MM-DD

Year-Month：

    YYYY-MM

---

## 26. Command生成

HTTP InputからApplication Commandへ明示的にMappingする。

例：

    Request
        ↓
    RegisterEmployeeCommand

Request ArrayをそのままHandlerへ渡さない。

避ける：

    $handler->handle($request->validated());

推奨：

    new RegisterEmployeeCommand(...)

理由：

Layer Boundaryを明確にするため。

---

## 27. Query生成

Readでも同様。

例：

    SearchEmployeesRequest
        ↓
    SearchEmployeesQuery

Filter：

- departmentId
- skillId
- skillLevel
- experienceMonths
- employmentStatus
- page
- limit

をQuery DTOへ変換する。

---

## 28. HTTP Status

基本方針：

### GET

    200 OK

### Create

    201 Created

### Update

    200 OK

または内容なしなら、

    204 No Content

### Disable / State Change

    200 OK
    または
    204 No Content

### Validation Error

    422 Unprocessable Entity

### Authentication Error

    401 Unauthorized

### Authorization Error

    403 Forbidden

### Not Found

    404 Not Found

### Conflict

    409 Conflict

---

## 29. 409 Conflict

Business Conflictに利用する。

候補：

- Employee Number重複
- Skill Name重複
- EmployeeSkill重複
- 最後のPermission Manager解除
- 不正な状態遷移

ただしValidation Errorとの境界をAPI Error Designで統一する。

---

## 30. Error Response

共通Error Formatを定義する。

第一候補：

    {
        "code": "EMPLOYEE_NUMBER_ALREADY_EXISTS",
        "message": "Employee number already exists.",
        "errors": null
    }

Validation：

    {
        "code": "VALIDATION_ERROR",
        "message": "The given data was invalid.",
        "errors": {
            "name": [
                "The name field is required."
            ]
        }
    }

---

## 31. Error Code

Machine ReadableなError Codeを持たせることを推奨する。

例：

    VALIDATION_ERROR

    UNAUTHENTICATED

    FORBIDDEN

    EMPLOYEE_NOT_FOUND

    EMPLOYEE_NUMBER_ALREADY_EXISTS

    SKILL_ALREADY_REGISTERED

    LAST_PERMISSION_MANAGER_CANNOT_BE_REMOVED

Next.js BFF側で判定しやすくする。

---

## 32. Exception Handler

Application / Domain ExceptionをHTTP Responseへ変換する。

LaravelのException HandlingをAdapterとして利用する。

概念：

    Domain Exception
        ↓
    Exception Mapper
        ↓
    HTTP Error Response

---

## 33. Exception Mapping例

    EmployeeNotFound
        ↓
    404

    DuplicateEmployeeNumber
        ↓
    409

    InvalidEmployeeStatusTransition
        ↓
    409

    LastPermissionManagerCannotBeRemoved
        ↓
    409

    PermissionDenied
        ↓
    403

---

## 34. Domain ExceptionへHTTPを持ち込まない

Domain Exception自身に、

    HTTP 409

等を持たせない。

Domain：

    Business意味

Presentation：

    HTTP意味

として分離する。

---

## 35. OpenAPI First

Presentation LayerはOpenAPI Contractを満たす責務を持つ。

Flow：

    OpenAPI
        ↓
    Route
    Request Schema
    Response Schema
        ↓
    Laravel Presentation実装

ControllerやResourceから
OpenAPIを後生成する方式にはしない。

---

## 36. OpenAPIとForm Request

OpenAPI Request Schema：

    External Contract

Form Request：

    Laravel HTTP Validation

として対応させる。

ContractとValidationがズレないようTest / Lintを利用する。

---

## 37. OpenAPIとResource

OpenAPI Response Schema：

    EmployeeResponse

Resource：

    EmployeeResource

として対応させる。

Eloquent Column名ではなくAPI Contract名を優先する。

---

## 38. API Version

MVPでは、

    /api/v1

を第一候補とする。

例：

    /api/v1/employees

    /api/v1/skills

    /api/v1/users

将来破壊的変更に備える。

---

## 39. Route構成

例：

    routes/
    └── api.php

またはContextごとに分割する。

第一候補：

    routes/
    ├── api.php
    └── api/
        ├── employees.php
        ├── skills.php
        └── access-control.php

規模が小さい間は`api.php`でもよい。

---

## 40. EndpointとUseCase

EndpointはUseCaseに合わせる。

単なるCRUDだけに縛られない。

例：

    POST /employees/{id}/retire

    POST /employees/{id}/leave

    POST /employees/{id}/return-from-leave

のような状態遷移Endpointも候補。

---

## 41. RESTとのバランス

すべてを、

    PATCH /employees/{id}

で`employmentStatus`を書き換える方式にはしない。

Domain Operationが明確な場合は、
Action Endpointを許可する。

理由：

    retire()
    takeLeave()
    returnFromLeave()

というDomain Behaviorと対応しやすいため。

---

## 42. EmployeeSkill Endpoint例

候補：

    POST
    /employees/{employeeId}/skills

    PATCH
    /employees/{employeeId}/skills/{employeeSkillId}

    POST
    /employees/{employeeId}/skills/{employeeSkillId}/disable

    POST
    /employees/{employeeId}/skills/{employeeSkillId}/activate

---

## 43. Access Control Endpoint例

候補：

    PATCH
    /users/{userId}/role

    POST
    /users/{userId}/permission-management

    DELETE
    /users/{userId}/permission-management

    POST
    /users/{userId}/sub-manager-assignments

    DELETE
    /users/{userId}/sub-manager-assignments/{employeeId}

---

## 44. Resource Collection

一覧ResponseではPagination Metadataを統一する。

例：

    {
        "data": [...],
        "meta": {
            "page": 1,
            "perPage": 20,
            "total": 120,
            "totalPages": 6
        }
    }

OpenAPIで共通Schema化する。

---

## 45. Pagination

Frontend/BFFの利用を考慮し、

    page
    perPage

方式を第一候補とする。

大量データが問題になった場合にCursor Paginationを検討する。

MVPではOffset Paginationで十分。

---

## 46. Naming

External APIではcamelCaseを採用することを第一候補とする。

例：

Database：

    employee_number

API：

    employeeNumber

Database：

    retirement_date

API：

    retirementDate

Mapper / DTO / Resourceで境界を変換する。

---

## 47. Laravel Internal Naming

PHPではcamelCase。

Databaseではsnake_case。

OpenAPI / JSONではcamelCase。

責務を分離する。

---

## 48. Presentation Directory

第一候補：

    app/
    └── Presentation/
        └── Http/
            ├── Controllers/
            │
            ├── Requests/
            │
            ├── Resources/
            │
            ├── Policies/
            │
            └── Middleware/

Laravel標準の`app/Http`を使う案もある。

---

## 49. 推奨Directory

Clean Architectureを明確にするため、

    app/Presentation/Http/

を第一候補とする。

構成：

    Presentation/
    └── Http/
        ├── Controllers/
        │   ├── EmployeeManagement/
        │   ├── SkillManagement/
        │   └── AccessControl/
        │
        ├── Requests/
        ├── Resources/
        ├── Policies/
        └── Middleware/

---

## 50. Laravelとの統合

Laravelが標準で期待する場所と異なる場合でも、
PSR-4 AutoloadとService Provider等で対応する。

ただしLaravelのConventionを壊しすぎない。

必要なら、

    app/Http

をPresentation Adapterとしてそのまま使う選択肢も残す。

---

## 51. 推奨

学習目的を考慮して、

    app/Presentation/Http

へ明示的に分離する。

ただしRoute / Bootstrap等、
Laravel Frameworkの標準構成は無理に移動しない。

---

## 52. Presentation Layer Test

Feature Testで確認する。

対象：

- Route
- Authentication
- Authorization
- Form Request
- HTTP Status
- Error Format
- Resource Response
- OpenAPI Contract

---

## 53. Application Testとの分離

Application HandlerのBusiness FlowはApplication Test。

Presentation Testでは、

    HTTPとして正しいか

を中心に確認する。

Domain InvariantをController Testで細かく繰り返さない。

---

## 54. Contract Test

OpenAPI Firstなので、

    実Response
        ↔
    OpenAPI Schema

の一致確認を導入することを検討する。

これによりLaravel側変更によるContract Driftを防ぐ。

---

## 55. Security

Presentation Layerで以下を徹底する。

- Sanctum Authentication
- Authorization
- Request Size制限
- Rate Limit
- Validation
- Sensitive Field非公開
- Token非公開

特に、

    password
    sanctum_token
    session_token

をResponseへ含めない。

---

## 56. User Resource

User API Responseに、

    password

は絶対に含めない。

AuthSessionやSanctum Token情報も通常のUser Resourceへ含めない。

---

## 57. Logging

Request全体を無条件でLogしない。

以下をMask / 除外する。

- password
- token
- Authorization Header
- Cookie
- Session Token

Logging PolicyはInfrastructure / Security設計で統一する。

---

## 58. 決定事項

### Controller

Single Action Controllerを第一候補とする。

### Form Request

HTTP Input Validation担当。

### Command / Query

Requestから明示的に生成する。

### Policy

Authorization Adapter。

### Application側Authorization

重要操作では再確認する。

### API Resource

Application Result → OpenAPI Response変換。

### Eloquent Model

Presentationへ公開しない。

### Error

共通Error Format + Error Code。

### API Naming

camelCase。

### API Version

`/api/v1`。

### Domain Operation

必要に応じてAction Endpointを利用する。

### Presentation Directory

`app/Presentation/Http`を第一候補とする。
