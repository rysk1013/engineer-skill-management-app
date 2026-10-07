# Laravel DDD設計

Engineer Skill Management App のLaravel Backendにおける、Bounded Context、Aggregate、Value Object、Application Layer、Persistence、Transaction、Presentation、Access Controlの具体設計を管理するディレクトリです。

実装時に守る個別ルールは[Laravel内部設計](../Laravel/README.md)で管理し、このディレクトリでは複数の決定事項を組み合わせたModelと処理の全体像を定義します。

## 設計方針

- Skill ManagementをCore Domainとする
- Employee ManagementとAccess ControlをSupporting Domainとして扱う
- AuthenticationはDomainの中心ではなく、Generic Subdomain／Infrastructure寄りに扱う
- Aggregateは小さく保ち、Aggregate間はDomain ObjectではなくIDで参照する
- Business Ruleや意味を持つ値にはValue ObjectやDomain Enumを使用する
- Write処理ではAggregateとRepository、Read処理ではQuery ServiceとRead Modelを使用する
- Domain AggregateとEloquent Modelを分離し、Mapperで相互変換する
- Transaction BoundaryはApplicationのWrite Use Caseに置く
- Domain Rule、Applicationの事前確認、Database Constraintを組み合わせて整合性を保証する

## Bounded Context

```text
┌────────────────────────┐
│ Employee Management    │
│ Department / Employee  │
└───────────┬────────────┘
            │ EmployeeId
            ▼
┌──────────────────────────────┐
│ Skill Management             │  Core Domain
│ SkillCategory / Skill /      │
│ EmployeeSkill                │
└──────────────────────────────┘

┌────────────────────────┐
│ Access Control         │
│ User / Assignment      │
└────────────────────────┘

Authentication: Generic Subdomain / Infrastructure
```

Context間で共有するModelは最小限にし、基本的にはIDを介して連携します。一覧、検索、Dashboardなど複数Contextを横断する参照処理では、Query ServiceとRead Modelを使用できます。

## Aggregate構成

MVPでは次のModelをAggregate Rootとして扱います。

| Context | Aggregate Root | 主な責務 |
| --- | --- | --- |
| Employee Management | `Department` | 部署情報と有効状態の管理 |
| Employee Management | [`Employee`](./03_Aggregate-Root/Employee.md) | 社員情報、所属、在籍状態、退職状態の管理 |
| Skill Management | [`SkillCategory`](./03_Aggregate-Root/Skill・SkillCategory.md) | スキル分類、名称、有効状態の管理 |
| Skill Management | [`Skill`](./03_Aggregate-Root/Skill・SkillCategory.md) | スキル情報、Category参照、有効状態の管理 |
| Skill Management | [`EmployeeSkill`](./03_Aggregate-Root/EmployeeSkill.md) | 社員のスキルレベル、実務経験、経験期間、最終利用年月の管理 |
| Access Control | `User` | Role、権限管理可否、認証対象との対応の管理 |

`SubManagerAssignment`と`TeamLeaderAssignment`はAggregate Rootではなく、UserとEmployeeを結ぶ軽量なRelationとして扱います。

## 重要なInvariant

### Employee

- Employeeは必ずDepartmentをIDで参照する
- 在籍状態が`RETIRED`の場合は退職日を必須とする
- `ACTIVE`または`LEAVE`の場合は退職日を持たない
- EmployeeSkillやUserをEmployee Aggregateの内部へ保持しない

### EmployeeSkill

- EmployeeとSkillはIDで参照し、作成後に参照先を変更しない
- 実務未経験の場合はLevel 1のみを許可する
- 実務経験ありの場合は経験期間を1か月以上とする
- 実務経験ありの場合は最終利用年月を必須とする
- 不正な組み合わせはDomain Exceptionで拒否する

### Access Control

- 権限管理可能なAdministratorを最低1人維持する
- 最低人数RuleはDomain Policyだけでなく、悲観Lockを使用して同時更新時にも保証する
- Laravel PolicyはHTTP側のAuthorization Adapterとして使用し、重要操作はApplicationでも確認する

## 設計ドキュメント

| No. | ドキュメント | 主な内容 |
| --- | --- | --- |
| 01 | [Bounded Context設計](./01_Bounded-Context設計.md) | Contextの境界、Context Map、Core／Supporting Domain、User Storyとの対応 |
| 02 | [Aggregate設計](./02_Aggregate設計.md) | Aggregate Rootの選定、参照方法、Repository、Cross Aggregate Rule |
| 03 | [Aggregate Root設計](./03_Aggregate-Root/) | Employee、EmployeeSkill、Skill、SkillCategoryのProperty、Behavior、Invariant |
| 04 | [Value Object設計](./04_Value-Object設計.md) | ID、EmployeeNumber、ExperienceMonths、LastUsedMonth、Domain Enumなどの型設計 |
| 05 | [Application Layer設計](./05_Application-Layer設計.md) | Command／Query Handler、DTO、Transaction、Read Model、Exception |
| 06 | [Repository・Mapper設計](./06_Repository・Mapper設計.md) | Interface、Eloquent実装、Mapper、Aggregateの保存・復元 |
| 07 | [Persistence設計](./07_Persistence設計.md) | Infrastructure全体、Eloquent、ID Generator、Query Service、Database Lock |
| 08 | [Transaction・Lock・Concurrency設計](./08_Transaction・Lock・Concurrency設計.md) | Transaction Boundary、悲観Lock、Isolation Level、Concurrency Test |
| 09 | [Presentation Layer設計](./09_Presentation-Layer設計.md) | Controller、Form Request、Policy、Actor Context、API Resource、Error Mapping |
| 10 | [Access Control設計](./10_Access-Control設計.md) | User Aggregate、Role、Permission Manager、Assignment、最低人数Rule |

## Application Layerの処理構成

```text
Presentation
    ├── Command → CommandHandler → Domain → Repository
    └── Query   → QueryHandler   → Query Service → Read Model

Infrastructure
    ├── Repository Implementation
    ├── Mapper / Eloquent Model
    ├── TransactionManager
    ├── ID Generator
    ├── Query Service
    └── Database Lock
```

- CommandとQueryはApplication専用DTOとして定義します。
- 1 Commandにつき1 CommandHandler、1 Queryにつき1 QueryHandlerを基本とします。
- MVPではCommand BusとQuery Busを導入しません。
- Write Use Caseは1 Transactionを基本とし、Repository内部ではTransactionを開始しません。
- 検索やDashboardではDomain Aggregateの復元を必須としません。

## Persistenceの境界

```text
Domain Aggregate
      ⇅ Mapper
Eloquent Model
      ⇅
PostgreSQL
```

- Repository InterfaceはDomain側へ配置し、実装はInfrastructureへ配置します。
- MapperはPersistence表現とDomain表現の変換だけを担当します。
- RepositoryやMapperへBusiness Rule、HTTP処理、独自Transactionを持ち込みません。
- Eloquent RelationはInfrastructure内部で使用できますが、Eloquent ModelをDomain、Application、Presentationへ公開しません。
- IDはPostgreSQL SequenceをINSERT前に取得し、生成時点からDomain Entityへ付与します。

## 関連文書

- [Laravel内部設計](../Laravel/README.md) — 本設計の前提となる個別Rule
- [要件定義](../../../01_要件定義/README.md) — Epic、User Story、Acceptance Criteria
- [システム設計](../../../03_システム設計/README.md) — Database、認証・認可、APIの具体設計
- [`99_archive`](./99_archive/) — 現在の設計へ統合される前の旧文書

## 推奨する読み順

1. [Bounded Context設計](./01_Bounded-Context設計.md)で、業務領域の境界を把握する。
2. [Aggregate設計](./02_Aggregate設計.md)で、整合性を守る単位とAggregate間の関係を確認する。
3. [Aggregate Root設計](./03_Aggregate-Root/)と[Value Object設計](./04_Value-Object設計.md)で、Modelの状態とInvariantを確認する。
4. [Application Layer設計](./05_Application-Layer設計.md)で、Use CaseとWrite／Readの処理経路を確認する。
5. Repository、Mapper、Persistence、Transaction設計で、DomainとPostgreSQLの接続方法を確認する。
6. Presentation LayerとAccess Control設計で、HTTP境界、Actor、認証・認可を確認する。

## 文書管理ルール

- Domain Ruleを変更した場合は、関連するAggregate、Value Object、Application Use Case、Database Constraint、Testを確認します。
- Aggregate境界を変更した場合は、Repository、Transaction、API、Read Modelへの影響を確認します。
- DDD用語と要件定義・コード上の業務用語を揃えます。
- Framework固有のClassやEloquent ModelをDomain設計へ持ち込みません。
- 旧設計は削除や上書きをせず、`99_archive/`へ移動します。
