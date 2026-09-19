# Backend 技術・Library選定 - Validation

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend における Validation の責務分離、Laravel Validation機能の利用方針、Domain InvariantおよびDatabase Constraintとの境界を定義する。

本ProjectではValidationを以下の4層に分離する。

```text
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

各Layerの責務は以下とする。

| Layer | 責務 |
|---|---|
| Presentation | HTTP Inputとして妥当か |
| Application | UseCaseを実行可能か |
| Domain | Business Ruleを満たしているか |
| Database | Data Integrityの最終防衛 |

この責務分離をValidation設計の基本原則とする。

---

## 2. 基本方針

Validationは単一Layerへ集中させない。

以下のように責務ごとに分割する。

```text
HTTPとして正しいか
    ↓
Presentation

UseCaseを実行できるか
    ↓
Application

Business上正しいか
    ↓
Domain

Database上壊れていないか
    ↓
Database Constraint
```

同じRuleが複数Layerで防御されることは許容する。

ただし、

> どのLayerが最終的な責務を持つか

を明確にする。

---

## 3. Presentation Validation

HTTP RequestのValidationにはLaravel Form Requestを採用する。

基本フローは以下とする。

```text
HTTP Request
    ↓
Form Request
    ↓
Validation済みInput
    ↓
Command / Query
```

例：

```php
final class RegisterEmployeeSkillRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'skill_id' => [
                'required',
                'integer',
                'min:1',
            ],

            'skill_level' => [
                'required',
                'integer',
                'between:1,5',
            ],
        ];
    }
}
```

Controller内で直接大量のValidation Ruleを定義しない。

---

## 4. Form Requestの責務

Form Requestでは主に以下を扱う。

```text
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

つまり、

> API Inputとして受け付けられる値か

を判定する。

例：

```text
skill_level = "abc"
    ↓
Presentation Validation Error

skill_level = 10
    ↓
Presentation Validation Error
```

---

## 5. Form RequestにBusiness Ruleを集中させない

Form RequestはDomain Invariantの最終保証場所ではない。

例えば、

```text
実務未経験
    ↓
Skill LevelはLevel1のみ
```

というRuleはDomain Ruleである。

PresentationでもUX改善や早期Error Detectionのため補助Validationを行うことはできる。

ただし、

```text
Form Requestを通ればBusiness Ruleも保証済み
```

とは考えない。

Domain Layerでも必ずInvariantを保証する。

---

## 6. EmployeeSkill Validation例

例えば以下のInputを受け取るとする。

```json
{
  "skill_id": 10,
  "work_experience": "experienced",
  "skill_level": 3,
  "experience_months": 24,
  "last_used_year_month": "2026-08"
}
```

Presentationでは以下を検証する。

```text
skill_id
    → integer
    → 1以上

work_experience
    → 有効なEnum値

skill_level
    → integer
    → 1〜5

experience_months
    → integer
    → 必要に応じて1以上

last_used_year_month
    → YYYY-MM形式
```

Domainでは以下を保証する。

```text
実務未経験
    ↓
Level1のみ
Experience Periodなし
Last Usedなし

実務経験あり
    ↓
Experience Period 1か月以上
Last Used必須
Level1〜5
```

---

## 7. Application Validation

Application Layerでは、

> HTTP Input自体は妥当だが、そのUseCaseを現在実行できるか

を確認する。

代表例：

```text
Employeeが存在するか
Skillが存在するか
Skillが有効か
Employeeが操作対象として有効か
EmployeeSkillがすでに登録されていないか
対象状態から変更可能か
```

例えば、

```text
skill_id = 100
```

という値はintegerとして正しい。

しかし、

```text
Skill ID 100が存在しない
```

場合、UseCaseは成立しない。

これはPresentation Validationとは分離する。

---

## 8. Application Validationの配置

Application Validationは主にHandler内で行う。

例：

```text
RegisterEmployeeSkillHandler
    ↓
Employee存在確認
    ↓
Skill存在確認
    ↓
Skill Active確認
    ↓
Duplicate確認
    ↓
Aggregate生成
```

ただしBusiness InvariantそのものをHandlerへ集中させない。

Business RuleはDomainへ配置する。

---

## 9. Domain Invariant

Business RuleはDomain Layerで保証する。

EmployeeSkillでは例えば以下。

```text
WorkExperience = Unexperienced
    ↓
SkillLevel = Level1
ExperiencePeriod = null
LastUsed = null
```

```text
WorkExperience = Experienced
    ↓
ExperiencePeriod >= 1 month
LastUsed != null
SkillLevel = Level1〜5
```

Invariantは以下で保証する。

- Factory Method
- Constructor
- Behavior Method
- Value Object
- Enum
- Domain Service
- Domain Exception

---

## 10. Domain Invariantの実装

例えば新規登録時は、

```php
EmployeeSkill::register(
    $id,
    $employeeId,
    $skillId,
    $skillLevel,
    $workExperience,
    $experiencePeriod,
    $lastUsedAt,
);
```

内部でInvariantを検証する。

状態変更時も、

```php
$employeeSkill->changeLevel(...);
$employeeSkill->recordWorkExperience(...);
$employeeSkill->markAsUnexperienced();
```

などのBehavior Methodを利用する。

Domain Ruleを回避できるGeneric Setterは使用しない。

---

## 11. Database Constraint

DatabaseはData Integrityの最終防衛として利用する。

主に以下を利用する。

```text
PRIMARY KEY
FOREIGN KEY
UNIQUE
CHECK
NOT NULL
```

ApplicationやDomainだけでDatabase Integrityを保証しない。

---

## 12. Validationの多層防御

例えばEmployeeSkillの重複禁止は以下とする。

```text
Presentation
    ↓
必要なら早期重複Validation

Application
    ↓
Duplicate確認

Database
    ↓
UNIQUE(employee_id, skill_id)
```

Application CheckだけではConcurrency Raceを防げない。

最終的なIntegrity GuaranteeはDatabase Constraintが担当する。

---

## 13. Validation Rule分類

Rule配置の判断基準は以下とする。

| Rule | Layer |
|---|---|
| Field必須 | Presentation |
| String / Integer型 | Presentation |
| 最大文字数 | Presentation |
| 数値範囲 | Presentation |
| Enum値 | Presentation + Domain Enum |
| Record存在 | Application + DB FK |
| Record Active | Application / Domain |
| Domain State Transition | Domain |
| 未経験ならLevel1 | Domain |
| Duplicate禁止 | Application + DB UNIQUE |
| FK Integrity | Database |
| Simple Data Range | Presentation + DB CHECK候補 |

迷った場合は以下で判断する。

```text
HTTPとして正しい？
    → Presentation

UseCaseを実行できる？
    → Application

Businessとして正しい？
    → Domain

Dataとして壊れてはいけない？
    → Database
```

---

## 14. Laravel Built-in Validation Rule

ValidationはLaravel Built-in Ruleを優先する。

例：

```php
return [
    'name' => [
        'required',
        'string',
        'max:100',
    ],

    'skill_level' => [
        'required',
        'integer',
        'between:1,5',
    ],
];
```

Custom Ruleを作成する前に標準Ruleで自然に表現できないか確認する。

---

## 15. Rule記述形式

単純なRuleはArray形式を基本とする。

```php
[
    'required',
    'string',
    'max:100',
]
```

条件や型安全性が必要な場合はLaravelの`Rule` APIを利用する。

例：

```php
use Illuminate\Validation\Rule;

[
    'role' => [
        'required',
        Rule::enum(UserRole::class),
    ],
]
```

過度に複雑なString Ruleを作らない。

---

## 16. Enum Validation

Enum InputにはPHP Native Enum + Laravel `Rule::enum()`を利用する。

例：

```php
'work_experience' => [
    'required',
    Rule::enum(WorkExperience::class),
],
```

Validation後はPrimitive StringのままApplicationへ渡し続けず、Enumへ変換する。

```text
HTTP String
    ↓
Validation
    ↓
PHP Enum
    ↓
Command
```

---

## 17. Conditional Validation

Field間のHTTP-levelな条件ValidationにはLaravel Conditional Ruleを利用できる。

例えば、

```text
work_experience = experienced
    ↓
experience_months必須
```

の場合、

```php
'experience_months' => [
    Rule::requiredIf(
        fn (): bool =>
            $this->input('work_experience') === 'experienced'
    ),
    'integer',
    'min:1',
],
```

のように表現できる。

---

## 18. `required_if`

単純な条件ではString Ruleも利用可能とする。

```php
'required_if:work_experience,experienced'
```

複雑な条件では、

```php
Rule::requiredIf(...)
```

を優先する。

可読性を基準に選択する。

---

## 19. `prohibited_if`

未経験時に送信してはいけないFieldをPresentation段階でも拒否できる。

例えば、

```text
work_experience = unexperienced

experience_months
last_used_year_month

→ Requestとして禁止
```

とする場合、

```php
Rule::prohibitedIf(...)
```

等を利用できる。

ただしこれもDomain Invariantの代替にはしない。

---

## 20. `exists` Rule

Foreign IDの入力補助としてLaravel `exists` Ruleを利用できる。

例：

```php
'skill_id' => [
    'required',
    'integer',
    'min:1',
    Rule::exists('skills', 'id'),
],
```

ただし、

```text
exists Validation
    ≠
UseCase実行時の存在保証
```

とする。

Validation後にRecord状態が変わる可能性があるため、Application側でも適切に存在確認を行う。

DatabaseではForeign KeyによってReferential Integrityを保証する。

---

## 21. `unique` Rule

Laravel `unique` Ruleは早期Error Detectionとして利用可能とする。

ただし最終保証には利用しない。

```text
unique Validation
    ↓
Application Duplicate Check
    ↓
Database UNIQUE Constraint
```

という多層防御とする。

Concurrency下ではDatabase UNIQUE Constraintを最終防衛とする。

---

## 22. Database Queryを伴うValidation

Presentation ValidationからDatabase Queryを行うこと自体は禁止しない。

`exists` / `unique`のような標準的Validationでは利用できる。

ただしForm Requestへ、

```text
大量のJOIN
Business State判定
Complex Permission判定
UseCase Logic
```

を実装しない。

複雑な状態確認はApplication Layerへ移す。

---

## 23. Custom Validation Rule

Laravel Built-in Ruleでは不自然になる場合のみCustom Validation Ruleを作成する。

例：

```php
final class YearMonthRule implements ValidationRule
{
    public function validate(
        string $attribute,
        mixed $value,
        Closure $fail,
    ): void {
        // YYYY-MM validation
    }
}
```

Custom RuleはPresentation LayerのHTTP Input Validationとして扱う。

---

## 24. Custom Validation Ruleの採用基準

Custom Ruleは以下の場合に利用する。

- 複数Form Requestで再利用する
- Built-in Ruleでは表現が不自然
- HTTP Inputとして独立した概念
- Error Messageを統一したい

以下には利用しない。

```text
Aggregate Invariant
Business State Transition
Complex UseCase Rule
```

これらはDomain / Applicationへ配置する。

---

## 25. YearMonth Validation

`YYYY-MM`形式は本Projectで重要なInput形式として扱う。

例えば、

```text
2026-09
```

を受け取る。

PresentationではFormatをValidationする。

```text
String
    ↓
YearMonth Validation
    ↓
YearMonth Value Object
```

Validation後にApplication / Domainで`YearMonth` Value Objectとして扱う。

年月をTimestampへ無理に変換しない。

---

## 26. ID Validation

HTTP InputのIDはPresentationでPrimitiveとしてValidationする。

例：

```php
'employee_id' => [
    'required',
    'integer',
    'min:1',
],
```

Validation後にTyped IDへ変換する。

```text
HTTP integer
    ↓
Validation
    ↓
EmployeeId
```

Application / Domainへ生のinteger IDを無秩序に伝播させない。

---

## 27. Input Normalization

Validation前の軽微なInput正規化にはForm Requestの`prepareForValidation()`を利用できる。

例：

```php
protected function prepareForValidation(): void
{
    $this->merge([
        'keyword' => trim((string) $this->input('keyword')),
    ]);
}
```

用途は以下に限定する。

```text
trim
Case Normalize
空文字Normalize
軽微な形式統一
```

---

## 28. `prepareForValidation()`で行わない処理

以下は禁止する。

```text
Domain Entity生成
Repository呼び出し
Database大量検索
Business Rule判定
Authorization Logic
UseCase実行
```

`prepareForValidation()`をApplication Service化しない。

---

## 29. `after()` Validation

Field間の追加HTTP ValidationにはForm Requestの`after()`を必要に応じて利用できる。

利用例：

```text
複数Field間のInput整合性
```

ただし以下を行わない。

```text
複雑なDB Query
Business Rule
Domain State Validation
UseCase Logic
```

複雑になった場合はApplication / Domainへ移す。

---

## 30. Form Request Authorization

Authorizationの中心はLaravel Policy / Gateとする。

Form Requestの`authorize()`へAuthorization Logicを分散させない。

原則として、

```php
public function authorize(): bool
{
    return true;
}
```

とし、Controller / Policy側でAuthorizationを行う。

例外的にRequestそのものと密接な単純Authorizationが必要になった場合のみ再検討する。

---

## 31. Controllerとの境界

ControllerではForm RequestからValidation済みInputを取得し、Command / Queryへ変換する。

```text
Form Request
    ↓
validated()
    ↓
Primitive / Enum / Value Objectへ変換
    ↓
Command / Query
```

例：

```php
public function __invoke(
    RegisterEmployeeSkillRequest $request,
    RegisterEmployeeSkillHandler $handler,
): JsonResponse {
    $command = new RegisterEmployeeSkillCommand(
        // validated input conversion
    );

    $result = $handler->handle($command);

    // response conversion
}
```

Form RequestそのものをApplication Handlerへ渡さない。

---

## 32. Validation Error Status

HTTP Input Validation Failureは、

```http
422 Unprocessable Content
```

として扱う。

Authentication / Authorization / Conflict等とは区別する。

```text
401
    → Authentication

403
    → Authorization

409
    → State Conflict

422
    → Request Validation

500
    → Unexpected Error
```

---

## 33. Validation Error Response

Validation ErrorはAPI全体の統一Error Schemaへ変換する。

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request is invalid.",
    "details": {
      "skill_level": [
        "The skill level must be between 1 and 5."
      ]
    }
  }
}
```

Laravel標準Validation Errorをそのまま外部Contractとして固定しない。

API Error Schemaへ統一する。

---

## 34. Validation Message

Validation Messageは主にUser表示用途とする。

Application LogicやFrontend LogicでError Message文字列を判定しない。

Frontendは以下を利用する。

```text
HTTP Status
error.code
details Field Name
```

Message Textは表示用情報として扱う。

---

## 35. Validation Error Code

HTTP Validation Errorの基本Codeは以下とする。

```text
VALIDATION_ERROR
```

Field単位の詳細は`details`へ格納する。

MVPでは全Validation Ruleごとに固有Error Codeを定義しない。

必要性が明確になった場合のみ拡張する。

---

## 36. Validation Messageの国際化

Laravel Validation MessageのLocalization機能を利用可能とする。

ただしMVPでは、

```text
Stable Error Code
Stable Field Name
Readable Message
```

を優先する。

API ContractとしてMessage文字列自体の完全固定を前提にしない。

---

## 37. Frontend Validation

FrontendでもValidationを実施する。

主な目的：

```text
UX改善
早期Error表示
不要Request削減
```

例えば以下。

```text
required
max length
format
range
conditional field
```

ただしFrontend ValidationをSecurity Boundaryとして扱わない。

---

## 38. Frontend / Backend Validationの関係

責務は以下とする。

```text
Frontend Validation
    ↓
UX

Laravel Form Request
    ↓
API Boundary

Application Validation
    ↓
UseCase Execution

Domain Invariant
    ↓
Business Integrity

Database Constraint
    ↓
Data Integrity
```

Backend側ではFrontend Validationの有無を信用しない。

---

## 39. OpenAPIとの整合性

HTTP Validation RuleはOpenAPI Schemaと整合させる。

例えば、

```yaml
skill_level:
  type: integer
  minimum: 1
  maximum: 5
```

の場合、Laravel側も同等のValidationを持つ。

```php
'skill_level' => [
    'required',
    'integer',
    'between:1,5',
],
```

---

## 40. OpenAPIをSource of Truthとする

API ContractのSource of TruthはOpenAPIとする。

```text
OpenAPI
    ↓
API Contract

Laravel Form Request
    ↓
Contract Implementation
```

Laravel Validation CodeからOpenAPIを自動生成しない。

---

## 41. Contract Test

OpenAPIとLaravel実装の差分はContract Testで検出する。

```text
OpenAPI
    ↓
Request / Response Contract
    ↓
Laravel Feature Test
    ↓
Contract Validator
```

Validation RuleとOpenAPI Schemaが乖離しないようCIで確認する。

---

## 42. Validation Attribute

Attribute-based Validation Frameworkは採用しない。

例えば、

```php
#[Required]
#[MaxLength(100)]
```

のようなProject全体のValidation Metadata化は行わない。

HTTP ValidationはLaravel Form Requestへ明示的に定義する。

---

## 43. DTO Validation Framework

DTO PackageへValidation責務を集約しない。

以下の構造にはしない。

```text
HTTP
    ↓
DTO Framework
    ↓
Validation
    ↓
Transformation
    ↓
Application
```

本Projectでは責務を以下に保つ。

```text
Form Request
    ↓
Command / Query
    ↓
Application / Domain
```

---

## 44. External Validation Library

External Validation Frameworkは原則導入しない。

Laravel標準機能で十分と判断する。

採用するもの：

```text
Laravel Form Request
Laravel Validator
Laravel Built-in Rules
Laravel Rule Object
Laravel Custom Validation Rule
PHP Native Enum
Project Value Object
```

不採用：

```text
External Validation Framework
DTO Validation Framework
Attribute-based Validation Framework
Symfony Validatorの追加利用
```

---

## 45. ValidationとException

Validation / Business Rule Errorをすべて同じExceptionとして扱わない。

概念的には以下を区別する。

```text
HTTP Validation Failure
    ↓
422

Application Conflict
    ↓
409等

Domain Rule Violation
    ↓
Application / PresentationでMapping

Database Constraint Violation
    ↓
適切なApplication ErrorへMapping
```

具体的なException Mappingは`07_Exception・Error-Handling.md`で定義する。

---

## 46. Database Constraint Error

Database UNIQUE / FK等のConstraint Errorをそのまま500として返さない。

予測可能なConstraint ViolationはInfrastructure / Applicationで意味のあるErrorへ変換する。

例えばEmployeeSkill重複の場合、

```text
Database UNIQUE Violation
    ↓
EmployeeSkillAlreadyExists
    ↓
409 Conflict
```

のように扱う。

詳細はException設計で決定する。

---

## 47. ValidationにおけるSecurity

Validation Errorへ以下を不用意に含めない。

```text
SQL
Table Name
Internal Column Name
Stack Trace
Class Name
Infrastructure詳細
```

Clientへ必要なField名とMessageのみ返す。

Internal Information Leakageを防ぐ。

---

## 48. Logging

通常の422 Validation ErrorをすべてError LevelでLogしない。

Validation Errorは通常のUser Input Errorとして扱う。

Security上不自然な大量Errorや攻撃兆候についてはObservability / Security側で別途検討する。

Logging方針は`09_Log・Audit.md`および`10_Observability.md`で定義する。

---

## 49. Validation Rule再利用

複数Requestで共通Ruleが必要な場合でも、安易に巨大なBase Form Requestを作らない。

まず以下を検討する。

```text
Laravel Built-in Rule
    ↓
Custom Validation Rule
    ↓
小さなRule Factory / Helper
```

Inheritanceによる複雑なValidation共有を避ける。

---

## 50. Base Form Request

全Form Requestを継承するProject固有Base Form Requestは、共通Error Response等の明確な必要性がある場合のみ作成する。

Validation Rule共有だけを目的にBase Class化しない。

Laravel標準Form Requestを基本とする。

---

## 51. Validation Test

Validation RuleはFeature Testを中心に確認する。

代表ケース：

```text
正常Input
必須不足
型不正
範囲外
Enum不正
Conditional Rule
Format不正
Exists不正
Unique不正
```

Domain InvariantはDomain Unit Testで別途確認する。

---

## 52. Layer別Test

```text
Form Request / API Validation
    ↓
Feature Test

Application Validation
    ↓
Application Unit / Integration Test

Domain Invariant
    ↓
Domain Unit Test

Database Constraint
    ↓
Infrastructure / Integration Test
```

同じRuleを異なるLayerで重複している場合も、それぞれの責務としてTestする。

---

## 53. Library採用判断

| Library / 技術 | 判断 |
|---|---|
| Laravel Form Request | 採用 |
| Laravel Validator | 採用 |
| Laravel Built-in Rule | 優先利用 |
| Laravel `Rule` API | 採用 |
| `Rule::enum()` | 採用 |
| Conditional Rule | 採用 |
| `exists` | 補助的に採用 |
| `unique` | 補助的に採用 |
| Custom Validation Rule | 必要時のみ |
| `prepareForValidation()` | 限定利用 |
| `after()` | 限定利用 |
| PHP Native Enum | 採用 |
| Domain Value Object | 採用 |
| External Validation Framework | 不採用 |
| DTO Validation Framework | 不採用 |
| Attribute Validation Framework | 不採用 |
| Symfony Validator追加利用 | 不採用 |

---

## 54. 採用技術・方針一覧

| 項目 | 決定 |
|---|---|
| HTTP Validation | Laravel Form Request |
| Validation Engine | Laravel標準 |
| Validation責務 | 4層分離 |
| Presentation | HTTP Input Validation |
| Application | UseCase成立性 |
| Domain | Business Invariant |
| Database | Data Integrity |
| Built-in Rule | 優先 |
| Custom Rule | 必要時のみ |
| Enum Validation | `Rule::enum()` |
| Conditional Validation | Laravel Conditional Rule |
| Input Normalization | `prepareForValidation()`限定利用 |
| Post Validation | `after()`限定利用 |
| Form Request Authorization | 原則Policyへ |
| `exists` | HTTP補助 |
| `unique` | HTTP補助 |
| Duplicate最終保証 | DB UNIQUE |
| FK最終保証 | DB FK |
| ID | Validation後Typed ID化 |
| YearMonth | Validation後VO化 |
| Business Rule in Form Request only | 禁止 |
| Form Request → Handler直渡し | 禁止 |
| Validation Error | 422 |
| Validation Error Code | `VALIDATION_ERROR` |
| Frontend Validation | UX目的 |
| Backend Validation | 必須 |
| OpenAPI | Source of Truth |
| Contract Test | CIで利用 |
| External Validation Library | 不採用 |

---

## 55. 最終Architecture

Validation Flowは以下とする。

```text
Browser
    ↓
Frontend Validation
    ↓
HTTP Request
    ↓
Laravel Form Request
    ↓
Presentation Validation
    ↓
Command / Query
    ↓
Application Validation
    ↓
Domain Aggregate / Value Object
    ↓
Domain Invariant
    ↓
Repository
    ↓
Database Constraint
```

Error Responsibilityは以下とする。

```text
Invalid HTTP Input
    ↓
422 Validation Error

UseCase Cannot Execute
    ↓
Application Error

Business Rule Violation
    ↓
Domain Error

Integrity Race / Constraint Violation
    ↓
Database Error
    ↓
Application Errorへ変換
```

---

## 56. 最終方針

Validationでは、

> すべてのRuleをForm Requestへ集約しない

ことを最重要原則とする。

以下の4層を維持する。

```text
Presentation
    ↓
HTTP Inputとして妥当か

Application
    ↓
UseCaseを実行できるか

Domain
    ↓
Business Ruleを満たしているか

Database
    ↓
Data Integrityを維持できるか
```

Laravel標準Validation機能を最大限活用し、

```text
Form Request
Built-in Rule
Rule API
Custom Rule
```

でHTTP Boundaryを守る。

一方で、

```text
Aggregate
Value Object
Enum
Domain Exception
```

によってBusiness InvariantをDomain側でも必ず保証する。

また、

```text
FOREIGN KEY
UNIQUE
CHECK
NOT NULL
```

によってDatabaseを最終防衛として利用する。

外部Validation Frameworkを導入せず、

> Laravel標準Validation + Application Validation + Domain Invariant + Database Constraint

という構成を採用する。
