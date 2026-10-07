# Laravel Backendアーキテクチャ

Engineer Skill Management App のLaravel Backendに関する内部Architecture、DDD、Application、Persistence、Presentation、Testの設計文書を管理するディレクトリです。

LaravelはHTMLを配信するApplicationではなく、Next.js Frontend／BFFから利用されるBackend APIとして動作します。Business Rule、最終的な認可とValidation、Transaction、データ整合性はLaravel Backend側で保証します。

## システム上の位置付け

```text
Browser
   │
   ▼
Next.js Frontend / BFF
   │ OpenAPIに基づくHTTP API
   ▼
Laravel Backend API
   │
   ▼
PostgreSQL
```

- BrowserからLaravel Backend APIを直接呼び出さず、Next.js BFFを経由します。
- Next.jsは画面、Browser Session、BFFを担当します。
- LaravelはUse Case、Domain Rule、認可、永続化を担当します。
- Backend APIの契約はOpenAPIをSource of Truthとします。

## 採用Architecture

| 方針 | 目的 |
| --- | --- |
| Clean Architecture | DomainとLaravel、Eloquent、PostgreSQL、HTTPを分離する |
| DDD | 業務概念とBusiness Ruleを明示的なDomain Modelで表現する |
| Lightweight CQRS | Write処理とRead処理の責務をApplication Layerで分離する |
| Dependency Inversion | Domain／ApplicationがInterfaceを定義し、Infrastructureが実装する |

Full CQRS、Event Sourcing、Microservicesなどを一律に導入せず、MVPと学習目的に必要な範囲で適用します。

## Layer構成

```text
Presentation
    ↓
Application
    ↓
Domain

Infrastructure
    └── Application / DomainのInterfaceを実装
```

| Layer | 主な責務 | Laravelとの関係 |
| --- | --- | --- |
| Presentation | Controller、Form Request、API Resource、Policy、Middleware | HTTPとApplicationのAdapter |
| Application | Command／Query Handler、DTO、Use Case調整、Transaction Boundary | Frameworkへ直接依存しない |
| Domain | Aggregate、Entity、Value Object、Enum、Domain Policy、Invariant | LaravelやEloquentへ依存しない |
| Infrastructure | Repository実装、Mapper、Eloquent Model、Query Service、Transaction、Lock | LaravelとPostgreSQLの技術詳細を閉じ込める |

基本的な依存方向は外側から内側です。DomainとApplicationからService Containerの`app()`を直接呼び出さず、Constructor Injectionを使用します。

## ドキュメント構成

### Laravel内部設計

このディレクトリでは、Laravel BackendのArchitecture RuleとLayerごとの実装方針を次の文書で管理します。

| No. | ドキュメント |
| --- | --- |
| 01 | [Backend Architecture 全体方針](./01_Backend%20Architecture%20全体方針.md) |
| 02 | [ディレクトリ構成](./02_ディレクトリ構成.md) |
| 03 | [Domain Layer設計](./03_Domain%20Layer設計.md) |
| 04 | [Application Layer設計](./04_Application%20Layer設計.md) |
| 05 | [Presentation Layer設計](./05_Presentation%20Layer設計.md) |
| 06 | [Infrastructure Layer設計](./06_Infrastructure%20Layer設計.md) |
| 07 | [Repository・Mapper](./07_Repository・Mapper.md) |
| 08 | [CQRS](./08_CQRS.md) |
| 09 | [Transaction](./09_Transaction.md) |
| 10 | [Exception設計](./10_Exception設計.md) |
| 11 | [Laravel Service Container・DI](./11_Laravel%20Service%20Container・DI.md) |
| 12 | [テスト戦略](./12_テスト戦略.md) |

### DDD設計

[`../DDD設計/`](../DDD設計/README.md)では、複数の決定事項を組み合わせた具体的なModelと処理を管理します。

1. [Bounded Context設計](../DDD設計/01_Bounded-Context設計.md)
2. [Aggregate設計](../DDD設計/02_Aggregate設計.md)
3. [Aggregate Root設計](../DDD設計/03_Aggregate-Root/)
4. [Value Object設計](../DDD設計/04_Value-Object設計.md)
5. [Application Layer設計](../DDD設計/05_Application-Layer設計.md)
6. [Repository・Mapper設計](../DDD設計/06_Repository・Mapper設計.md)
7. [Persistence設計](../DDD設計/07_Persistence設計.md)
8. [Transaction・Lock・Concurrency設計](../DDD設計/08_Transaction・Lock・Concurrency設計.md)
9. [Presentation Layer設計](../DDD設計/09_Presentation-Layer設計.md)
10. [Access Control設計](../DDD設計/10_Access-Control設計.md)

## Domain構成

| Bounded Context | 位置付け | 主なModel |
| --- | --- | --- |
| Employee Management | Supporting Domain | Department、Employee |
| Skill Management | Core Domain | SkillCategory、Skill、EmployeeSkill |
| Access Control | Supporting Domain | User、SubManagerAssignment、TeamLeaderAssignment |
| Authentication | Generic Subdomain／Infrastructure寄り | Password、Session、Tokenなどの認証情報 |

MVPではDepartment、Employee、SkillCategory、Skill、EmployeeSkill、UserをAggregate Rootとして扱います。Aggregateは小さく保ち、Aggregate間はObjectではなくValue Object化したIDで参照します。

## WriteとRead

### Write処理

```text
HTTP Request
    ↓
Form Request / Controller
    ↓
Command → CommandHandler
    ↓
Domain Aggregate
    ↓
Repository Interface
    ↓
Repository Implementation / Mapper / Eloquent
    ↓
PostgreSQL
```

- 1 Commandにつき1 CommandHandlerを基本とします。
- 1 Write Use Caseを1 Transactionとして扱います。
- Business InvariantはDomainで保証します。
- Cross Aggregate RuleはApplication、Repository、Database Constraintを組み合わせて保証します。

### Read処理

```text
HTTP Request
    ↓
Controller
    ↓
Query → QueryHandler
    ↓
Query Service
    ↓
Read Model
    ↓
API Resource
```

- 1 Queryにつき1 QueryHandlerを基本とします。
- 一覧、検索、Dashboardでは専用Query Serviceを使用します。
- Read処理でDomain Aggregateの復元を必須としません。
- MVPではCommand BusとQuery Busを導入しません。

## Persistenceと整合性

- Eloquent ModelはInfrastructure Detailとして扱い、Domain Entityと分離します。
- MapperはEloquentとDomainの変換だけを担当します。
- Repository InterfaceはDomain、Repository実装はInfrastructureへ配置します。
- IDには`bigint`を使用し、PostgreSQL SequenceをINSERT前に取得します。
- TransactionはApplication Handlerを境界とし、Repository内部で開始しません。
- PostgreSQLのIsolation LevelはREAD COMMITTEDを基本とします。
- PK、FK、UNIQUE、CHECKを使用し、ApplicationとDatabaseで二重に整合性を守ります。
- Permission Manager最低人数Ruleなどの重要な同時更新には悲観Lockを使用します。

## HTTP、認証・認可、外部表現

- Single Action Controllerを第一候補とし、Controllerを薄く保ちます。
- Form RequestはHTTP Input Validationを担当し、Business InvariantはDomainで保証します。
- Laravel PolicyをHTTP側のAuthorization Adapterとして使用します。
- 重要な権限制御はApplication Layerでも確認します。
- Application ResultをAPI ResourceでOpenAPI Responseへ変換します。
- Eloquent ModelをAPI Responseへ直接公開しません。
- Domain ExceptionにHTTP Statusを持たせず、PresentationでHTTP ErrorへMappingします。
- BrowserとNext.js間はBetter Auth Session、Next.jsとLaravel間はSanctumを使用します。

## Test方針

| 対象 | Test |
| --- | --- |
| Domain | Aggregate、Value Object、Domain PolicyのUnit Test |
| Application | Command／Query Handler、Use CaseのTest |
| Infrastructure | 実PostgreSQLを使用したIntegration Test |
| Presentation | Routing、Validation、Authorization、ResponseのFeature Test |
| Concurrency | Permission Manager Ruleなどの同時更新Test |

Sequence、CHECK Constraint、Transaction、LockなどのPostgreSQL固有動作はSQLiteで代替しません。

## 目的別ナビゲーション

| 目的 | 参照先 |
| --- | --- |
| Architecture Ruleを確認する | [Backend Architecture 全体方針](./01_Backend%20Architecture%20全体方針.md) |
| Domain Modelを設計する | [DDD設計](../DDD設計/README.md) |
| Database Schemaを確認する | [データベース設計](../../../03_システム設計/01_データベース/README.md) |
| 認証フローを確認する | [認証・認可設計](../../../03_システム設計/02_認証・認可/README.md) |
| API契約の運用を確認する | [API設計](../../../03_システム設計/03_API/README.md) |
| Laravelの採用理由を確認する | [バックエンド技術選定](../../../04_技術選定/Backend/README.md) |
| Test ToolとCIを確認する | [テストツール](../../../04_技術選定/Backend/12_Test.md)／[CI/CD方針](../../../06_開発・運用/03_CICD方針.md) |

## 推奨する読み順

1. [Backend Architecture 全体方針](./01_Backend%20Architecture%20全体方針.md)で基本原則を確認し、[ディレクトリ構成](./02_ディレクトリ構成.md)で配置と依存関係を確認する。
2. [Bounded Context設計](../DDD設計/01_Bounded-Context設計.md)と[Aggregate設計](../DDD設計/02_Aggregate設計.md)でDomainの境界を確認する。
3. Aggregate RootとValue Objectの設計で、状態とInvariantを確認する。
4. Application、Repository、Persistence、Transaction設計でUse Caseの実装経路を確認する。
5. PresentationとAccess Control設計でHTTP境界とSecurityを確認する。
6. 実装する機能に対応するLaravel内部設計と[テスト戦略](./12_テスト戦略.md)を参照する。

## 文書管理ルール

- LaravelのArchitecture RuleとLayerごとの実装方針はこのディレクトリの個別文書、具体的なDomain ModelとUse Case設計は`../DDD設計/`へ記録します。
- Architectureを変更した場合は、Domain設計、System Design、Test、OpenAPIへの影響を確認します。
- Frameworkの都合だけでDomainやApplicationの依存方向を逆転させません。
- 文書と実装が異なる場合は、どちらを正とするか確認し、差異を解消します。
- DDDの旧設計は`../DDD設計/90_archive/`へ移動します。Laravel内部設計を退避する場合も、保存先を明示して関連リンクを更新します。
