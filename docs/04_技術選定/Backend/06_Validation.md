# Backend 技術・Library選定 - Validation

## 1. 目的

本ドキュメントでは、Engineer Skill Management App BackendにおけるValidation設計方針を定義する。

対象：

- HTTP Request Validation
- Application Validation
- Domain Invariant
- Database Constraint
- Laravel Form Request
- Laravel Validation Rule
- Conditional Validation
- Enum Validation
- Entity ID Validation
- YearMonth Validation
- Validation Error Response
- Validation Test

本Projectでは、Validationを1箇所へ集中させず、

```text id="g0v35g"
HTTP Request
    ↓
① Presentation Validation
    ↓
② Application Validation
    ↓
③ Domain Invariant
    ↓
④ Database Constraint
```

の4層で責務分離する。

---

# 2. Validation基本方針

Validationは単なるHTTP Input Checkではない。

Layerごとに異なる責務を持つ。

| Layer | 責務 |
|---|---|
| Presentation | HTTP Inputとして正しいか |
| Application | UseCaseを現在Stateで実行可能か |
| Domain | Business Rule / Invariantを満たすか |
| Database | Data Integrityを最終防衛できるか |

---

# 3. Validationを1Layerへ集中しない

以下のような設計は採用しない。

```text id="k1fn0u"
Form Request
    ↓
すべてのBusiness RuleをValidation
```

または、

```text id="xhyy1o"
Domain
    ↓
HTTP Input FormatまでValidation
```

のような責務混在を避ける。

---

# 4. Defense in Depth

同じRequirementが複数Layerで防御されることを許容する。

例：

```text id="njtp2z"
EmployeeSkill Duplicate

Presentation
    → optional early check

Application
    → duplicate check

Database
    → UNIQUE constraint
```

これは重複実装ではなく、目的の異なる多層防御として扱う。

---

# 5. Presentation Validation

HTTP Request ValidationにはLaravel Form Requestを採用する。

```text id="hxaudq"
HTTP Request
    ↓
Form Request
    ↓
validated data
```

Controller内へ大量のValidation Ruleを書かない。

---

# 6. Form Request責務

Form RequestはHTTP InputとしてのValidityを確認する。

対象例：

```text id="516hik"
required
nullable
string
integer
boolean
array
min
max
between
date
date_format
enum
exists
unique
```

---

# 7. Form Requestへ置かないもの

以下をForm Requestへ集中させない。

```text id="vpllyy"
Complex Business Rule
Domain State Transition
Aggregate Invariant
Large Database Join
Transaction
UseCase Execution
Permission Management Invariant
```

---

# 8. Controller

ControllerはValidation Logicを持たない。

```text id="bywl1w"
Form Request
    ↓
validated()
    ↓
Primitive / Enum / VO
    ↓
Command / Query
```

とする。

---

# 9. Form RequestをApplicationへ渡さない

禁止：

```php id="nzcwv3"
$handler->handle($request);
```

Application LayerはLaravel HTTP Requestへ依存しない。

---

# 10. Application Validation

Application Validationは、

> このUseCaseを現在Stateで実行可能か

を判定する。

対象例：

```text id="xypc8v"
Employeeが存在するか
Skillが存在するか
SkillがActiveか
Target Employeeが操作可能Stateか
EmployeeSkillがDuplicateしていないか
Operationが現在Stateで許可されるか
```

---

# 11. Application Validationの配置

Application Handlerを中心に実施する。

例：

```text id="gqrhlk"
Command
    ↓
Handler
    ↓
Repository / Query
    ↓
Current State確認
    ↓
Domain Behavior
```

---

# 12. Handlerへ置かないもの

Handlerへ複雑なBusiness Ruleを蓄積しない。

```text id="f6t4no"
if (...)
if (...)
if (...)
if (...)
```

がBusiness Ruleを表している場合はDomainへ移すことを検討する。

HandlerはUseCase Orchestrationを担当する。

---

# 13. Domain Validation

DomainではBusiness Invariantを保証する。

Domain Objectが不正Stateにならないことを最優先する。

---

# 14. Domain Invariantの実装手段

以下を利用する。

```text id="m6whx8"
Factory Method
Constructor
Behavior Method
Value Object
Enum
Domain Service
Domain Exception
```

---

# 15. Generic Setter不採用

以下のような設計を避ける。

```php id="5kxf4x"
$employeeSkill->setSkillLevel($level);
$employeeSkill->setExperienceMonths($months);
```

代わりに、意味のあるBehaviorを利用する。

---

# 16. EmployeeSkill Invariant

EmployeeSkillでは以下をDomain Ruleとして保証する。

### 実務未経験

```text id="bl8pqf"
WorkExperience = Unexperienced

SkillLevel
    → Level 1 only

Experience Period
    → unset

Last Used YearMonth
    → unset
```

### 実務経験あり

```text id="cbb59l"
WorkExperience = Experienced

SkillLevel
    → Level 1〜5

Experience Period
    → 1 month以上

Last Used YearMonth
    → required
```

---

# 17. Domain RuleはPresentationだけに依存しない

例えばForm Requestで、

```text id="o26khx"
未経験ならLevel1
```

を確認していても、Domainでも必ずInvariantを保証する。

Presentation ValidationをBypassしたApplication Callや将来のBatch処理でも不正Stateを作れないようにする。

---

# 18. Database Constraint

DatabaseはData Integrityの最終防衛線とする。

採用：

```text id="2zlr54"
PRIMARY KEY
FOREIGN KEY
UNIQUE
CHECK
NOT NULL
```

---

# 19. DBへ置くRule

DB Constraintに向いているもの：

```text id="rnp2jr"
Foreign Key Integrity
Duplicate Prevention
Simple Range
NOT NULL
Simple Cross-column Constraint
```

複雑なBusiness MeaningはDomainへ置く。

---

# 20. EmployeeSkill Duplicate

EmployeeSkill Duplicateは、

```text id="ojx63g"
Application
    → existence check

Database
    → UNIQUE(employee_id, skill_id)
```

の二重防御とする。

Presentationで早期Checkを追加してもよいが、Correctnessの前提にはしない。

---

# 21. Race Condition

以下だけでは不十分。

```text id="34f7ca"
SELECT exists
    ↓
not exists
    ↓
INSERT
```

Concurrent RequestによりRace Conditionが起きる可能性がある。

最終防衛：

```text id="w0m6n3"
UNIQUE Constraint
```

とする。

---

# 22. Rule分類

| Rule | Presentation | Application | Domain | Database |
|---|---:|---:|---:|---:|
| Required Field | ✅ |  |  | NOT NULLの場合あり |
| Type | ✅ |  | VO変換時 |  |
| String Length | ✅ |  | 必要時 | CHECK候補 |
| Enum | ✅ |  | ✅ | CHECK候補 |
| Record Exists | `exists`補助 | ✅ |  | FK |
| Record Active |  | ✅ | 必要時 |  |
| State Transition |  |  | ✅ |  |
| 未経験→Level1 | 補助可能 |  | ✅ | 必要ならCHECK候補 |
| Experience >= 1 month | 補助可能 |  | ✅ | CHECK候補 |
| Duplicate | 補助可能 | ✅ |  | UNIQUE |
| Authorization |  | Policy | Domain Ruleとは別 |  |

---

# 23. Laravel Built-in Rule優先

HTTP ValidationではLaravel Built-in Ruleを優先する。

例：

```php id="avgaoc"
[
    'name' => ['required', 'string', 'max:255'],
]
```

単純なValidationのために独自Rule Classを増やさない。

---

# 24. Rule Object

条件が複雑になる場合やType-safeに表現しやすい場合はLaravelの`Rule` APIを利用する。

例：

```php id="xfwiy5"
Rule::enum(SkillLevel::class)
```

---

# 25. Native Enum Validation

PHP Native Enumを採用する。

例：

```php id="up9mdf"
Rule::enum(WorkExperience::class)
```

HTTP string / intをApplicationへ渡す前にEnumへ変換する。

---

# 26. Enum Flow

```text id="m7jdqw"
HTTP
    ↓
Form Request
    ↓
Backed Value
    ↓
Native Enum
    ↓
Command
```

Applicationへ未変換stringを長期間持ち込まない。

---

# 27. Conditional Validation

Simple ConditionにはLaravel Built-in Ruleを利用する。

候補：

```text id="7k94te"
required_if
required_unless
prohibited_if
prohibited_unless
```

---

# 28. `Rule::requiredIf`

条件がCodeとして表現した方が読みやすい場合：

```php id="meq7td"
Rule::requiredIf(...)
```

を利用する。

---

# 29. Conditional Validationの限界

Conditional ValidationはHTTP Request Shapeを検証するために利用する。

Domain Invariantの代替にはしない。

---

# 30. Prohibited Rule

Business Rule上、HTTP RequestにFieldが存在してはいけない場合、

```text id="6u3ceh"
prohibited_if
Rule::prohibitedIf(...)
```

等を利用できる。

例：

```text id="h55ml8"
work_experience = unexperienced

experience_months
    → prohibited

last_used_year_month
    → prohibited
```

ただし最終InvariantはDomainでも保証する。

---

# 31. `exists`

Laravel `exists` RuleをHTTP Validationの補助として利用できる。

例：

```text id="9ljgzy"
skill_id
    ↓
exists
```

ただし、

```text id="jkfg6d"
exists rule
    ≠
Application Entity Lookup
```

とする。

---

# 32. `exists`の責務

`exists`は、

```text id="zot1jq"
HTTP Inputとして明らかに存在しないIDを早期Reject
```

するための補助。

ApplicationではUseCase実行時に必要なEntityを改めて取得する。

DBではFKを利用する。

---

# 33. `unique`

`unique` Ruleも早期Feedbackに利用可能。

ただし、

```text id="806mev"
unique Form Request
    ≠
Application Duplicate Check
    ≠
Database UNIQUE
```

とする。

---

# 34. Database Query in Form Request

Laravel標準の、

```text id="l3a26k"
exists
unique
```

程度のDatabase Accessは許容する。

---

# 35. Form Requestで避けるDB Logic

避ける：

```text id="3r9mde"
Large Join
複雑なState判定
Business-specific Query
Permission Calculation
Multiple Aggregate Traversal
UseCase Decision
```

これらはApplication / Policy / Domainへ置く。

---

# 36. Custom Validation Rule

Custom Validation Ruleは以下の場合に限定する。

```text id="hqr3g7"
Built-in Ruleでは自然に表現できない
HTTP Input Conceptとして再利用価値がある
Presentation Layer責務である
```

---

# 37. Custom Ruleへ置かないもの

以下をCustom Validation Ruleへ入れない。

```text id="nmy6vb"
Aggregate Invariant
UseCase Logic
Complex Repository Access
Authorization
Transaction
```

---

# 38. Entity ID API Contract

Entity IDはHTTP API上ではstringとして扱う。

```text id="st5x42"
Database
    ↓
PostgreSQL bigint

PHP
    ↓
positive int
    ↓
Typed ID Value Object

API
    ↓
positive decimal digit string

TypeScript
    ↓
string
```

---

# 39. ID Input

HTTP Request Example：

```json id="zwti1a"
{
  "employee_id": "123",
  "skill_id": "45"
}
```

API Contract上、以下のnumber形式を正式表現として採用しない。

```json id="1lb84j"
{
  "employee_id": 123
}
```

---

# 40. ID Format Validation

API Entity IDは、

```text id="j7ui44"
^[1-9][0-9]*$
```

に相当する正の10進数字文字列としてValidationする。

---

# 41. ID不正例

以下はRejectする。

```text id="gpc5ls"
"0"
"-1"
"+1"
"1.5"
"001"
" 123 "
"abc"
"12abc"
```

Normalization方針によってWhitespace Trim後にValidationする場合でも、Canonical API Representationは正の10進数字文字列とする。

---

# 42. PHP int Range

Formatとして正しくてもPHP `int`で安全に扱えない値はRejectする。

例：

```text id="8azd84"
"9223372036854775808"
```

64-bit PHP環境で`PHP_INT_MAX`を超える値はTyped IDへ変換しない。

---

# 43. ID Validation Flow

```text id="vwnkkf"
HTTP
"123"
    ↓
Form Request
Positive Decimal Digit String
    ↓
Range Check
    ↓
PHP int
123
    ↓
EmployeeId
```

---

# 44. ID Domain Conversion

Application / DomainへHTTP string IDをそのまま渡さない。

```text id="u6a2ft"
"123"
    ↓ Presentation
123
    ↓
EmployeeId
    ↓
Command / Query
```

とする。

---

# 45. Semantic ID

Primitive表現が同じでもTyped IDを分ける。

例：

```text id="pqspxx"
EmployeeId
SkillId
DepartmentId
UserId
SkillCategoryId
```

誤ったIDの取り違えをTypeで防ぐ。

---

# 46. OpenAPI ID Schemaとの整合

OpenAPIではSemantic IDごとにstring Schemaを定義する。

例：

```yaml id="ufdpsv"
EmployeeId:
  type: string
  pattern: '^[1-9][0-9]*$'
  example: '123'
```

Form Request実装はこのContractへ従う。

---

# 47. YearMonth Validation

最終利用年月には`YearMonth` Conceptを利用する。

API表現：

```text id="8zmkqp"
YYYY-MM
```

例：

```text id="j2l60e"
2026-09
```

---

# 48. YearMonth Pattern

OpenAPI：

```text id="auaq9f"
^[0-9]{4}-(0[1-9]|1[0-2])$
```

を基準とする。

---

# 49. YearMonth Custom Validation

Laravel Built-in Ruleだけで意図が分かりづらい場合、YearMonth用Custom Ruleを作成してよい。

例：

```text id="tqcyml"
ValidYearMonth
```

これはHTTP Input ConceptであるためPresentation Layer責務とする。

---

# 50. YearMonth Conversion

Validation後：

```text id="mod8ks"
"2026-09"
    ↓
YearMonth
```

へ変換する。

Applicationへstringとして長期間保持しない。

---

# 51. YearMonth Database Representation

Validation LayerはDatabase Persistence形式を意識しすぎない。

```text id="1u61ns"
API
    → YYYY-MM

Domain
    → YearMonth VO

Infrastructure
    → PostgreSQL date / first day of month
```

への変換はMapper / Infrastructure責務とする。

---

# 52. Experience Period

API / Internal Representation：

```text id="hdjgbi"
experience_months
```

を整数Total Monthsとして扱う。

例：

```json id="73eq3y"
{
  "experience_months": 27
}
```

---

# 53. Experience Period HTTP Validation

Presentationでは少なくとも、

```text id="6ca9vn"
integer
minimum
conditional required / prohibited
```

を確認する。

---

# 54. Experience Period Domain Validation

Domainでは、

```text id="15vmce"
Experienced
    → ExperiencePeriod >= 1 month
```

をInvariantとして保証する。

---

# 55. EmployeeSkill Request Example

例：

```json id="5ugbsy"
{
  "employee_id": "123",
  "skill_id": "45",
  "work_experience": "experienced",
  "skill_level": 3,
  "experience_months": 24,
  "last_used_year_month": "2026-09"
}
```

---

# 56. EmployeeSkill Presentation Validation

概念：

```text id="lxn5i3"
employee_id
    → positive digit string

skill_id
    → positive digit string

work_experience
    → enum

skill_level
    → integer
    → 1〜5

experience_months
    → integer
    → conditional

last_used_year_month
    → YYYY-MM
    → conditional
```

---

# 57. 未経験Request

例：

```json id="6o3zsc"
{
  "employee_id": "123",
  "skill_id": "45",
  "work_experience": "unexperienced",
  "skill_level": 1
}
```

この場合、

```text id="ix3fxe"
experience_months
last_used_year_month
```

は送信しないContractを基本とする。

---

# 58. 未経験HTTP Validation

Presentationでは、

```text id="0qfsg8"
skill_level
    → Level 1

experience_months
    → prohibited

last_used_year_month
    → prohibited
```

を補助的にValidationしてよい。

同じRuleをDomainでも保証する。

---

# 59. 経験ありHTTP Validation

```text id="ygayf3"
work_experience = experienced

experience_months
    → required
    → integer
    → min 1

last_used_year_month
    → required
    → YearMonth
```

とする。

---

# 60. Domain側の最終防衛

HTTP Validationが成功していてもDomainは再度自身のInvariantを保証する。

```text id="pcvvlh"
Presentation Valid
    ≠
Domain Valid保証
```

Domain Object単独でも不正Stateを作れない設計にする。

---

# 61. Normalization

`prepareForValidation()`は軽量Normalizationに限定する。

候補：

```text id="4drdoh"
trim
case normalization
empty string normalization
simple input shape normalization
```

---

# 62. `prepareForValidation()`へ置かないもの

禁止：

```text id="j3o2co"
Repository Access
Entity Retrieval
Business Rule
Authorization
UseCase Logic
Domain Object Reconstruction
Complex Database Query
```

---

# 63. `after()`

Form Requestの`after()`は必要な場合のみ利用する。

適切：

```text id="ccr89m"
Cross-field HTTP Consistency
```

---

# 64. `after()`へ置かないもの

```text id="38x12m"
Complex Business Logic
Repository-heavy Validation
Domain Invariant
UseCase Decision
Authorization
```

を入れない。

---

# 65. Authorization

Form Requestの`authorize()`へ複雑なAuthorizationを集中させない。

基本：

```text id="j8kzei"
authorize()
    → true

Controller / Policy
    → Authorization
```

とする。

---

# 66. Policy

AuthorizationはValidationとは別ConceptとしてLaravel Policyで行う。

```text id="s2el20"
Authentication
    ↓
Authorization
    ↓
Validation
```

実際のMiddleware / Controller順序に依存しすぎず、責務として分離する。

---

# 67. Validation Failure Status

HTTP Input Validation Failureは、

```text id="2p83ig"
422 Unprocessable Content
```

を利用する。

---

# 68. Validation Error Format

Validation Error ResponseはRFC 9457 Problem Detailsへ統一する。

旧独自形式：

```json id="3fp6jr"
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "...",
    "details": {}
  }
}
```

は採用しない。

---

# 69. Content-Type

Validation Error：

```text id="xzo418"
application/problem+json
```

を返す。

---

# 70. Validation Problem Details

例：

```json id="2xhy17"
{
  "type": "https://example.com/problems/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "The request contains invalid fields.",
  "instance": "/api/v1/employee-skills",
  "code": "VALIDATION_ERROR",
  "errors": {
    "skill_level": [
      "The skill level is invalid."
    ],
    "last_used_year_month": [
      "The last used year month is required."
    ]
  }
}
```

---

# 71. Problem Details Members

Standard Member：

```text id="sefz9z"
type
title
status
detail
instance
```

Project Extension：

```text id="ulxdgu"
code
errors
```

---

# 72. `errors`

Validation ErrorのField Errorには、

```text id="jr6z0q"
errors
```

を利用する。

旧：

```text id="gc9fgy"
details
```

は使用しない。

---

# 73. Laravel標準Validation Response

Laravelが内部的に生成する標準Validation JSONを、そのままExternal API Contractとして固定しない。

```text id="2ew3fp"
Laravel Validation Error
    ↓
Central Exception Handling
    ↓
ValidationProblemDetails
```

へMappingする。

---

# 74. Error Message

Human-readable MessageはFrontendのMachine Logicに利用しない。

```text id="4njipm"
HTTP Status
+
code
```

をMachine-readable Contractとする。

---

# 75. Validation Error Code

Validation FailureではStable Error Codeとして、

```text id="4qbrvg"
VALIDATION_ERROR
```

を利用する。

必要がない限りFieldごとに大量のError Codeを作らない。

---

# 76. Internal Information

Validation Errorへ以下を含めない。

```text id="29kmjv"
SQL
Table Name
Internal Class
Stack Trace
DB Host
Raw Exception
Secret
```

---

# 77. Application Errorとの区別

以下はValidation Errorとは限らない。

```text id="1a8gy8"
Employee Not Found
Skill Inactive
EmployeeSkill Already Exists
Operation Conflict
```

Application Errorとして意味に応じ、

```text id="jjbl8g"
404
409
```

等へMappingする。

すべて422にしない。

---

# 78. Predictable DB Constraint Error

Database Constraint Violationのうち、Business上予測可能なものはInfrastructureでSemantic Errorへ変換する。

例：

```text id="eg7njv"
UNIQUE(employee_id, skill_id)
    ↓
EmployeeSkillAlreadyExists
    ↓
409 Conflict
```

Raw SQL Exceptionを500としてClientへExposeしない。

---

# 79. Unexpected Constraint Error

未知のDatabase Error / Driver Error / Connection ErrorはUnexpected Errorとして扱う。

ClientにはGeneric 5xxを返し、内部Log / MonitoringへReportする。

---

# 80. OpenAPI Source of Truth

Validation ContractもOpenAPIをSource of Truthとする。

```text id="t51hxa"
OpenAPI
    ↓
Form Request
    ↓
Implementation
```

とする。

---

# 81. OpenAPIで表現するValidation

例：

```text id="5bwtm6"
required
type
minLength
maxLength
minimum
maximum
enum
pattern
format
nullable
```

---

# 82. Framework Validationとの整合

```text id="i9jo6v"
OpenAPI
    ≠
Laravel Rule Definition Source
```

だが、両者のContractは一致させる。

DriftはContract Test / Reviewで検出する。

---

# 83. Contract Test

OpenAPI Contract Testによって、

```text id="xb9ztx"
OpenAPI Schema
    ↔
Laravel Request / Response
```

の不整合を検出する。

---

# 84. ID Contract Test

最低限以下を確認する。

Valid：

```text id="fzeo1p"
"1"
"123"
"9223372036854775807"
```

環境上の最大値は実行Runtimeに合わせる。

Invalid：

```text id="f23nyd"
0
123
"0"
"-1"
"001"
"1.0"
"abc"
PHP int range overflow
```

API Contract上、JSON number `123`もEntity IDとしてReject対象とする。

---

# 85. YearMonth Test

最低限：

```text id="2dz4ll"
2026-01
2026-12
```

をValidとする。

Invalid：

```text id="5m2v9q"
2026-00
2026-13
26-09
2026/09
2026-9
```

---

# 86. EmployeeSkill Domain Test

最低限以下を確認する。

```text id="cqnp0j"
未経験 + Level1
    → OK

未経験 + Level2〜5
    → Reject

未経験 + ExperiencePeriod
    → Reject

未経験 + LastUsed
    → Reject

経験あり + 0 months
    → Reject

経験あり + LastUsedなし
    → Reject

経験あり + 1 month以上 + LastUsed
    → OK
```

---

# 87. Presentation Test

Form Request / Feature TestではProject Contractを確認する。

Laravel Built-in Rule自体の挙動を大量に再テストしない。

---

# 88. Application Test

Application Validationでは、

```text id="l2gfji"
Entity Not Found
Inactive State
Duplicate
Invalid Operation
```

等をTestする。

RepositoryはFake等を利用できる。

---

# 89. Database Constraint Test

Infrastructure Integration TestではReal PostgreSQLを利用する。

対象：

```text id="ht782a"
FK
UNIQUE
CHECK
NOT NULL
```

SQLiteでPostgreSQL Constraint Behaviorを代替しない。

---

# 90. Concurrency

Application check + DB UNIQUEが競合するScenarioについては重要箇所のみConcurrency Testを検討する。

すべてのValidation RuleにConcurrency Testを作らない。

---

# 91. Logging

通常の422 Validation FailureをSystem Errorとして大量にLogしない。

---

# 92. Security Logging

ただし、

```text id="i0lwry"
異常な大量Validation Failure
Malicious Input Pattern
Repeated Abuse
```

等がSecurity Signalとなる場合はSecurity Logging / Rate Limit側で扱う。

---

# 93. Sensitive Data

Validation Error / LogへSensitive Dataを含めない。

例：

```text id="i2w3ti"
Password
Token
Authorization Header
Cookie
Secret
Private Key
```

---

# 94. Validation Base Class

巨大な、

```text id="dbb27a"
BaseFormRequest
```

へProject全Validation Logicを集約しない。

共通化は本当に共通な小さなBehaviorに限定する。

---

# 95. External Validation Library

以下は採用しない。

```text id="nyfzbj"
Attribute-based Validation Framework
DTO Validation Framework
Symfony Validatorの追加導入
External Validation Package
```

Laravel標準Validationで十分と判断する。

---

# 96. DTO Library

Validation目的だけでDTO Frameworkを導入しない。

Command / Query / DTOはNative PHP Classを基本とする。

---

# 97. Validation Architecture

最終構成：

```text id="2c495g"
HTTP
    ↓
Form Request
    │
    ├── Type
    ├── Format
    ├── Required
    ├── Range
    └── Request Shape
    ↓
Primitive / Enum / Value Object
    ↓
Command / Query
    ↓
Application Handler
    │
    ├── Existence
    ├── Current State
    └── UseCase Feasibility
    ↓
Domain
    │
    └── Business Invariant
    ↓
Repository
    ↓
PostgreSQL
        ├── FK
        ├── UNIQUE
        ├── CHECK
        └── NOT NULL
```

---

# 98. EmployeeSkill Validation Flow

```text id="126btr"
HTTP Request
    ↓
Form Request
    ├── employee_id = digit string
    ├── skill_id = digit string
    ├── work_experience = enum
    ├── skill_level = 1..5
    ├── experience_months = conditional integer
    └── last_used_year_month = YYYY-MM
    ↓
Presentation Mapping
    ├── EmployeeId
    ├── SkillId
    ├── WorkExperience
    ├── SkillLevel
    ├── ExperiencePeriod
    └── YearMonth
    ↓
Application
    ├── Employee existence
    ├── Skill existence
    ├── Skill active
    └── Duplicate check
    ↓
Domain
    └── EmployeeSkill invariant
    ↓
PostgreSQL
    └── FK / UNIQUE / CHECK / NOT NULL
```

---

# 99. 採用一覧

| 項目 | 決定 |
|---|---|
| Validation Model | 4 Layer |
| HTTP Validation | Laravel Form Request |
| Built-in Rules | 優先 |
| Rule API | 採用 |
| Native Enum Validation | 採用 |
| Custom Rule | 必要時のみ |
| Conditional Rule | 採用 |
| `exists` | HTTP補助として採用 |
| `unique` | HTTP補助として採用 |
| Application Validation | 採用 |
| Domain Invariant | 採用 |
| DB Constraint | 採用 |
| Entity ID API Type | string |
| ID Format | positive decimal digit string |
| ID Range Check | 必須 |
| ID Domain Type | positive int Typed ID |
| YearMonth API | `YYYY-MM` |
| YearMonth VO | 採用 |
| Experience Period | total months |
| Form Request→Handler直接渡し | 不採用 |
| Complex Business Rule in Form Request | 不採用 |
| Complex DB Query in Form Request | 不採用 |
| Authorization in Validation | 原則分離 |
| Validation Failure | 422 |
| Error Format | RFC 9457 Problem Details |
| Validation Extension | `errors` |
| Legacy `details` | 不採用 |
| External Validation Library | 不採用 |
| DTO Validation Framework | 不採用 |
| OpenAPI | Source of Truth |
| Contract Test | 採用 |
| PostgreSQL Constraint Test | 採用 |

---

# 100. 最終原則

Validationでは、

> どのLayerでも同じことを全部Validationするのではなく、それぞれのLayerが守るべき境界を明確にする

ことを基本とする。

```text id="suvr6g"
Presentation
    → Input Validity

Application
    → UseCase Validity

Domain
    → Business Validity

Database
    → Data Integrity
```

とする。

さらに、

```text id="tlonbn"
Form Request
    ≠
Business Rule Engine
```

および、

```text id="ds90q7"
HTTP Validation Success
    ≠
Domain Invariant保証
```

を維持する。

Entity IDについては、

```text id="5g11b5"
HTTP
    → positive digit string

Presentation
    → range check
    → positive PHP int
    → Typed ID

Domain / Application
    → Typed ID
```

へ統一する。

Validation Errorは、

```text id="ngrowz"
RFC 9457 Problem Details
+
code
+
errors
```

へ統一する。

最終的なValidation構成は、

```text id="5hfqpf"
Laravel Form Request
+
Application Validation
+
Domain Invariant
+
PostgreSQL Constraint
```

をEngineer Skill Management App Backendの標準とする。
