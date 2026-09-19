# Laravel Service Container・DI設計

## 1. 目的

Dependency Injectionは、各Classが必要なDependencyを外部から受け取り、

- Layer間の依存方向を守る
- Domain / ApplicationをFrameworkから独立させる
- Infrastructure実装を差し替え可能にする
- Testしやすい構造にする
- Object生成責務をUseCaseから分離する

ために利用する。

本システムではLaravel Service ContainerをDI Containerとして利用する。

ただし、

> Laravel Service ContainerはObjectを組み立てるために利用し、Domain / ApplicationがLaravel Containerへ依存するためには利用しない

ことを基本方針とする。

---

## 2. 基本方針

- Constructor Injectionを基本とする
- Concrete ClassはLaravel Service ContainerのAuto Resolutionを利用する
- Interface → ImplementationのBindingはService Providerで行う
- Service ProviderをComposition Rootとして扱う
- Domain LayerからLaravel Service Containerを利用しない
- Application LayerからLaravel Service Containerを利用しない
- `app()` / `resolve()` をInner Layerで利用しない
- Service Locator Patternを避ける
- Static Global Dependencyを避ける
- Domain / ApplicationではLaravel Facadeを利用しない
- Infrastructureでは必要に応じてLaravel Facadeを利用してよい
- Optional Dependencyを安易に増やさない
- Interfaceを形式だけで作らない
- Test用差し替えはContainer BindingまたはTest Doubleで行う
- Dependency数が増えすぎた場合はClass Responsibilityを見直す

---

## 3. Dependency Injectionとは

DIではClass自身がDependencyを生成しない。

避ける例:

```php
final class RegisterEmployeeSkillHandler
{
    public function handle(
        RegisterEmployeeSkillCommand $command,
    ): void {
        $repository =
            new EloquentEmployeeSkillRepository();

        // ...
    }
}
```

この構造ではApplication LayerがInfrastructure Implementationを直接知ることになる。

推奨:

```php
final readonly class RegisterEmployeeSkillHandler
{
    public function __construct(
        private EmployeeSkillRepository $repository,
    ) {}
}
```

ImplementationはApplicationの外側から注入する。

---

## 4. Constructor Injection

Dependency Injectionは原則としてConstructor Injectionを利用する。

例:

```php
final readonly class RegisterEmployeeSkillHandler
{
    public function __construct(
        private EmployeeSkillRepository $repository,
        private EmployeeRepository $employeeRepository,
        private SkillRepository $skillRepository,
        private TransactionManager $transactionManager,
        private EmployeeSkillIdGenerator $idGenerator,
        private ActorContext $actorContext,
    ) {}
}
```

Classが何に依存しているかをConstructorから確認できる構造とする。

---

## 5. Constructor Injectionを採用する理由

Constructor Injectionには以下の利点がある。

- Dependencyが明示される
- Object生成時点でDependencyが揃う
- Test Doubleを注入しやすい
- Hidden Dependencyを避けられる
- ImmutableなClassを作りやすい
- Laravel ContainerのAuto Wiringと相性がよい

本システムではProperty Injection / Setter Injectionを基本方式として採用しない。

---

## 6. Method Injection

Laravel ControllerなどFramework Entry PointではMethod Injectionを利用できる。

ただし、Application HandlerやDomain ServiceなどのCore LogicではConstructor Injectionを基本とする。

Method Injectionを使う判断基準は、

> そのDependencyがClass全体のDependencyではなく、そのMethod実行時だけ必要か

とする。

MVPではCore LayerのDependency表現を揃えるため、基本的にはConstructor Injectionを優先する。

---

## 7. Laravel Service Container

Laravel Service ContainerはObject Graphを生成するために利用する。

例えばControllerが、

```php
final readonly class RegisterEmployeeSkillController
{
    public function __construct(
        private RegisterEmployeeSkillHandler $handler,
    ) {}
}
```

へ依存している場合、

```text
Controller
    ↓
Handler
    ↓
Repository Interface
    ↓
Infrastructure Implementation
```

をLaravel Service Containerが組み立てる。

---

## 8. Auto Resolution

Concrete Class同士のDependencyはLaravel Service ContainerのAuto Resolutionを利用する。

例えば、

```php
final readonly class RegisterEmployeeSkillController
{
    public function __construct(
        private RegisterEmployeeSkillHandler $handler,
    ) {}
}
```

```php
final readonly class RegisterEmployeeSkillHandler
{
    public function __construct(
        private EmployeeSkillRepository $repository,
    ) {}
}
```

Handlerそのものに特別なBindingが不要であれば、Containerへ個別登録しない。

必要なBindingだけを定義する。

---

## 9. Interface Binding

InterfaceにはConcrete ImplementationをService ProviderでBindingする。

例:

```php
$this->app->bind(
    EmployeeSkillRepository::class,
    EloquentEmployeeSkillRepository::class,
);
```

これによりApplication Handlerは、

```text
EmployeeSkillRepository
```

だけを知り、

```text
EloquentEmployeeSkillRepository
```

を知らない。

---

## 10. Dependency Rule

Dependency方向は以下を維持する。

```text
Presentation
    ↓
Application
    ↓
Domain
```

Infrastructureは、

```text
Application / Domain Interface
        ↑
        │ implements
        │
Infrastructure
```

として依存する。

Service Containerはこの依存関係をRuntimeで接続する。

---

## 11. Composition Root

Composition Rootとは、

> Application全体のDependencyを組み立てる場所

である。

本システムではLaravel Service ProviderをComposition Rootとして利用する。

概念:

```text
Domain Interface
Application Port
        ↑
        │ Binding
        │
Service Provider
        ↓
Infrastructure Implementation
```

---

## 12. Service Provider

Service Providerでは主に以下を行う。

- Repository Interface Binding
- Query Service Interface Binding
- Transaction Manager Binding
- ID Generator Binding
- ActorContext Binding
- Clock Binding
- External Gateway Binding

Business LogicはService Providerへ書かない。

---

## 13. Service Providerの例

```php
final class ApplicationServiceProvider
    extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            EmployeeSkillRepository::class,
            EloquentEmployeeSkillRepository::class,
        );

        $this->app->bind(
            TransactionManager::class,
            LaravelTransactionManager::class,
        );

        $this->app->bind(
            ActorContext::class,
            LaravelActorContext::class,
        );
    }
}
```

Service ProviderはDependency Mappingに集中する。

---

## 14. `register()` と `boot()`

Dependency Bindingは原則としてService Providerの `register()` で行う。

`boot()` はApplication起動後のFramework Integrationが必要な処理に利用する。

例:

- Event登録
- Route Model Binding
- Framework Extension
- Boot-time Configuration

単純なInterface Bindingを `boot()` へ置かない。

---

## 15. Providerの分割

すべてのBindingを巨大な `AppServiceProvider` に集約しない。

規模が増えた場合は責務ごとにProviderを分割する。

例:

```text
Providers/
├── PersistenceServiceProvider.php
├── ApplicationServiceProvider.php
└── AuthenticationServiceProvider.php
```

ただしMVP初期から細かく分割しすぎない。

Binding数と責務が増えてから分割する。

---

## 16. Repository Binding

Domain Repository InterfaceはInfrastructure ImplementationへBindingする。

例:

```php
$this->app->bind(
    EmployeeRepository::class,
    EloquentEmployeeRepository::class,
);

$this->app->bind(
    SkillRepository::class,
    EloquentSkillRepository::class,
);

$this->app->bind(
    EmployeeSkillRepository::class,
    EloquentEmployeeSkillRepository::class,
);
```

Application HandlerはRepository Interfaceへ依存する。

---

## 17. Query Service Binding

Application Layerで定義したQuery Service InterfaceもInfrastructure ImplementationへBindingする。

例:

```php
$this->app->bind(
    EmployeeSkillSearchQueryService::class,
    EloquentEmployeeSkillSearchQueryService::class,
);
```

Read側でもEloquent ImplementationをApplicationへ直接露出しない。

---

## 18. Transaction Manager Binding

Application Port:

```php
interface TransactionManager
{
    public function run(
        callable $callback,
    ): mixed;
}
```

Infrastructure:

```php
final class LaravelTransactionManager
    implements TransactionManager
{
    // ...
}
```

Binding:

```php
$this->app->bind(
    TransactionManager::class,
    LaravelTransactionManager::class,
);
```

Application Handlerは `DB::transaction()` を知らない。

---

## 19. ID Generator Binding

Application Portとして定義したID GeneratorもBindingする。

例:

```php
$this->app->bind(
    EmployeeSkillIdGenerator::class,
    PostgreSqlEmployeeSkillIdGenerator::class,
);
```

PostgreSQL Sequenceの取得方法をApplication / Domainへ漏らさない。

---

## 20. ActorContext Binding

Authentication情報をApplicationへ渡すため、

```text
ActorContext
```

をApplication Portとして利用する。

Infrastructure Implementation:

```text
LaravelActorContext
```

Binding:

```php
$this->app->bind(
    ActorContext::class,
    LaravelActorContext::class,
);
```

ApplicationはLaravel Auth / Sanctumへ直接依存しない。

---

## 21. Clock Binding

Business Ruleで現在時刻が必要になった場合は、

```text
Clock
```

Portを定義できる。

Production:

```text
SystemClock
```

Test:

```text
FixedClock
```

のように差し替えられる。

ただし単なる `created_at` / `updated_at` のためだけにClock Abstractionを作らない。

---

## 22. External Gateway Binding

将来的にExternal Serviceを利用する場合、

```text
Application Port
    ↓
Infrastructure Adapter
```

とする。

例:

```php
$this->app->bind(
    EmployeeDirectoryGateway::class,
    HttpEmployeeDirectoryGateway::class,
);
```

ApplicationからHTTP Clientを直接利用しない。

---

## 23. Domain LayerとContainer

Domain LayerではLaravel Service Containerを利用しない。

禁止:

```php
app(...)
resolve(...)
App::make(...)
Container::getInstance()
```

Domain ObjectはPlain PHP Objectとして利用可能にする。

---

## 24. Application LayerとContainer

Application LayerでもLaravel Service Containerを利用しない。

避ける:

```php
$repository =
    app(EmployeeSkillRepository::class);
```

推奨:

```php
public function __construct(
    private EmployeeSkillRepository $repository,
) {}
```

Application LayerのDependencyはConstructorで明示する。

---

## 25. Service Locator Pattern

以下のような構造をService Locator Patternとして避ける。

```php
final class RegisterEmployeeSkillHandler
{
    public function handle(
        RegisterEmployeeSkillCommand $command,
    ): void {
        $repository = app(
            EmployeeSkillRepository::class,
        );

        $transaction = app(
            TransactionManager::class,
        );
    }
}
```

DependencyがClass定義から見えなくなるため採用しない。

---

## 26. `app()` / `resolve()` の許容範囲

`app()` / `resolve()` をApplication / Domainでは使用しない。

Infrastructure / Framework IntegrationでLaravel API上必要な場合は限定的に利用できる。

ただしInfrastructureでもConstructor Injectionで自然に解決できる場合はそちらを優先する。

原則:

```text
Domain
    ↓
禁止

Application
    ↓
禁止

Presentation
    ↓
Constructor Injection優先

Infrastructure
    ↓
必要なFramework Integrationのみ許容
```

---

## 27. Laravel Facadeとの違い

Service ContainerとFacadeを混同しない。

Laravel FacadeはFramework ServiceへのStatic-like Interfaceである。

本システムでは、

```text
Domain
Application
```

からFacadeを利用しない。

Infrastructureでは、

```php
DB::transaction()
DB::table()
Cache::...
Http::...
```

などを必要に応じて利用できる。

PresentationでもLaravel標準機能として必要なFacade利用は許容する。

---

## 28. InfrastructureでFacadeを利用できる理由

Infrastructure LayerはFramework / Database / External Serviceなどの技術詳細を隔離する場所である。

そのため、

```php
DB::transaction()
```

や、

```php
UserModel::query()
```

などのLaravel依存を持ってよい。

重要なのは、

> Laravel依存をなくすことではなく、Laravel依存を適切なLayerへ閉じ込めること

である。

---

## 29. Concrete ClassへInterfaceを作りすぎない

すべてのClassにInterfaceを作らない。

例えば、

```text
RegisterEmployeeSkillHandler
RegisterEmployeeSkillHandlerInterface
```

のような1 Implementationしかなく、差し替えBoundaryでもないInterfaceを形式だけで作らない。

Interfaceは主に、

> Inner LayerがOuter Layerの機能を必要とするBoundary

で利用する。

---

## 30. Interfaceを作る代表例

本システムでは以下がInterface候補になる。

### Domain

- Repository

### Application

- Query Service
- Transaction Manager
- ID Generator
- ActorContext
- Clock
- External Gateway

一方、

- Handler
- Controller
- Mapper
- Eloquent Model

へ形式的なInterfaceを作る必要はない。

---

## 31. Interface Segregation

Interfaceは利用側が必要な責務だけを持たせる。

避ける:

```php
interface ApplicationInfrastructure
{
    public function saveEmployee(...);
    public function searchEmployee(...);
    public function transaction(...);
    public function currentUser(...);
    public function nextId(...);
}
```

責務ごとに分離する。

```text
EmployeeRepository
EmployeeSearchQueryService
TransactionManager
ActorContext
EmployeeIdGenerator
```

とする。

---

## 32. Contextual Binding

LaravelにはContextual Bindingが存在するが、MVPでは必要性がない限り利用しない。

例えば、

```text
Class AにはImplementation A
Class BにはImplementation B
```

というRequirementが発生した場合に検討する。

通常は1 Interface = 1 Default Implementationとする。

---

## 33. Singleton

`singleton()` は必要性があるDependencyだけに利用する。

すべてのServiceをSingletonへしない。

Singleton候補は、

- Statelessで共有可能
- 生成Costが高い
- Application全体で1 Instanceである意味がある

場合に限る。

Repository / Handlerなどを理由なくSingletonにしない。

---

## 34. `bind()` と `singleton()`

通常のInterface Bindingは、

```php
$this->app->bind(...)
```

を基本とする。

明確なLifetime Requirementがある場合のみ、

```php
$this->app->singleton(...)
```

を利用する。

Container LifetimeをPerformance Optimization目的で先回りして複雑化しない。

---

## 35. Scoped Binding

Request ScopeなどLifetime管理が必要になる場合はScoped Bindingを検討できる。

ActorContextのようにRequest単位のContextを保持するDependencyについては、ImplementationのState設計次第でRequest Scopeが適切になる可能性がある。

ただしStateless Adapterであれば通常Bindingで十分である。

Lifetimeは実装上必要になった時点で決定する。

---

## 36. Stateを持つService

Container管理ClassへMutable Stateを安易に持たせない。

特にSingletonへ、

```text
Current Employee
Current Command
Temporary Result
```

などRequest-specific Stateを保持しない。

Request ContextはActorContext等の明確なBoundaryで扱う。

---

## 37. Handlerの解決

Presentation LayerではHandlerをConstructor Injectionする。

例:

```php
final readonly class RegisterEmployeeSkillController
{
    public function __construct(
        private RegisterEmployeeSkillHandler $handler,
    ) {}

    public function __invoke(
        RegisterEmployeeSkillRequest $request,
    ): JsonResponse {
        $result = $this->handler->handle(
            // ...
        );

        // ...
    }
}
```

ControllerからContainerを直接操作しない。

---

## 38. HandlerからHandlerを呼ばない

原則としてApplication Handlerから別のApplication Handlerを呼ばない。

避ける:

```text
Handler A
    ↓
Handler B
    ↓
Handler C
```

UseCase同士を内部呼び出しすると、

- Transaction Boundaryが曖昧になる
- Authorizationが重複する
- UseCase依存が複雑になる

ためである。

共通処理が必要ならDomain Service / Domain Policy / Application Service / Port等の適切な責務へ抽出する。

ただしGenericなApplication Serviceを安易に作らない。

---

## 39. HandlerのDependency数

HandlerのConstructor Dependencyが増えすぎた場合は設計を見直すSignalとする。

例えば、

```text
Repository × 5
Query Service × 3
Gateway × 2
Policy × 3
```

などになった場合、

- UseCaseが大きすぎないか
- Aggregate Boundaryが適切か
- Responsibilityが混在していないか
- 別UseCaseへ分けられないか

を確認する。

ただしDependency数を減らすためだけに巨大Facade Serviceを作らない。

---

## 40. Dependency Aggregatorを避ける

避ける:

```php
final class SkillManagementDependencies
{
    public function __construct(
        public EmployeeRepository $employees,
        public SkillRepository $skills,
        public TransactionManager $transactions,
        public ActorContext $actor,
    ) {}
}
```

HandlerのConstructorを短くするだけのDependency Bagは作らない。

実際のDependencyを明示する方を優先する。

---

## 41. Domain ServiceのInjection

Domain ServiceがStatelessなPure Domain Logicである場合、Application HandlerへConstructor Injectionできる。

例:

```php
public function __construct(
    private PermissionManagementPolicy $policy,
) {}
```

Pure Domain Policyが単純なConcrete Classであり、Implementation差し替えBoundaryでない場合はInterfaceを作らず直接注入してよい。

---

## 42. Domain EntityへRepositoryをInjectionしない

Entity / AggregateへRepositoryやInfrastructure ServiceをInjectしない。

避ける:

```php
final class EmployeeSkill
{
    public function __construct(
        private EmployeeSkillRepository $repository,
    ) {}
}
```

AggregateはPersistenceを知らない。

必要なDataはApplication Handlerが取得し、Domainへ渡す。

---

## 43. Value ObjectへServiceをInjectionしない

Value ObjectもInfrastructure Dependencyを持たない。

```text
Value Object
    ↓
自身の値とInvariantのみ
```

を基本とする。

---

## 44. MapperのDependency

MapperはInfrastructure LayerのClassであるため、必要なDependencyをConstructor Injectionできる。

ただしMapperの役割はPersistence Representation ↔ Domain Representationの変換であり、

- Repository
- External API
- Authorization
- Transaction Manager

などをInjectして責務を肥大化させない。

---

## 45. Repository ImplementationのDependency

Repository Implementationには必要に応じて以下をInjectできる。

- Mapper
- Database-related Adapter
- Technical Helper

例:

```php
final readonly class EloquentEmployeeSkillRepository
    implements EmployeeSkillRepository
{
    public function __construct(
        private EmployeeSkillMapper $mapper,
    ) {}
}
```

Repository内からContainerでMapperを取得しない。

---

## 46. Query Service Implementation

Query Service ImplementationもConstructor Injectionを利用する。

単純にEloquent / Query Builderだけで完結する場合はDependencyがないConcrete Classでもよい。

Architectureのために不要なDatabase Adapter Interfaceを挟まない。

---

## 47. TestとDI

Unit TestではContainerを起動せず、Dependencyを直接注入することを基本とする。

例:

```php
$handler =
    new RegisterEmployeeSkillHandler(
        repository: $repository,
        employeeRepository: $employees,
        skillRepository: $skills,
        transactionManager: $transactions,
        idGenerator: $ids,
        actorContext: $actor,
    );
```

これによりApplication LayerがLaravelなしでもTest可能であることを確認できる。

---

## 48. Containerを使うTest

Laravel Feature / Integration TestではLaravel Containerを利用する。

必要に応じて、

```php
$this->app->bind(
    ExternalGateway::class,
    FakeExternalGateway::class,
);
```

などTest用Implementationへ差し替えられる。

---

## 49. MockのContainer登録

Laravel ContainerにMockを登録することも可能だが、Unit Testでは直接Constructor Injectionを優先する。

Container BindingをTestする必要がある場合はIntegration / Feature Testで確認する。

---

## 50. FakeとMock

Test Doubleは用途に応じて使い分ける。

- Fake
- Stub
- Mock
- Spy

Architecture上すべてMockに統一しない。

Repository FakeがDomain / Application Unit Testで有効な場合は利用できる。

---

## 51. Production BindingとTest Binding

Production:

```text
EmployeeSkillRepository
    ↓
EloquentEmployeeSkillRepository
```

Test:

```text
EmployeeSkillRepository
    ↓
InMemoryEmployeeSkillRepository
```

のように差し替えることができる。

ただしRepository Implementationの正しさ自体はPostgreSQL Integration Testで検証する。

---

## 52. EnvironmentごとのBinding

EnvironmentによってImplementationを切り替えることは可能だが、安易に分岐しない。

避ける:

```php
if (app()->environment('local')) {
    // completely different business behavior
}
```

Environment差異は主にInfrastructure Configurationとして扱う。

Business RuleをEnvironmentによって変更しない。

---

## 53. Config値

Configuration値はLaravel `config()` をInfrastructure / Presentationで利用できる。

Application / DomainでConfiguration値がBusiness Inputとして必要な場合は、ValueやPortとして明示的に渡す。

Domainから直接、

```php
config(...)
env(...)
```

を利用しない。

---

## 54. `env()` の扱い

Application Codeから `env()` を直接利用しない。

LaravelのConventionに従い、

```text
.env
    ↓
config/*.php
    ↓
config()
```

を利用する。

Domain / Applicationへ必要な値はContainerで構築時に渡す。

---

## 55. Primitive Dependency

Service Constructorへ大量のPrimitive Configurationを直接並べる場合はValue Object / Configuration Objectを検討する。

避ける:

```php
public function __construct(
    string $baseUrl,
    int $timeout,
    int $retryCount,
    string $apiKey,
)
```

必要に応じて、

```text
ExternalServiceConfig
```

のようなInfrastructure Configuration Objectへまとめられる。

ただしConfiguration Objectの乱造はしない。

---

## 56. Binding Closure

Implementation生成にConfigurationが必要な場合はClosure Bindingを利用できる。

例:

```php
$this->app->bind(
    ExternalServiceClient::class,
    function () {
        return new ExternalServiceClient(
            baseUrl: config(
                'services.example.base_url',
            ),
        );
    },
);
```

Laravel依存はComposition Rootに留める。

---

## 57. Factory

Runtime Dataによって異なるObject生成が必要な場合はFactoryを検討する。

ただし、

```text
DI Container
=
Business Object Factory
```

とはしない。

ContainerはApplication Wiringに利用し、Domain Object生成はDomain Factory / `register()` 等のDomain設計に従う。

---

## 58. ContainerからDomain Entityを生成しない

避ける:

```php
$employeeSkill =
    app(EmployeeSkill::class);
```

Aggregate生成は、

```php
EmployeeSkill::register(...)
```

など明示的なDomain Factory Methodを利用する。

ContainerへDomain Entity Lifecycleを管理させない。

---

## 59. Container Bindingの確認

Application起動時またはTestでBinding漏れが早期に検出されるようにする。

代表的なFeature / Integration Testで主要HandlerをContainerからResolveできることを確認する。

ただし全Classを機械的にResolveするTestを大量に作る必要はない。

---

## 60. Circular Dependency

以下のようなCircular Dependencyを作らない。

```text
Service A
    ↓
Service B
    ↓
Service A
```

Circular Dependencyが発生した場合は、

- Responsibility分離
- Dependency Direction
- Abstraction Boundary

を見直す。

Container機能で無理に回避しない。

---

## 61. Lazy Resolution

Dependencyを遅延Resolveするために `app()` をClass内部で利用しない。

必要なDependencyはConstructorで受け取る。

本当に生成Costが問題になる場合はFactory等を個別に検討する。

Premature OptimizationとしてLazy Service Locatorを導入しない。

---

## 62. DIとClean Architecture

DIは、

> Interfaceを大量に作ること

ではない。

目的は、

```text
High-level Policy
        ↓
Abstraction
        ↑
Low-level Detail
```

というDependency Inversionを成立させることである。

Laravel Service ContainerはそのRuntime Wiringを担当する。

---

## 63. DIとLaravel活用

Clean Architectureを採用していてもLaravel Service Containerを避けない。

むしろ、

- Auto Resolution
- Interface Binding
- Service Provider
- Configuration
- Testing Override

を積極的に利用する。

避けるべきなのはLaravelそのものではなく、

> Domain / ApplicationのBusiness LogicがLaravel固有APIへ直接結合すること

である。

---

## 64. Laravel標準機能とのバランス

Laravelに標準機能が存在する場合、Architectureのためだけに独自Containerや独自DI Frameworkを実装しない。

採用:

```text
Laravel Service Container
Laravel Service Provider
Constructor Injection
```

不採用:

```text
独自DI Container
独自Dependency Resolver
独自Service Locator
```

とする。

---

## 65. Service Provider設計で避けるもの

以下を避ける。

- Business Logic
- Database Query実行
- Domain Entity生成
- UseCase実行
- HTTP Request処理
- EnvironmentごとのBusiness Rule
- 巨大なFactory Logic
- Runtime Business State保持

ProviderはApplication Wiringへ集中する。

---

## 66. Container利用で避けるもの

以下を避ける。

- Domainから `app()`
- Applicationから `resolve()`
- Handler内Service Locator
- EntityへのRepository Injection
- Value ObjectへのService Injection
- すべてのClassへのInterface作成
- すべてのBindingをSingleton化
- Dependency Bag
- Circular Dependency
- ContainerからAggregate生成
- EnvironmentによるBusiness Logic変更
- ContainerをDependency隠蔽手段として利用

---

## 67. ディレクトリ構成

基本:

```text
app/
├── Domain/
│   └── ...
│
├── Application/
│   ├── Shared/
│   │   └── Ports/
│   │       ├── TransactionManager.php
│   │       ├── ActorContext.php
│   │       └── Clock.php
│   └── ...
│
├── Infrastructure/
│   ├── Persistence/
│   ├── Authentication/
│   ├── Transaction/
│   ├── IdGeneration/
│   └── External/
│
└── Providers/
    └── AppServiceProvider.php
```

規模が増えた場合はProviderを責務単位で分割する。

---

## 68. Binding例

概念的なBindingは以下となる。

```php
public function register(): void
{
    $this->app->bind(
        EmployeeRepository::class,
        EloquentEmployeeRepository::class,
    );

    $this->app->bind(
        SkillRepository::class,
        EloquentSkillRepository::class,
    );

    $this->app->bind(
        EmployeeSkillRepository::class,
        EloquentEmployeeSkillRepository::class,
    );

    $this->app->bind(
        EmployeeSkillSearchQueryService::class,
        EloquentEmployeeSkillSearchQueryService::class,
    );

    $this->app->bind(
        TransactionManager::class,
        LaravelTransactionManager::class,
    );

    $this->app->bind(
        EmployeeSkillIdGenerator::class,
        PostgreSqlEmployeeSkillIdGenerator::class,
    );

    $this->app->bind(
        ActorContext::class,
        LaravelActorContext::class,
    );
}
```

---

## 69. Object Graph例

EmployeeSkill登録UseCaseでは、概念的にContainerが以下を組み立てる。

```text
RegisterEmployeeSkillController
        ↓
RegisterEmployeeSkillHandler
        ├── EmployeeRepository
        │       ↓
        │   EloquentEmployeeRepository
        │
        ├── SkillRepository
        │       ↓
        │   EloquentSkillRepository
        │
        ├── EmployeeSkillRepository
        │       ↓
        │   EloquentEmployeeSkillRepository
        │
        ├── TransactionManager
        │       ↓
        │   LaravelTransactionManager
        │
        ├── EmployeeSkillIdGenerator
        │       ↓
        │   PostgreSqlEmployeeSkillIdGenerator
        │
        └── ActorContext
                ↓
            LaravelActorContext
```

Handler自身はConcrete Infrastructure Classを知らない。

---

## 70. Test方針

Domain Unit Test:

```text
Laravel Container
    ↓
不要
```

Application Unit Test:

```text
Laravel Container
    ↓
原則不要
```

Infrastructure Integration Test:

```text
Laravel Container
    ↓
利用可
```

Presentation Feature Test:

```text
Laravel Container
    ↓
利用
```

これによってDomain / ApplicationがLaravelから独立していることも確認できる。

---

## 71. DI設計原則

依存関係は以下とする。

```text
Controller
    ↓
Handler
    ↓
Interface
    ↑
Infrastructure Implementation
```

Runtimeでは、

```text
Laravel Service Provider
        ↓
Interface
        =
Implementation
```

をBindingする。

---

## 72. 最終方針

本システムではLaravel Service ContainerをApplication全体のDI Containerとして利用する。

基本は、

```text
Constructor Injection
+
Interface Binding
+
Service Provider
```

とする。

Domain / Applicationでは、

```text
app()
resolve()
Laravel Facade
Container API
```

を利用しない。

Infrastructure / PresentationではLaravel標準機能を必要に応じて利用する。

InterfaceはFrameworkから独立させるために形式的に増やすのではなく、

> Inner LayerがOuter Layerの機能へ依存する必要があるBoundary

に定義する。

Service Providerは、

> Domain / Applicationが要求するAbstractionとInfrastructure Implementationを接続するComposition Root

として扱う。

最終的な設計基準は、

> Dependencyを隠すのではなくConstructorで明示し、Framework依存を適切なOuter Layerへ閉じ込めながら、Laravel Service Containerの便利さを最大限利用すること

とする。
