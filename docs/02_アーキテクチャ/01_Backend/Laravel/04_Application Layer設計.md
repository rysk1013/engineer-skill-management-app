# Application Layer設計

## 1. 目的

Application Layerは、ユーザーや外部システムから要求されたUseCaseを実行するLayerとする。

Domain Layerが保持する業務ルールを利用しながら、UseCase全体の処理順序を調整する。

Application Layerは、

> 業務ルールそのものを実装する場所ではなく、Domainを利用してUseCaseを成立させる場所

として設計する。

---

## 2. 基本方針

Application Layerでは以下を基本方針とする。

- UseCase単位で処理を表現する
- WriteにはCommand / Command Handlerを利用する
- ReadにはQuery / Query Handlerを利用する
- `1 Command = 1 Command Handler` を基本とする
- `1 Query = 1 Query Handler` を基本とする
- Command Bus / Query BusはMVPでは導入しない
- HTTP Requestを直接受け取らない
- HTTP Responseを直接返さない
- Eloquent Modelを直接扱わない
- Laravel Facadeへ直接依存しない
- Service Containerから直接Dependencyを取得しない
- Business InvariantはDomain Layerへ委譲する
- RepositoryやApplication PortをInterface経由で利用する
- Write UseCaseのTransaction Boundaryを管理する
- WriteとReadの責務を分離する
- Domain EntityやEloquent ModelをPresentation Layerへ直接公開しない

---

## 3. Application Layerの責務

Application Layerは主に以下を担当する。

- UseCaseの実行
- UseCaseの処理順序のオーケストレーション
- 必要なDomain Objectの取得
- Domain Behaviorの呼び出し
- Domain Policyの利用
- Repositoryへの永続化依頼
- Application Portを通じたInfrastructure機能の利用
- Transaction Boundaryの管理
- UseCaseとして必要なAuthorizationの確認
- Application Resultの生成

Application Layerが担当するのは、

> 何を、どの順番で実行するか

である。

一方で、

> その状態や状態変更が業務上正しいか

はDomain Layerが担当する。

---

## 4. UseCase単位の設計

Application LayerはBounded Context単位で整理し、その配下をUseCase単位で構成する。

例:

```text
Application/
└── SkillManagement/
    ├── Commands/
    │   ├── RegisterEmployeeSkill/
    │   └── UpdateEmployeeSkill/
    │
    └── Queries/
        ├── GetEmployeeSkill/
        └── SearchEmployeeSkills/
```

同一UseCaseに属するCommand / Query / Handler / Resultなどは近くに配置する。

例えば以下のように構成する。

```text
Commands/
└── RegisterEmployeeSkill/
    ├── RegisterEmployeeSkillCommand.php
    ├── RegisterEmployeeSkillHandler.php
    └── RegisterEmployeeSkillResult.php
```

Application Layerを、

```text
Commands/
Handlers/
DTOs/
Results/
```

のように完全な技術分類だけで横割りする構成は原則として採用しない。

---

## 5. Command

Commandは状態変更を伴うUseCaseの入力を表現するApplication DTOとする。

例:

```php
final readonly class RegisterEmployeeSkillCommand
{
    public function __construct(
        public int $employeeId,
        public int $skillId,
        public int $skillLevel,
        public string $workExperience,
        public ?int $experienceMonths,
        public ?string $lastUsedMonth,
    ) {}
}
```

Commandは以下の責務だけを持つ。

- UseCaseの入力値を保持する
- Presentation LayerからApplication Layerへの入力境界を表現する

Command自身には業務ロジックを持たせない。

CommandはLaravel RequestやEloquent Modelを保持しない。

---

## 6. Command Handler

Command HandlerはWrite UseCaseのオーケストレーションを担当する。

基本的な処理フローは以下とする。

```text
Command
    ↓
Actor / Authorization確認
    ↓
必要なDomain Object取得
    ↓
必要なApplication上の存在確認
    ↓
Domain Behavior / Domain Policy実行
    ↓
Repository保存
    ↓
Result生成
```

Write UseCaseでは、この処理全体を原則として1つのTransaction Boundaryに含める。

例:

```php
final class RegisterEmployeeSkillHandler
{
    public function __construct(
        private EmployeeSkillRepository $repository,
        private EmployeeSkillIdGenerator $idGenerator,
        private TransactionManager $transactionManager,
    ) {}

    public function handle(
        RegisterEmployeeSkillCommand $command,
    ): RegisterEmployeeSkillResult {
        return $this->transactionManager->run(
            function () use ($command) {
                $employeeSkill = EmployeeSkill::register(
                    $this->idGenerator->generate(),
                    new EmployeeId($command->employeeId),
                    new SkillId($command->skillId),
                    SkillLevel::from($command->skillLevel),
                    WorkExperience::from($command->workExperience),
                    // ...
                );

                $this->repository->save($employeeSkill);

                return new RegisterEmployeeSkillResult(
                    $employeeSkill->id()->value(),
                );
            },
        );
    }
}
```

HandlerにはBusiness Invariantそのものを書かない。

例えば、

```php
if ($command->workExperience === 'none'
    && $command->skillLevel > 1
) {
    throw new ...
}
```

のような業務ルールをHandlerへ実装しない。

この判断はDomainへ委譲する。

---

## 7. Query

Queryは参照系UseCaseの入力を表現するApplication DTOとする。

例:

```php
final readonly class GetEmployeeSkillQuery
{
    public function __construct(
        public int $employeeSkillId,
    ) {}
}
```

Query自身は状態変更を行わない。

Queryには業務ロジックを持たせない。

---

## 8. Query Handler

Query HandlerはRead UseCaseのオーケストレーションを担当する。

基本的にはQuery Serviceを利用してRead Model / Resultを取得する。

```php
final class GetEmployeeSkillHandler
{
    public function __construct(
        private EmployeeSkillQueryService $queryService,
    ) {}

    public function handle(
        GetEmployeeSkillQuery $query,
    ): GetEmployeeSkillResult {
        return $this->queryService->find(
            $query->employeeSkillId,
        );
    }
}
```

Read処理ではDomain Aggregateの復元を必須としない。

必要なデータをRead用途に最適化して取得する。

---

## 9. Command / Query Bus

MVPではCommand BusおよびQuery Busを導入しない。

Presentation Layerから対象Handlerを直接Dependency Injectionして利用する。

```text
Controller
    ↓
Command / Query生成
    ↓
Handler
```

例えば以下のような構造とする。

```php
final class RegisterEmployeeSkillController
{
    public function __construct(
        private RegisterEmployeeSkillHandler $handler,
    ) {}

    public function __invoke(
        RegisterEmployeeSkillRequest $request,
    ) {
        $command = new RegisterEmployeeSkillCommand(
            // ...
        );

        $result = $this->handler->handle($command);

        // HTTP Responseへ変換
    }
}
```

Command Bus / Query Busは、Cross-cutting Concernの統一処理など明確な必要性が生じた場合に再検討する。

Architecture Patternを利用すること自体を目的として導入しない。

---

## 10. Result / DTO

Application LayerからPresentation Layerへ返す値としてApplication Result / DTOを利用する。

Domain EntityやEloquent Modelを直接返さない。

例:

```php
final readonly class GetEmployeeSkillResult
{
    public function __construct(
        public int $id,
        public int $employeeId,
        public int $skillId,
        public int $level,
        public string $workExperience,
        public ?int $experienceMonths,
        public ?string $lastUsedMonth,
    ) {}
}
```

基本的な境界を以下とする。

```text
Domain Entity
      ↓
Application Result
      ↓
Presentation
      ↓
API Resource
      ↓
HTTP Response
```

これによりPresentation LayerとDomain / Infrastructureの不要な結合を避ける。

---

## 11. Domainとの責務分担

Application LayerとDomain Layerの責務を明確に分離する。

### Application Layer

以下を担当する。

- UseCaseの処理順序
- 必要なAggregateの取得
- Repository呼び出し
- Transaction管理
- Application Port利用
- 複数Domain Object間のオーケストレーション
- UseCase単位のAuthorization
- Application Result生成

### Domain Layer

以下を担当する。

- Business Invariant
- Entity / Aggregateの状態変更
- Value Object自身の妥当性
- Domain Policyによる業務判断
- Domain上の不正状態の防止

例えば、

```text
実務未経験
    ↓
Skill Level 1のみ
```

というルールはDomain Layerで保証する。

Application Handlerで同じルールをBusiness Ruleとして実装しない。

---

## 12. Application Port

Application LayerからInfrastructure固有機能を利用する必要がある場合は、Application側にPortとなるInterfaceを定義する。

主な例として以下がある。

```text
TransactionManager
ID Generator
ActorContext
Clock
External Service Gateway
```

例:

```php
interface TransactionManager
{
    public function run(callable $callback): mixed;
}
```

Infrastructure LayerがLaravelやDatabaseなどを利用して具体実装を提供する。

```text
Application
TransactionManager
        ↑
        │ implements
        │
Infrastructure
LaravelTransactionManager
```

Portは実際に必要なUseCaseが存在する場合に導入する。

将来利用する可能性だけを理由として、事前に大量のPortを作成しない。

---

## 13. ID Generator

Domain ObjectのIDを新規生成する必要があるUseCaseでは、Application PortとしてID Generatorを利用する。

例:

```php
interface EmployeeSkillIdGenerator
{
    public function generate(): EmployeeSkillId;
}
```

Application HandlerはPostgreSQL Sequenceなどの具体的なID生成方法を知らない。

```text
Application
EmployeeSkillIdGenerator
        ↑
        │ implements
        │
Infrastructure
PostgreSqlEmployeeSkillIdGenerator
```

これにより、ID生成方式をInfrastructure Detailとして分離する。

---

## 14. Repository利用

Application LayerはDomain Layerで定義されたRepository Interfaceを利用する。

Eloquent Repositoryなどの具体実装には依存しない。

```text
Application
    ↓
Domain Repository Interface
    ↑
Infrastructure Repository Implementation
```

例えば、

```php
final class UpdateEmployeeSkillHandler
{
    public function __construct(
        private EmployeeSkillRepository $repository,
    ) {}
}
```

とする。

以下のように具体的なRepository Implementationへ依存しない。

```php
private EloquentEmployeeSkillRepository $repository;
```

Repositoryの詳細は `07_Repository・Mapper.md` で定義する。

---

## 15. Query Service

Read UseCaseではQuery Serviceを利用する。

Query ServiceのInterfaceはApplication側に定義し、具体的なData Access実装はInfrastructure Layerへ配置する。

```text
Application
EmployeeSkillQueryService
        ↑
        │ implements
        │
Infrastructure
EmployeeSkillQueryService Implementation
```

Query ServiceではDomain Aggregateの復元を必須としない。

Infrastructure実装では必要に応じて以下を利用できる。

- Eloquent Query Builder
- Laravel Query Builder
- Raw SQL
- PostgreSQL固有機能

これらの技術的詳細をApplication Layerへ露出しない。

---

## 16. Transaction Boundary

Write UseCaseでは原則として、

```text
1 Write UseCase
    =
1 Transaction
```

とする。

Transaction BoundaryはCommand Handlerとする。

例えば、

```text
Command Handler
└── Transaction
    ├── Aggregate取得
    ├── Domain Behavior実行
    ├── Domain Policy実行
    └── Repository保存
```

とする。

Application LayerはTransactionManager Portを利用する。

以下のようにLaravelへ直接依存しない。

```php
DB::transaction(...);
```

具体的なTransaction設計は `09_Transaction.md` で定義する。

---

## 17. Read UseCaseとTransaction

Query Handlerでは、Write UseCaseと同様のTransaction管理を原則として要求しない。

単純なRead処理ではQuery Serviceから必要なRead Modelを取得する。

```text
Query
    ↓
Query Handler
    ↓
Query Service
    ↓
Read Model
```

一貫したSnapshotが必要など、Read Transactionに明確な理由がある場合のみ個別に検討する。

---

## 18. Authorization

AuthorizationはPresentation LayerとApplication Layerで責務を分担する。

### Presentation Layer

Laravel Policyなどを利用し、

> HTTP Requestの入口として、このActorがEndpointを利用できるか

を確認する。

### Application Layer

UseCase実行上重要なAuthorizationについて、

> このActorが対象Resourceに対して、このUseCaseを実行できるか

を確認する。

特に以下のようなUseCaseではApplication側でも確認する。

- 担当社員のみ操作可能なSub Manager
- 担当社員のみ閲覧可能なTeam Leader
- Permission変更
- Permission Managerの管理

ただし、Domain上のBusiness InvariantとAuthorizationを混同しない。

---

## 19. Actor Context

現在の操作主体が必要なUseCaseではApplication PortとしてActorContextを利用する。

例:

```php
interface ActorContext
{
    public function actorId(): UserId;

    public function role(): UserRole;
}
```

Application LayerはBetter AuthやLaravel Auth、Sanctumなどの具体的な認証機構を知らない。

```text
Better Auth / Laravel Auth / Sanctum
                 ↓
Infrastructure / Presentation
                 ↓
ActorContext
                 ↓
Application
```

これにより認証技術とUseCaseを分離する。

ActorContextへ何を持たせるかは、実際にAuthorizationへ必要な最小限の情報に限定する。

---

## 20. HTTPとの分離

Application LayerはHTTPを知らない。

以下へ依存しない。

```text
Request
FormRequest
Response
JsonResponse
HTTP Status
API Resource
Route
Middleware
```

Presentation Layerで、

```text
HTTP Request
    ↓
Form Request
    ↓
Command / Query
```

へ変換する。

Application Layerから返されたResultはPresentation LayerでHTTP Responseへ変換する。

```text
Application Result
    ↓
API Resource
    ↓
HTTP Response
```

---

## 21. Eloquentとの分離

Application LayerではEloquent Modelを直接扱わない。

以下のような実装は行わない。

```php
EmployeeSkillModel::query()->find(...);
```

また、Handlerの戻り値としてEloquent Modelを返さない。

Write処理ではRepository Interfaceを利用する。

```text
Application
    ↓
Repository Interface
```

Read処理ではQuery Service Interfaceを利用する。

```text
Application
    ↓
Query Service Interface
```

Persistence技術をApplication Layerへ露出しない。

---

## 22. Laravelとの分離

Application LayerではLaravel Frameworkへの直接依存を原則として避ける。

特に以下を利用しない。

```text
Eloquent Model
DB Facade
Auth Facade
Cache Facade
Laravel Request
Laravel Response
Laravel Validation
Service Containerの直接利用
app()
resolve()
```

Infrastructure機能が必要な場合はApplication Portを利用する。

ただし、Laravelから独立させること自体を目的として、意味のないInterfaceを作成しない。

UseCaseと技術的詳細の境界として必要な場合に抽象化する。

---

## 23. Application Serviceを乱用しない

UseCaseを曖昧なApplication Serviceへ集約しない。

例えば以下のようなServiceを作成し、

```text
EmployeeService
SkillService
EmployeeSkillService
```

多数のUseCaseをMethodとして集約する構成は避ける。

```php
$employeeSkillService->register(...);

$employeeSkillService->update(...);

$employeeSkillService->delete(...);

$employeeSkillService->search(...);
```

代わりにUseCaseごとのHandlerとして表現する。

```text
RegisterEmployeeSkillHandler

UpdateEmployeeSkillHandler

DeactivateEmployeeSkillHandler

SearchEmployeeSkillsHandler
```

これによりUseCaseの責務を明確にする。

---

## 24. Handlerの粒度

基本的に以下を原則とする。

```text
1 UseCase
    =
1 Command / Query
    +
1 Handler
```

例えば、

```text
RegisterEmployeeSkill
├── RegisterEmployeeSkillCommand
└── RegisterEmployeeSkillHandler
```

とする。

この構成により、

- UseCaseの責務が明確になる
- Presentationとの対応関係を理解しやすい
- Test対象が明確になる
- Handlerの肥大化を防ぎやすい
- UseCase単位で変更影響を把握しやすい

状態を維持する。

ただし、形式を守るためだけに不要なClassを増やさない。

---

## 25. Handlerの肥大化

Handlerが肥大化した場合、単純に処理をPrivate Methodへ分割するだけではなく、責務の配置が正しいかを確認する。

主に以下を検討する。

```text
Business Ruleではないか？
        ↓
Domainへ移動

値そのもののRuleではないか？
        ↓
Value Objectへ移動

複数AggregateのBusiness Ruleではないか？
        ↓
Domain Policyを検討

Infrastructure Detailではないか？
        ↓
Application Port + Infrastructureへ移動

Read処理ではないか？
        ↓
Query Serviceへ移動
```

HandlerはUseCaseのオーケストレーションへ集中させる。

---

## 26. Application Exception

Application Layerでは、Domain Invariant違反とは異なるUseCaseレベルの失敗を表現する必要がある場合、Application Exceptionを利用できる。

例として以下がある。

```text
対象Resourceが存在しない
UseCase実行に必要な対象が取得できない
Actorが対象UseCaseを実行できない
```

Domain ExceptionとApplication Exceptionを区別する。

Application Exception自身もHTTP StatusやJSON Responseを直接持たない。

具体的なException分類およびHTTP Mappingは `10_Exception設計.md` で定義する。

---

## 27. Application Layerのディレクトリ原則

Application LayerはBounded Context → Command / Query → UseCase単位で整理する。

例:

```text
Application/
└── SkillManagement/
    ├── Commands/
    │   ├── RegisterEmployeeSkill/
    │   │   ├── RegisterEmployeeSkillCommand.php
    │   │   ├── RegisterEmployeeSkillHandler.php
    │   │   └── RegisterEmployeeSkillResult.php
    │   │
    │   └── UpdateEmployeeSkill/
    │       ├── UpdateEmployeeSkillCommand.php
    │       ├── UpdateEmployeeSkillHandler.php
    │       └── UpdateEmployeeSkillResult.php
    │
    └── Queries/
        ├── GetEmployeeSkill/
        │   ├── GetEmployeeSkillQuery.php
        │   ├── GetEmployeeSkillHandler.php
        │   └── GetEmployeeSkillResult.php
        │
        └── SearchEmployeeSkills/
            ├── SearchEmployeeSkillsQuery.php
            ├── SearchEmployeeSkillsHandler.php
            └── SearchEmployeeSkillsResult.php
```

Application PortなどBounded Contextをまたいで利用するものについては、必要に応じて以下へ配置する。

```text
Application/
└── Shared/
    └── Ports/
```

ただし、`Shared` を便利な置き場所として利用しない。

複数Contextから実際に共有されるものだけを配置する。

---

## 28. Application Layer設計原則

Application Layer全体では以下の原則を維持する。

```text
外部からの要求
        ↓
Command / Query

UseCase
        ↓
Handler

UseCaseの処理順序
        ↓
Application

Business Invariant
        ↓
Domainへ委譲

Domain Objectの永続化
        ↓
Repository Interface

Read用Data Access
        ↓
Query Service Interface

Infrastructure機能
        ↓
Application Port

Write
        ↓
ApplicationがTransaction Boundaryを管理

Read
        ↓
Read用途に最適化

Applicationからの出力
        ↓
Result / DTO

HTTP / Eloquent / Laravel固有処理
        ↓
Applicationへ持ち込まない
```

Application Layerでは、

> UseCaseを明示し、その実行に必要なDomain・Persistence・Infrastructureの処理をオーケストレーションする

ことを重視する。

同時に、

> Application Layer自身がBusiness Logicの置き場にならないこと

を維持する。

Domainが業務上の正しさを保証し、ApplicationがそのDomainを利用してUseCaseを成立させる構造とする。
