# MVP完了条件

## 1. 目的

本ドキュメントは、Engineer Skill Management App のMVP実装について、どの状態をもって「MVP実装完了」と判断するかを定義する。

MVP完了を単なるコード実装完了ではなく、要件、API契約、Database、認証・認可、テスト、品質、ドキュメントを含めて、Staging環境で検証できる状態として定義する。

本ドキュメントはMVP実装のDefinition of Doneとして使用する。

---

## 2. MVP完了の定義

MVP実装完了は以下の状態とする。

```text id="8i5f9g"
MVP Scopeの機能実装完了
        +
主要User Flow動作
        +
OpenAPI整合
        +
Database整合
        +
Authentication / Authorization
        +
Test / Quality Check
        +
必要な非機能要件
        +
Documentation更新
        +
Staging Ready
        +
Blockerなし
        ↓
MVP Implementation Complete
```

単にコードを書き終えた状態はMVP完了とはしない。

```text id="qj6u4c"
コード実装完了
      ×

APIが動作
      ×

主要機能が一応動作
      ×

MVPとして必要な機能・品質を満たし
Stagingで検証できる
      ○
```

---

## 3. MVP / Staging / Productionの境界

MVP実装完了とProduction Readyは分離する。

```text id="mbdtfj"
MVP Implementation
        ↓
MVP完了条件を満たす
        ↓
Ready for Staging
        ↓
Staging Deploy
        ↓
Staging Verification
        ↓
必要な修正
        ↓
Production Ready
        ↓
Production
```

本ドキュメントでは「Stagingへ進める状態」をMVP実装完了として扱う。

Production環境固有の要件や本番運用開始条件については、MVP完了条件には含めない。

---

## 4. 判定原則

MVP完了判定では以下を基本原則とする。

1. MVP Scopeのみを判定対象とする
2. MVP外の未実装機能を理由に未完了とはしない
3. API単体ではなく主要User Flowまで確認する
4. OpenAPIと実装の重大な乖離を残さない
5. Authentication / Authorizationを重点確認する
6. Domain Invariantを保証する
7. Database Constraintを最終防衛線として機能させる
8. 必要なTestおよびCIが成功する
9. Source of Truthとなるドキュメントを実装と同期させる
10. MVP進行を妨げるBlockerを残さない

完璧なシステムを完成させることではなく、MVPとして定義した範囲を信頼してStagingへ進められることを目的とする。

---

# 5. MVP Scope

MVP対象機能が既存の要件定義に従って実装されていることを確認する。

主なSource of Truthは以下とする。

- MVP
- User Story
- Acceptance Criteria
- 画面一覧・画面遷移
- MVP API一覧
- 個別API設計

MVP対象外の機能については、必要に応じてBacklog / Future Scopeとして管理する。

```text id="yxwpfm"
MVP Scope
    ↓
完了判定対象

Non-MVP Scope
    ↓
Backlog / Future
    ↓
MVP完了を妨げない
```

### 完了条件

- [ ] MVP Scopeが明確である
- [ ] MVP対象User Storyが実装されている
- [ ] MVP対象Acceptance Criteriaを満たしている
- [ ] MVP対象画面が利用可能である
- [ ] MVP対象APIが実装されている
- [ ] MVP外機能がMVP完了条件へ混入していない

---

# 6. Functional

MVPの主要FeatureがEnd-to-Endで利用可能であることを確認する。

対象Featureは以下とする。

```text id="vb5r26"
Authentication
      +
Employee
      +
Skill
      +
EmployeeSkill
      +
Access Control
      +
Dashboard
```

---

## Authentication

以下を確認する。

- [ ] ログインできる
- [ ] ログアウトできる
- [ ] Auth.js Sessionを利用できる
- [ ] BFFから認証済みユーザーを識別できる
- [ ] Sanctum Tokenを利用してLaravel APIへアクセスできる
- [ ] Laravelで認証済みユーザーを識別できる
- [ ] 未認証アクセスが適切に拒否される

---

## Employee

以下を確認する。

- [ ] Employee一覧を利用できる
- [ ] Employee詳細を利用できる
- [ ] Employeeを登録できる
- [ ] Employeeを更新できる
- [ ] MVPで必要なその他のEmployee操作を利用できる
- [ ] Departmentとの必要な関連が機能する
- [ ] 在籍状態を適切に扱える
- [ ] 退職情報を既存要件に従って扱える

---

## Skill

以下を確認する。

- [ ] SkillCategoryを利用できる
- [ ] Skillを一覧・参照できる
- [ ] Skillを追加できる
- [ ] Skillを更新できる
- [ ] Skillを無効化できる
- [ ] Skillを完全削除しない既存ルールが守られている
- [ ] マスタに存在しない技術を自由入力できない

---

## EmployeeSkill

以下を確認する。

- [ ] EmployeeSkillを登録できる
- [ ] EmployeeSkillを参照できる
- [ ] EmployeeSkillを更新できる
- [ ] MVPで必要な解除・削除操作を利用できる
- [ ] EmployeeとSkillを適切に参照している

### 実務未経験

```text id="zfjpcu"
WorkExperience = 未経験
        ↓
SkillLevel = Level 1のみ
        ↓
経験期間なし
        ↓
最終利用年月なし
```

- [ ] 未経験ではLevel 1のみ選択できる
- [ ] 未経験では経験期間を保持しない
- [ ] 未経験では最終利用年月を保持しない

### 実務経験あり

```text id="22xdzd"
WorkExperience = 経験あり
        ↓
経験期間 >= 1か月
        ↓
最終利用年月必須
        ↓
SkillLevel = Level 1〜5
```

- [ ] 経験期間1か月未満を許可しない
- [ ] 最終利用年月が必須である
- [ ] SkillLevel 1〜5を扱える
- [ ] 不正な状態をDomainで生成・更新できない
- [ ] EmployeeSkillの重複が防止されている

---

## Access Control

対象Roleは以下とする。

- Administrator
- Manager
- Sub Manager
- Team Leader

以下を確認する。

- [ ] Roleを適切に扱える
- [ ] Managerが要件どおり操作できる
- [ ] Sub Managerが担当社員のみ操作できる
- [ ] 1社員へ複数Sub Managerを割り当てられる
- [ ] Team Leaderが担当社員を閲覧できる
- [ ] Team Leaderが変更操作できない
- [ ] 担当外社員へのアクセスが拒否される
- [ ] 権限管理可能なAdministratorのみ権限管理できる

### 管理権限保持者

以下のInvariantを保証する。

```text id="j7jycf"
role = ADMINISTRATOR
        +
can_manage_permissions = true
        ↓
最低1人必須
```

- [ ] 条件を満たすAdministratorが最低1人存在する
- [ ] 0人になる更新を拒否する
- [ ] 競合更新でもInvariantが維持される
- [ ] 必要なTransaction / Pessimistic Lockが機能する

---

## Dashboard

以下を確認する。

- [ ] MVP対象Dashboardを表示できる
- [ ] 必要な集計データを取得できる
- [ ] 在籍社員のみが集計対象となる
- [ ] Query Service / Read Modelを既存設計に従って利用している
- [ ] Roleに応じたAuthorizationが適用されている

---

# 7. API / OpenAPI

OpenAPIはBackend API契約のSource of Truthとする。

```text id="ztjm48"
OpenAPI
   ├── Laravel Backend
   │
   └── TypeScript型
          ↓
      Next.js BFF
```

以下を確認する。

### Specification

- [ ] MVP対象APIがOpenAPIに定義されている
- [ ] Path / HTTP Methodが正しい
- [ ] Request Schemaが正しい
- [ ] Response Schemaが正しい
- [ ] Error Responseが共通仕様と整合している
- [ ] Authenticationが適切に定義されている
- [ ] Validation Constraintが定義されている
- [ ] operationIdが適切に定義されている

### Validation

- [ ] Redocly Lintが成功する
- [ ] OpenAPI Bundleが成功する
- [ ] openapi-typescriptによる型生成が成功する
- [ ] Generated Typeを手動変更していない

### Implementation

- [ ] Laravel BackendがOpenAPI契約に従っている
- [ ] Next.js BFFがGenerated Typeを利用している
- [ ] OpenAPIと実装に重大な乖離がない
- [ ] Backend APIをBrowserから直接利用する構成になっていない

---

# 8. Database

PostgreSQL Schemaが既存Database設計と一致し、必要な整合性を保証していることを確認する。

## Migration

- [ ] MVPに必要なMigrationが存在する
- [ ] Migrationを正常に適用できる
- [ ] クリーンなPostgreSQLへ最初からMigrationを適用できる
- [ ] Migration順序が正しい
- [ ] SchemaがDatabase設計と一致している

## Constraint

必要な箇所で以下が機能していることを確認する。

- [ ] PRIMARY KEY
- [ ] FOREIGN KEY
- [ ] UNIQUE
- [ ] CHECK
- [ ] NOT NULL

特にEmployeeSkillの重複については、Applicationで確認するとともにDatabase UNIQUE Constraintを最終防衛線として利用する。

## Transaction / Concurrency

- [ ] 1 UseCase = 1 Transactionの既存方針に従っている
- [ ] Transaction失敗時にRollbackされる
- [ ] 必要なUseCaseでPessimistic Lockを利用している
- [ ] 複数Lock時の順序が既存設計に従っている
- [ ] Access Controlの競合更新でInvariantが破壊されない

---

# 9. Authentication / Authorization

AuthenticationおよびAuthorizationをMVP完了の重点確認項目とする。

## Authentication

- [ ] Auth.js Sessionが正常に機能する
- [ ] Session Storeが正常に機能する
- [ ] BFF → Laravel間でSanctum Token認証が機能する
- [ ] 未認証アクセスが拒否される
- [ ] 無効な認証情報が拒否される

## Authorization

以下のRoleについて期待するアクセス範囲を確認する。

| Role | 確認対象 |
|---|---|
| Administrator | 管理操作・権限管理 |
| Manager | 全社員操作 |
| Sub Manager | 担当社員のみ操作 |
| Team Leader | 担当社員の閲覧のみ |

- [ ] 許可された操作を実行できる
- [ ] 許可されていない操作が拒否される
- [ ] 担当外Employeeへアクセスできない
- [ ] UI非表示だけにAuthorizationを依存していない
- [ ] Laravel BackendでAuthorizationを最終保証している
- [ ] 不正な権限昇格を許可しない

---

# 10. Test / Quality

必要なTestおよび品質確認が完了していることを確認する。

## Backend

- [ ] 重要なDomain InvariantにDomain Testが存在する
- [ ] 主要UseCaseに必要なApplication Testが存在する
- [ ] API境界に必要なFeature / API Testが存在する
- [ ] 必要なInfrastructure Testが存在する
- [ ] Backend Testがすべて成功する

## Frontend

- [ ] 重要なComponent / User Interactionが確認されている
- [ ] Form Validationが確認されている
- [ ] Loading / Error UIが確認されている
- [ ] 必要なFrontend Testが存在する
- [ ] Frontend Testがすべて成功する

## Integration

- [ ] 主要Vertical SliceがEnd-to-Endで動作する
- [ ] 正常系が確認されている
- [ ] 主要な異常系が確認されている
- [ ] Error ResponseがFrontendまで適切に伝播する

## E2E

- [ ] 主要User Flowに必要なE2E Testが存在する
- [ ] 主要E2E Testが成功する
- [ ] 複数Featureを横断する主要フローが確認されている

## Static Quality

- [ ] Frontend Lintが成功する
- [ ] Frontend Type Checkが成功する
- [ ] Frontend Buildが成功する
- [ ] Backend Static Analysisが成功する
- [ ] Backend Code Quality Checkが成功する
- [ ] OpenAPI Validationが成功する

Code Coverageの固定数値はMVP完了条件としない。

重要なDomain Invariant、Authorization、主要UseCaseが適切にTestされていることを優先する。

---

# 11. Non-Functional Requirements

`07_非機能要件` をSource of Truthとして、MVP / Staging移行時点で必要な項目を満たしていることを確認する。

主な確認対象は以下とする。

## Security

- [ ] MVP時点で必要なSecurity要件を満たしている
- [ ] Authentication / Authorizationが適切に実装されている
- [ ] Sensitive Dataを不必要に露出していない
- [ ] Validation / Error Responseが安全に処理されている

## Performance

- [ ] 主要画面・APIに明らかな性能問題がない
- [ ] 不要な大量Query等がない
- [ ] MVP想定規模で利用可能な性能を満たしている

## Logging / Audit

- [ ] 必要なApplication Logを取得できる
- [ ] MVPで必要なAudit Logを取得できる
- [ ] Sensitive Dataを不適切にLogへ出力していない

## Observability

- [ ] MVP / Stagingで必要な監視情報を取得できる
- [ ] 障害調査に必要な最低限の情報を確認できる

## Accessibility / Usability

- [ ] 主要画面をKeyboardで操作できる
- [ ] Form / Errorが理解可能である
- [ ] 主要UIに重大なAccessibility問題がない
- [ ] Loading / Feedbackが適切に表示される

## Compatibility

- [ ] MVP対象Browserで主要User Flowを利用できる

## Date / Time

- [ ] Date / Time処理が既存設計に従っている
- [ ] 最終利用年月等の業務日時を正しく扱える
- [ ] Frontend / Backend / Database間で日時表現に重大な不整合がない

---

# 12. Documentation

実装とSource of Truthとなるドキュメントが同期していることを確認する。

```text id="u4qv1f"
Requirements
     ↓
Architecture
     ↓
System Design
     ↓
OpenAPI
     ↓
Implementation
```

すべての実装変更で全ドキュメントを更新する必要はない。

変更による影響があるSource of Truthのみ更新する。

### 完了条件

- [ ] 要件変更がある場合、要件定義が更新されている
- [ ] Architecture変更がある場合、Architecture Documentが更新されている
- [ ] Database変更がある場合、Database設計が更新されている
- [ ] API変更がOpenAPIへ反映されている
- [ ] 認証・認可変更が関連設計へ反映されている
- [ ] 技術選定変更がある場合、技術選定Documentが更新されている
- [ ] 非機能要件変更がある場合、関連Documentが更新されている
- [ ] 実装とドキュメントに既知の重大な乖離がない

---

# 13. CI

MVPとして必要な自動品質確認をCIで実行できることを確認する。

```text id="xf6g38"
OpenAPI
├── Lint
├── Bundle
└── Type Generation

Frontend
├── Lint
├── Type Check
├── Test
└── Build

Backend
├── Code Quality
├── Static Analysis
└── Test
```

### 完了条件

- [ ] OpenAPI関連CIが成功する
- [ ] Frontend関連CIが成功する
- [ ] Backend関連CIが成功する
- [ ] Test失敗時にCIが失敗する
- [ ] Static Analysis失敗時にCIが失敗する
- [ ] Build失敗時にCIが失敗する
- [ ] MVPのMain Branchが正常なCI状態である

---

# 14. Staging Ready

MVP実装完了後にStaging環境へ進める状態であることを確認する。

この段階では、実際にStagingへDeploy済みであることをMVP実装完了条件とはしない。

```text id="sg97xb"
MVP Implementation Complete
          ↓
Ready for Staging
          ↓
Staging Deploy
```

主な確認対象は以下とする。

- [ ] FrontendをBuildできる
- [ ] BackendをStaging向けに起動できる構成になっている
- [ ] 必要なDocker構成が整っている
- [ ] Stagingで必要な環境変数が整理されている
- [ ] Database Migrationを適用できる
- [ ] 必要な初期データ投入方法が整理されている
- [ ] CIが成功している
- [ ] Staging Deployを妨げる既知の問題がない

Staging Platform固有の詳細設定は `06_開発・運用` の関連ドキュメントで管理する。

---

# 15. Known Issue / Blocker

既知のIssueが1件でも存在することを理由にMVP未完了とはしない。

IssueがMVP / Staging移行を妨げるかで判断する。

```text id="5dz4vz"
Known Issue
     ↓
MVP / Stagingを妨げるか
      /             \
    Yes             No
     ↓               ↓
  Blocker       記録して進行可
```

## Blockerの例

以下のような問題は原則としてBlockerとする。

- Core User Flowが実行できない
- データ破損の可能性がある
- Authenticationを回避できる
- Authorizationを回避できる
- 担当外Employeeの情報へアクセスできる
- 重要なDomain Invariantが破壊される
- Database Migrationが失敗する
- OpenAPIと実装に重大な乖離がある
- 主要Testが失敗する
- CIが失敗する
- Applicationを正常にBuildできない
- Stagingへの移行を妨げる重大な問題がある

## Non-Blockerの例

MVPの主要目的を妨げない軽微な問題については、記録した上でStagingへ進むことを許容する。

例：

- 軽微なUI調整
- 文言改善
- MVP利用を妨げない小さなUX改善
- 将来的なPerformance Optimization
- MVP外機能

Non-Blockerについては放置するのではなく、Issue / Backlogとして追跡可能な状態にする。

---

# 16. Master Checklist

MVP実装完了の最終判定では以下を確認する。

## Scope

- [ ] MVP Scopeが実装されている
- [ ] Acceptance Criteriaを満たしている
- [ ] MVP外機能を完了条件へ含めていない

## Feature

- [ ] Authentication
- [ ] Employee
- [ ] Skill
- [ ] EmployeeSkill
- [ ] Access Control
- [ ] Dashboard

## API

- [ ] MVP OpenAPI定義完了
- [ ] OpenAPI Lint成功
- [ ] OpenAPI Bundle成功
- [ ] TypeScript型生成成功
- [ ] OpenAPIと実装の重大な乖離なし

## Database

- [ ] Migration成功
- [ ] クリーンDatabaseからMigration可能
- [ ] 必要なConstraintが機能する
- [ ] Transaction / Lockが機能する

## Authentication / Authorization

- [ ] Authentication確認完了
- [ ] RoleごとのAuthorization確認完了
- [ ] 担当範囲制御確認完了
- [ ] 権限管理Invariant確認完了

## Test / Quality

- [ ] Backend Test成功
- [ ] Frontend Test成功
- [ ] Integration確認完了
- [ ] 主要E2E Test成功
- [ ] Static Analysis成功
- [ ] Lint成功
- [ ] Type Check成功
- [ ] Build成功

## Non-Functional

- [ ] Security確認完了
- [ ] Performance確認完了
- [ ] Logging / Audit確認完了
- [ ] Observability確認完了
- [ ] Accessibility / Usability確認完了
- [ ] Compatibility確認完了
- [ ] Date / Time確認完了

## Documentation

- [ ] OpenAPI最新
- [ ] Database設計最新
- [ ] 関連Architecture / System Design最新
- [ ] 実装との重大なDocument Driftなし

## Delivery

- [ ] CI成功
- [ ] Staging Ready
- [ ] Blockerなし
- [ ] Non-Blockerが必要に応じてIssue / Backlog化されている

---

# 17. MVP完了判定

Master Checklistを確認し、MVP / Staging移行を妨げるBlockerが存在しない場合、MVP実装完了とする。

```text id="9g1r0p"
MVP Scope
    +
Functional
    +
OpenAPI
    +
Database
    +
Authentication / Authorization
    +
Test / Quality
    +
Non-Functional Requirements
    +
Documentation
    +
CI
    +
Staging Ready
    +
No Blocker
        ↓
MVP Implementation Complete
        ↓
Ready for Staging
```

### Status

- [ ] Not Ready
- [ ] Ready for Staging

判定日：

```text id="kn5kvl"
YYYY-MM-DD
```

確認者：

```text id="ve2ckz"
-
```

Known Non-Blocker：

```text id="ihxfma"
-
```

---

# 18. MVP完了後

MVP実装完了後はStaging工程へ進む。

```text id="w95jkp"
MVP Implementation Complete
        ↓
Staging Deploy
        ↓
Staging Verification
        ↓
Bug Fix / Adjustment
        ↓
Production Readiness確認
        ↓
Production Deploy
```

Stagingでは実環境に近い条件で、

- Deploy
- Migration
- Authentication
- User Flow
- Authorization
- Logging
- Observability
- Performance
- Environment Configuration

などを確認する。

Stagingで問題が発見された場合は、原因となる設計・実装まで戻って修正し、必要なTestおよびDocumentationを更新する。

MVP実装完了は開発の終了ではなく、Stagingでの統合検証へ進むためのGateとして扱う。
