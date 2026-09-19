# Backend Architecture 全体方針

## 1. 目的

Engineer Skill Management App のBackendは、業務ルールを安全かつ保守しやすい形で実装することを目的とする。

Laravelの生産性と標準機能を活かしながら、DDD（Domain-Driven Design）およびClean Architectureの考え方を取り入れ、業務ロジックとFramework・Database・HTTPなどの技術的詳細を分離する。

また、本プロジェクトは学習目的も含むため、MVPとして過度に複雑にならない範囲で、実務的なArchitecture・Design Patternを積極的に採用する。

---

## 2. 基本方針

Backend Architectureは以下を基本方針とする。

- Backend FrameworkとしてLaravelを利用する
- Clean Architectureを採用する
- DDDを採用する
- Lightweight CQRSを採用する
- DomainをLaravel・Eloquent・HTTP・Databaseから独立させる
- Laravelの標準機能を積極的に利用する
- 業務ルールをDomainへ集約する
- UseCaseをApplication Layerで表現する
- HTTP固有処理をPresentation Layerへ閉じ込める
- Database・Eloquentなどの技術的詳細をInfrastructure Layerへ閉じ込める
- Write処理とRead処理の責務を分離する
- 必要性のない抽象化やLayerを追加しない
- Full CQRSやEvent Sourcingなどの高度なArchitectureはMVPでは採用しない

---

## 3. Laravelの位置付け

Laravelを単なる起動基盤として扱うのではなく、Application Frameworkとして提供される機能を積極的に利用する。

主に以下の機能をLaravelへ任せる。

- Routing
- Middleware
- Controller
- Form Request
- Authorization Policy
- Service Container
- Service Provider
- Exception Handling
- Logging
- Queue
- Cache
- Database Connection
- Transaction
- Eloquent ORM

Clean Architectureを採用するためにLaravelの機能を避けたり、Laravelが提供している仕組みを独自実装したりすることは原則として行わない。

一方で、Laravel固有の仕組みをDomain Layerへ持ち込まない。

Laravelは主にPresentation LayerおよびInfrastructure Layerで活用する。

基本原則を以下とする。

> Laravelの便利さは積極的に利用する。ただし、LaravelをDomainの中には入れない。

---

## 4. Architecture構成

Backendは以下の4 Layerを基本構成とする。

- Presentation
- Application
- Domain
- Infrastructure

基本的な処理の流れは以下とする。

```text
HTTP Request
    ↓
Presentation
    ↓
Application
    ↓
Domain
```

基本的な依存方向は以下とする。

```text
Presentation → Application → Domain
```

InfrastructureはApplicationまたはDomainで定義されたInterfaceを実装し、DatabaseやFrameworkなどの技術的詳細を提供する。

```text
Presentation ─────→ Application ─────→ Domain
                         ↑                 ↑
                         │                 │
                         └── Infrastructure
```

Domainから外側のLayerへ依存してはならない。

各Layerの詳細な責務および依存ルールはLayer構成ドキュメントで定義する。

---

## 5. Domain中心の設計

業務上重要なルールはDomain Modelで表現し、Domain自身がInvariantを保証する。

本システムでは、例えば以下のような業務ルールをDomainで保証する。

- 実務未経験の場合はSkill Level 1のみ選択可能
- 実務経験ありの場合は経験期間1か月以上必須
- 実務経験ありの場合は最終利用年月必須
- Permission Managerを最低1人維持する

これらの業務ルールをController、Form Request、Eloquent Modelなどへ分散させない。

Domain Modelは単なるデータ構造ではなく、業務上意味のある状態とBehaviorを持つModelとして設計する。

---

## 6. LaravelとDomainの分離

Domain EntityとEloquent Modelは別のObjectとして扱う。

```text
Domain Entity ≠ Eloquent Model
```

Eloquent ModelはPersistenceを実現するためのInfrastructure Detailと位置付ける。

Domain Layerは以下へ依存しない。

- Laravel Framework
- Illuminate
- Eloquent
- HTTP
- Database
- Laravel Facade
- Service Container

Domain EntityとEloquent Modelの相互変換にはMapperを利用する。

これにより、Domain ModelをFrameworkやPersistence方式から独立させる。

---

## 7. Application Layerの方針

Application LayerはUseCaseの実行とオーケストレーションを担当する。

Command / Query / Handlerを利用し、Applicationが提供するUseCaseを明示する。

Write UseCaseでは主に以下を行う。

1. Commandを受け取る
2. 必要なDomain ObjectをRepositoryから取得する
3. Domain Modelへ業務処理を依頼する
4. 必要な永続化処理をRepositoryへ依頼する
5. UseCase単位のTransactionを管理する

Application Layerは処理の流れを制御するが、Domain自身が保証すべきBusiness InvariantをApplication Layerへ実装しない。

HTTP RequestやEloquent ModelなどのFramework固有ObjectをApplication Layerの入力として使用しない。

---

## 8. Lightweight CQRS

Write処理とRead処理では求められる責務が異なるため、Lightweight CQRSを採用する。

### Write

Write処理ではDomain ModelおよびAggregateを中心として業務ルールと整合性を保証する。

基本的な流れを以下とする。

```text
Command
    ↓
Command Handler
    ↓
Domain Model
    ↓
Repository
```

### Read

Read処理では必ずしもAggregateを復元せず、取得用途に最適化したQuery ServiceおよびRead Modelを利用する。

基本的な流れを以下とする。

```text
Query
    ↓
Query Handler
    ↓
Query Service
    ↓
Read Model
```

Read専用処理では、必要に応じてEloquent Query BuilderやSQLを利用できる。

Read処理をWrite用Repositoryへ詰め込まない。

Write DatabaseとRead Databaseの物理的な分離は行わない。

---

## 9. Transaction

Write処理では原則として以下をTransaction Boundaryとする。

```text
1 Write UseCase = 1 Transaction
```

Transaction BoundaryはApplication Handlerとする。

Application LayerからTransactionを抽象化して利用し、Laravelの `DB::transaction()` などDatabase・Framework固有の実装はInfrastructure側へ閉じ込める。

Repository内部で独自にTransactionを開始しない。

これにより、UseCase全体のTransaction Boundaryを明確にする。

---

## 10. Presentation Layer

Presentation Layerは外部InterfaceとApplicationとの境界を担当する。

HTTP APIでは主に以下を扱う。

- Route
- Controller
- Form Request
- API Resource
- Authorization Policy
- Middleware

Controllerは薄く保つ。

主な責務を以下とする。

```text
HTTP Request
    ↓
Input Validation
    ↓
Command / Queryへの変換
    ↓
Application Handler
    ↓
HTTP Responseへの変換
```

ControllerからEloquent Modelを直接操作しない。

HTTP Input ValidationとBusiness Invariantを区別し、業務ルールはDomainで保証する。

---

## 11. Infrastructure Layer

Infrastructure LayerはFramework・Database・外部システムなどの技術的詳細を担当する。

主に以下を配置する。

- Eloquent Model
- Repository Implementation
- Mapper
- Query Service Implementation
- Transaction Implementation
- ID Generator Implementation
- Authentication Adapter
- External Service Adapter
- Persistence関連実装

Infrastructure LayerはDomain/Applicationで定義された抽象に対して具体的な技術実装を提供する。

Infrastructureの詳細をDomainへ漏らさない。

---

## 12. Dependency Injection

Dependency InjectionはConstructor Injectionを基本とする。

Laravel Service ContainerをComposition Rootとして利用する。

InterfaceとImplementationのBindingはService Providerなど、Laravel側のComposition Rootで行う。

Domain LayerおよびApplication Layerでは以下のようなService Locator的な依存取得を行わない。

- `app()`
- `resolve()`
- Laravel FacadeによるInfrastructure Serviceの直接取得

依存関係はConstructorから明示的に受け取る。

---

## 13. MVPで採用しないArchitecture

MVPでは以下を原則として採用しない。

- Full CQRS
- Event Sourcing
- Separate Read Database
- Command Bus
- Query Bus
- Message Busを前提としたArchitecture
- Microservices
- Saga
- Outbox Pattern
- Optimistic Lock
- 独自DI Container

これらを将来的にも禁止するものではない。

システム規模、業務要件、性能要件、運用要件などから明確な必要性が発生した場合に再検討する。

---

## 14. 学習目的とOverengineeringのバランス

本プロジェクトはArchitecture・DDD・Laravel設計の学習目的も含むため、一般的なMVPより多少高度なArchitectureを採用することを許容する。

ただし、ArchitectureやDesign Patternを導入すること自体を目的にしない。

新しいLayer・Interface・Abstraction・Design Patternを追加する場合は、少なくとも以下のいずれかに明確なメリットがあることを判断基準とする。

- Domainを技術的詳細から保護できる
- Dependencyを適切に制御できる
- Responsibilityを明確にできる
- Business Ruleを適切な場所へ配置できる
- Testabilityを向上できる
- 変更影響範囲を小さくできる

単にArchitectureを綺麗に見せるためだけの抽象化は行わない。

また、Laravel標準機能で十分に解決できるInfrastructure上の問題について、学習目的だけを理由として独自Frameworkや独自基盤を実装しない。

---

## 15. Architecture原則

Backend Architecture全体で以下の原則を維持する。

```text
Laravelを活かす
        +
DomainをLaravelから独立させる
        +
業務ルールをDomainへ集約する
        +
UseCaseをApplicationで明示する
        +
技術的詳細をInfrastructureへ閉じ込める
        +
HTTPとの境界をPresentationへ閉じ込める
        +
WriteとReadの責務を適切に分離する
        +
必要以上にArchitectureを複雑化しない
```

本プロジェクトにおけるBackend Architectureは、

> LaravelをApplication Frameworkとして最大限活用しながら、Core Domainの業務ルールをLaravel・Eloquentなどの技術的詳細から分離する。Application LayerでUseCaseを明示し、Write処理ではDDDによって整合性を保証し、Read処理ではLightweight CQRSによって取得用途に最適化する。

ことを基本方針とする。
