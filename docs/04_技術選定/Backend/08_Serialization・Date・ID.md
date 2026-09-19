# Backend 技術・Library選定 - Serialization・Date・ID

## 1. 目的

本ドキュメントでは、Engineer Skill Management App の Backend における以下を定義する。

- API Serialization
- Domain / Application上の値表現
- Database上のPersistence Representation
- Date / Time / Time Zone
- YearMonth
- Experience Period
- ID
- Enum / Value Objectの外部表現
- OpenAPI Schemaとの整合性

本Projectでは、以下の3つの表現を明確に分離する。

```text
Database Representation
        ↓
Domain / Application Representation
        ↓
API Representation
```

各Layerで最適な表現を利用し、Database都合やHTTP都合をDomainへ持ち込まない。

---

## 2. 基本方針

Serializationでは以下を基本原則とする。

- Domain Entityを直接JSON化しない
- Eloquent Modelを直接HTTP Responseとして返さない
- API ContractはPresentation Layerで明示する
- EnumはBacked ValueをAPIへ公開する
- Value ObjectはBoundaryでPrimitiveへ変換する
- Instant / Date / YearMonth / Durationを区別する
- Domain / Applicationでは`DateTimeImmutable`を基本とする
- 現在時刻取得には`Clock` Portを利用する
- Backend内部のInstantはUTC基準とする
- PostgreSQLではInstantに`timestamptz`を利用する
- DB Primary Keyはbigintを利用する
- API上のIDはstringとして扱う
- Serialization専用External Libraryは追加しない

---

## 3. Serialization Boundary

Serialization Flowは以下を基本とする。

```text
Domain Entity
Value Object
Enum
Application Result
Read Model
        ↓
Presentation
        ↓
Laravel API Resource
        ↓
JSON
```

Persistence側は以下。

```text
PostgreSQL
    ↓
Eloquent / Query Builder
    ↓
Mapper / Query Service
    ↓
Domain / Read Model
```

Database RepresentationとAPI Representationを直接結び付けない。

---

## 4. Laravel API Resource

API ResponseのSerializationにはLaravel `JsonResource`を採用する。

例：

```php
final class EmployeeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id->value,
            'name' => $this->name,
            'employment_status' => $this->employmentStatus->value,
            'created_at' => $this->createdAt->format(
                DateTimeInterface::RFC3339_EXTENDED,
            ),
        ];
    }
}
```

API Resourceでは以下を明示する。

```text
Field Name
Primitive Type
ID表現
Enum表現
Date / Time Format
Nullable Field
Nested Resource
Collection Structure
```

LaravelやEloquentの自動SerializationへPublic API Contractを委ねない。

---

## 5. Eloquent Modelの直接Response禁止

以下は禁止する。

```php
return EmployeeModel::findOrFail($id);
```

または、

```php
return response()->json($employeeModel);
```

理由は以下。

- Database ColumnがAPI Contractへ漏れる
- Hidden / Cast設定がPublic APIへ影響する
- Persistence ModelとAPI Modelが密結合になる
- Database Schema変更がBreaking API Changeになりやすい

以下の構造を基本とする。

```text
Eloquent / Query Builder
        ↓
Domain / Read Model
        ↓
API Resource
        ↓
JSON
```

---

## 6. Domain Objectの直接JSON化禁止

Domain Entity / Value ObjectへAPI Serialization責務を持たせない。

以下のような設計は原則採用しない。

```php
final class EmployeeId implements JsonSerializable
{
    public function jsonSerialize(): mixed
    {
        return $this->value;
    }
}
```

理由：

```text
Domain
    ↓
JSON / Transport Format
```

という依存が生じるため。

Primitiveへの変換はPresentation Boundaryで行う。

---

## 7. API Resourceの責務

API ResourceはPresentation Transformerとして扱う。

担当するもの：

```text
Field Name変換
Typed ID → string
Enum → backed value
DateTime → RFC 3339
YearMonth → YYYY-MM
Nullable Field
Nested Resource
Collection Structure
```

担当しないもの：

```text
Business Rule
Domain State変更
Repository呼び出し
Database Query
Complex Authorization
Transaction
```

---

## 8. JSON Field Naming

API JSON Fieldは以下へ統一する。

```text
snake_case
```

例：

```json
{
  "employee_id": "123",
  "skill_level": 3,
  "work_experience": "experienced",
  "last_used_year_month": "2026-09",
  "created_at": "2026-09-12T10:03:24Z"
}
```

Laravel / OpenAPIとの整合性を優先する。

Frontend内部でcamelCaseへ変換する場合はFrontend側の責務とする。

---

## 9. Enum Serialization

PHP Native Backed EnumをAPIではBacked Valueとして表現する。

例：

```php
enum SkillLevel: int
{
    case Level1 = 1;
    case Level2 = 2;
    case Level3 = 3;
    case Level4 = 4;
    case Level5 = 5;
}
```

API：

```json
{
  "skill_level": 3
}
```

String Enum：

```php
enum UserRole: string
{
    case Administrator = 'administrator';
    case Manager = 'manager';
    case SubManager = 'sub_manager';
    case TeamLeader = 'team_leader';
}
```

API：

```json
{
  "role": "administrator"
}
```

以下をAPI Contractへ公開しない。

```text
Administrator
SubManager
Level3
```

PHP Enum Case NameはInternal Detailとする。

---

## 10. Value Object Serialization

Value ObjectはPresentation BoundaryでPrimitiveへ変換する。

例：

```php
final readonly class EmployeeId
{
    public function __construct(
        public int $value,
    ) {
    }
}
```

API Resource：

```php
'id' => (string) $employee->id->value,
```

YearMonthなら、

```php
'last_used_year_month' =>
    $employeeSkill->lastUsedYearMonth?->toString(),
```

のように表現する。

---

## 11. Null

`null`はDomain上、

> 値が存在しない

ことに意味がある場合に利用する。

例えば実務未経験の場合：

```json
{
  "experience_months": null,
  "last_used_year_month": null
}
```

以下の状態を`null`として混在させない。

```text
値が存在しない
未取得
Relation未Load
Calculation未実行
内部Error
```

---

## 12. MissingとNull

API Contractでは、

```text
Field Missing
```

と、

```json
{
  "field": null
}
```

を区別する。

基本方針：

```text
Schemaに存在するNullable Field
    → null

そのResponse Schemaに存在しないField
    → Missing
```

同じEndpointでEloquent RelationのLoad状態によってFieldが不規則に消える設計は避ける。

---

## 13. Date / Timeの概念分離

日時関連の値をすべて同じDateTimeとして扱わない。

少なくとも以下を区別する。

```text
Instant
    → 特定の瞬間

Date
    → 日付

YearMonth
    → 年月

Duration
    → 期間
```

例：

| Concept | Example |
|---|---|
| Instant | `created_at` |
| Instant | `retired_at` |
| Date | `2026-09-12` |
| YearMonth | `2026-09` |
| Duration | `27 months` |

意味に合った型を利用する。

---

## 14. Instant

Instantは、

> 世界上の特定の瞬間

を表す。

例：

```text
created_at
updated_at
retired_at
permission_changed_at
```

Domain / Applicationでは、

```php
DateTimeImmutable
```

を利用する。

Databaseでは、

```text
timestamp with time zone
```

を利用する。

APIではTimezone付きRFC 3339形式へ変換する。

---

## 15. DateTimeImmutable

Domain / Applicationの日時型には`DateTimeImmutable`を標準採用する。

```text
Domain
    → DateTimeImmutable

Application
    → DateTimeImmutable
```

Mutableな日時ObjectをDomainで標準利用しない。

---

## 16. Carbon

Carbonは全面禁止しない。

Layerごとの方針は以下。

| Layer | Carbon |
|---|---|
| Domain | 使用しない |
| Application | 原則使用しない |
| Presentation | 利用可 |
| Infrastructure | 利用可 |

Domain / ApplicationのBoundaryではNative PHPの`DateTimeImmutable`を利用する。

---

## 17. Clock Port

現在日時取得にはApplication Portとして`Clock`を利用する。

```php
interface Clock
{
    public function now(): DateTimeImmutable;
}
```

Infrastructure：

```php
final class SystemClock implements Clock
{
    public function now(): DateTimeImmutable
    {
        return new DateTimeImmutable(
            'now',
            new DateTimeZone('UTC'),
        );
    }
}
```

TestではFake Clockを利用できる。

```text
Clock
├── SystemClock
└── FakeClock
```

---

## 18. Global Current Timeの禁止

Domain / Applicationで以下を直接利用しない。

```php
now();
```

```php
Carbon::now();
```

```php
new DateTimeImmutable('now');
```

UseCaseが現在日時を必要とする場合はClockから取得する。

例：

```php
$now = $this->clock->now();

$employee->retire($now);
```

---

## 19. UTC

Backend内部のInstantはUTCを基準とする。

```text
Browser
    ↓
Timezone付きDateTime
    ↓
Next.js BFF
    ↓
Laravel
    ↓
UTC
    ↓
PostgreSQL
```

基本設定：

```text
Application Timezone
    → UTC

Database Session Timezone
    → UTC
```

Server Local Timeに依存する実装を避ける。

---

## 20. Time Zone Conversion

Time Zone変換はBoundaryで行う。

```text
Stored Instant
    ↓
UTC

API
    ↓
UTCを基本

UI
    ↓
必要に応じてUser向けTimezoneへ変換
```

Backend Domain Model内部で表示Timezoneを意識しない。

---

## 21. PostgreSQL Timestamp

Instantを保存するDatabase Typeには以下を採用する。

```text
timestamp with time zone
```

PostgreSQL Alias：

```text
timestamptz
```

対象例：

```text
created_at
updated_at
retired_at
permission_changed_at
```

---

## 22. `timestamp without time zone`

以下は標準のInstant保存用途には使用しない。

```text
timestamp without time zone
```

これは、

> Time Zoneに依存しないLocal DateTime

という意味を持つ値がRequirementとして存在する場合のみ使用する。

単なる日時Columnだからという理由で利用しない。

---

## 23. Laravel Migration

Instant ColumnはMigrationでもTimezone-aware型を明示する。

例：

```php
$table->timestampTz('created_at');
$table->timestampTz('updated_at');

$table
    ->timestampTz('retired_at')
    ->nullable();
```

Projectの日時方針との整合を優先し、Laravel Helperを機械的に選択しない。

---

## 24. created_at / updated_at

Infrastructureでは標準的に以下を利用する。

```text
created_at
updated_at
```

ただしMigrationではProjectのTimezone Strategyに合わせた型を使用する。

また、

```text
updated_at
```

をBusiness Eventの日時として代用しない。

例えば、

```text
retired_at
permission_changed_at
```

は専用Columnとして保持する。

---

## 25. PostgreSQL Session Time Zone

PostgreSQL ConnectionのSession Time ZoneはUTCとする。

```text
PostgreSQL Session
    ↓
UTC
```

これにより、

```text
Application
Database Connection
Stored Instant
```

のTime Zone解釈を統一する。

---

## 26. API Instant Format

APIでInstantを返す場合はRFC 3339互換のTimezone付き文字列とする。

基本例：

```json
{
  "created_at": "2026-09-12T10:03:24Z"
}
```

Fractional Secondsが必要な場合：

```json
{
  "created_at": "2026-09-12T10:03:24.123Z"
}
```

以下の形式はPublic APIでは使用しない。

```text
2026/09/12 19:03
2026-09-12 19:03:00
09/12/2026
```

Timezone情報のない独自DateTime Formatを避ける。

---

## 27. Fractional Seconds

DatabaseではPostgreSQLのNative Timestamp Precisionを利用できる。

APIではMVP時点で、

```text
Seconds
または
Milliseconds
```

までを想定する。

マイクロ秒をAPI Contract上必須にしない。

OpenAPIとSerialization TestでFormatを統一する。

---

## 28. Date

日付のみの値には以下を利用する。

API：

```text
YYYY-MM-DD
```

例：

```json
{
  "date": "2026-09-12"
}
```

Database：

```sql
date
```

Date自体にTimezoneを持たせない。

---

## 29. YearMonth

年月のみを表すBusiness Conceptは`YearMonth` Value Objectとして扱う。

対象例：

```text
EmployeeSkill.last_used_year_month
```

Domain例：

```php
final readonly class YearMonth
{
    public function __construct(
        public int $year,
        public int $month,
    ) {
        if ($month < 1 || $month > 12) {
            throw new InvalidArgumentException();
        }
    }

    public function toString(): string
    {
        return sprintf(
            '%04d-%02d',
            $this->year,
            $this->month,
        );
    }
}
```

---

## 30. YearMonth API Representation

APIでは以下へ統一する。

```text
YYYY-MM
```

例：

```json
{
  "last_used_year_month": "2026-09"
}
```

TimestampやFull DateをAPI上のYearMonthとして使用しない。

---

## 31. YearMonth Database Representation

YearMonthはPostgreSQLの`date`型で月初日をPersistence Representationとして保存する。

例えば、

```text
Domain / API
    ↓
2026-09

Database
    ↓
2026-09-01
```

とする。

Database上の`01`はBusiness上の「1日」を意味せず、Persistence表現上のConventionとする。

変換はMapper / Query Service Boundaryへ閉じ込める。

---

## 32. YearMonth DB表現の理由

月初日の`date`を採用する理由：

- PostgreSQL Native `date`を利用できる
- Sortが自然
- Range Queryが自然
- Year / Monthを2 Columnへ分割するより単純
- `YYYY-MM`文字列保存よりDatabase Operationしやすい
- Domain / APIではYearMonthとして隠蔽できる

以下は採用しない。

```text
timestampとして保存
YYYY-MM stringをそのままDB保存
year / monthを原則2 Column化
```

Requirementにより必要性が出た場合のみ再検討する。

---

## 33. Experience Period

実務経験期間はDateTimeではなくDurationとして扱う。

Domainでは、

```text
ExperiencePeriod
```

Value Objectを利用する。

内部表現はTotal Monthsを基本とする。

例：

```text
2年3か月
    ↓
27 months
```

---

## 34. Experience Period Database Representation

Databaseでは、

```text
experience_months
```

としてintegerで保持する。

例：

```text
27
```

API：

```json
{
  "experience_months": 27
}
```

PostgreSQL `interval`はMVPでは利用しない。

---

## 35. Eloquent Date Cast

InfrastructureのEloquent ModelではImmutable Date Castを利用する。

例：

```php
protected function casts(): array
{
    return [
        'created_at' => 'immutable_datetime',
        'updated_at' => 'immutable_datetime',
        'retired_at' => 'immutable_datetime',
    ];
}
```

Eloquent Date ObjectをDomainへ直接公開しない。

```text
Eloquent
    ↓
Mapper
    ↓
DateTimeImmutable
    ↓
Domain
```

とする。

---

## 36. Eloquent Serializationとの分離

Eloquent Date Serialization設定はInfrastructure Convenienceとして扱う。

Public API FormatはAPI Resourceで定義する。

```text
Eloquent Cast
    ↓
Infrastructure Concern

API Resource
    ↓
Public Contract
```

Eloquent ModelのSerialization設定をAPI ContractのSource of Truthにしない。

---

## 37. ID基本方針

既存方針通りDatabase Primary Keyには以下を利用する。

```text
bigint
```

Domain / ApplicationではTyped ID Value Objectへ変換する。

例：

```php
final readonly class EmployeeId
{
    public function __construct(
        public int $value,
    ) {
        if ($value <= 0) {
            throw new InvalidArgumentException();
        }
    }
}
```

---

## 38. ID生成

ID生成は既存方針通りPostgreSQL Sequenceを利用する。

```text
PostgreSQL nextval()
    ↓
PHP int
    ↓
Typed ID
    ↓
Aggregate::register()
```

ApplicationではID Generator Port経由で取得する。

Serialization設計はID生成方式へ影響させない。

---

## 39. API ID Representation

Public APIではbigint IDをstringとして扱う。

例：

```json
{
  "id": "123"
}
```

Foreign IDも同様。

```json
{
  "employee_id": "123",
  "skill_id": "42"
}
```

API内でinteger / stringを混在させない。

---

## 40. bigintをAPI stringにする理由

PostgreSQL `bigint`は64-bit Signed Integerである。

FrontendのJavaScript / TypeScriptでは`number`の安全な整数精度に上限があるため、Database bigint全範囲を正確に扱えるとは限らない。

そのためBoundaryを以下に統一する。

```text
PostgreSQL
    ↓
bigint

PHP
    ↓
int

Domain
    ↓
Typed ID

API
    ↓
string

TypeScript
    ↓
string
```

Frontend側で精度Lossを起こさないことを優先する。

---

## 41. Request ID Representation

ResponseだけでなくRequestでもIDをstringとして扱う。

例：

```http
GET /api/v1/employees/123
```

Path Parameterは文字列として受け取り、Presentation BoundaryでValidationする。

```text
"123"
    ↓
Validation
    ↓
PHP int
    ↓
EmployeeId
```

---

## 42. ID Validation

API上のIDは正の10進整数Stringとして扱う。

概念：

```text
^[1-9][0-9]*$
```

さらにPHP bigint範囲・Database IDとして妥当かをApplication Boundaryで確認する。

Clientから、

```text
0
-1
1.5
abc
```

等をIDとして受け付けない。

---

## 43. OpenAPI ID Schema

OpenAPIではIDをstringとして定義する。

例：

```yaml
EmployeeId:
  type: string
  pattern: '^[1-9][0-9]*$'
  example: '123'
```

同形式でもDomain意味ごとにSchema Nameを分ける。

例：

```text
EmployeeId
EmployeeSkillId
SkillId
SkillCategoryId
DepartmentId
UserId
```

型の意味をOpenAPI上でも明確にする。

---

## 44. OpenAPI DateTime

Instantは以下。

```yaml
created_at:
  type: string
  format: date-time
```

API実装ではTimezone付きRFC 3339形式を返す。

---

## 45. OpenAPI Date

Dateは以下。

```yaml
date:
  type: string
  format: date
```

表現：

```text
YYYY-MM-DD
```

---

## 46. OpenAPI YearMonth

OpenAPI標準FormatとしてYearMonthは存在しないため、string + patternを使用する。

例：

```yaml
last_used_year_month:
  type:
    - string
    - 'null'
  pattern: '^[0-9]{4}-(0[1-9]|1[0-2])$'
  example: '2026-09'
```

APIとDomainのYearMonth表現を一致させる。

---

## 47. Enum OpenAPI Schema

EnumはBacked ValueをSchemaへ定義する。

例：

```yaml
WorkExperience:
  type: string
  enum:
    - experienced
    - unexperienced
```

Skill Level：

```yaml
SkillLevel:
  type: integer
  enum:
    - 1
    - 2
    - 3
    - 4
    - 5
```

PHP Enum Case NameではなくPublic Backed Valueを定義する。

---

## 48. API Serialization例

EmployeeSkillのResponse例：

```json
{
  "id": "1001",
  "employee_id": "100",
  "skill_id": "20",
  "skill_level": 3,
  "work_experience": "experienced",
  "experience_months": 27,
  "last_used_year_month": "2026-09",
  "created_at": "2026-09-12T10:03:24Z",
  "updated_at": "2026-09-12T10:03:24Z"
}
```

実務未経験の場合：

```json
{
  "id": "1002",
  "employee_id": "101",
  "skill_id": "20",
  "skill_level": 1,
  "work_experience": "unexperienced",
  "experience_months": null,
  "last_used_year_month": null,
  "created_at": "2026-09-12T10:03:24Z",
  "updated_at": "2026-09-12T10:03:24Z"
}
```

---

## 49. Read ModelとSerialization

Read ModelはAPI Resourceへ必要な情報を渡す。

例：

```text
Query Service
    ↓
EmployeeSkillReadModel
    ↓
EmployeeSkillResource
    ↓
JSON
```

Read Modelを必ずAPI Shapeと完全一致させる必要はない。

API Contractへの最終変換責務はResourceに持たせる。

---

## 50. Write ResultとSerialization

Write SideではDomain EntityをControllerへそのまま返さない。

例：

```text
Command Handler
    ↓
EmployeeSkillId
または
RegisterEmployeeSkillResult
    ↓
Controller / Resource
    ↓
JSON
```

単純に生成IDだけ必要な場合はTyped IDを返すこともできる。

複数情報が必要な場合はUseCase固有Resultを利用する。

---

## 51. Serialization Test

API SerializationはFeature Testを中心に確認する。

確認対象：

```text
ID
    → string

Enum
    → Backed Value

Instant
    → Timezone付きRFC 3339

Date
    → YYYY-MM-DD

YearMonth
    → YYYY-MM

Duration
    → integer months

Nullable Field
    → null

Internal Field
    → Responseへ出ない
```

---

## 52. Date / Time Test

日時関連は以下をTestする。

```text
UTC Serialization
Timezone付きInput
UTC Conversion
Nullable Instant
YearMonth Validation
YearMonth Sort
December → January
Leap Year
Clock固定
```

現在時刻依存TestではFake Clockを使用する。

---

## 53. ID Test

IDについて以下を確認する。

```text
DB bigint
Typed ID生成
0以下拒否
API string serialization
Request string → Typed ID
Large bigint serialization
```

特にJavaScript Safe Integer範囲を超える値でもAPI Serializationが壊れないことを確認できるようにする。

---

## 54. OpenAPI Contract Test

以下がOpenAPIと実装で一致することをContract Testで確認する。

```text
ID = string
Enum Backed Value
DateTime Format
Date Format
YearMonth Pattern
Nullable
Required Field
```

OpenAPIをSource of Truthとして維持する。

---

## 55. Serialization Library

追加Serialization Frameworkは採用しない。

採用：

```text
Laravel JsonResource
PHP Native Enum
DateTimeImmutable
DateTimeZone
Project Value Object
Laravel Eloquent Cast
OpenAPI
```

不採用：

```text
External Serializer Framework
AutoMapper
DTO Serialization Framework
Domain JsonSerializable標準化
Date Library追加
```

---

## 56. Date Library

追加Date LibraryはDomain / Application用途では採用しない。

基本：

```text
DateTimeImmutable
DateTimeZone
Project YearMonth
Project ExperiencePeriod
Clock Port
```

で対応する。

CarbonはLaravel / Infrastructure / Presentation内部で必要な場合のみ利用する。

---

## 57. ID Library

IDにはbigint + PostgreSQL Sequenceを利用するため、UUID系Libraryは採用しない。

```text
ramsey/uuid
ULID Library
Snowflake ID Library
```

等はMVPでは不要とする。

---

## 58. Library採用判断

| Library / 技術 | 判断 |
|---|---|
| Laravel JsonResource | 採用 |
| PHP Native Enum | 採用 |
| `DateTimeImmutable` | 採用 |
| `DateTimeZone` | 採用 |
| Application Clock Port | 採用 |
| PostgreSQL `timestamptz` | Instantに採用 |
| PostgreSQL `date` | Date / YearMonth Persistenceに採用 |
| Eloquent `immutable_datetime` | 採用 |
| Project YearMonth VO | 採用 |
| Project ExperiencePeriod VO | 採用 |
| bigint | DB IDとして採用 |
| Typed ID VO | 採用 |
| API ID string | 採用 |
| Carbon in Domain | 不採用 |
| Domain `JsonSerializable`標準化 | 不採用 |
| External Serializer | 不採用 |
| Date Library追加 | 不採用 |
| UUID / ULID | 不採用 |

---

## 59. 採用技術・方針一覧

| 項目 | 決定 |
|---|---|
| Serialization Boundary | Presentation |
| API Serialization | Laravel `JsonResource` |
| Eloquent直接Response | 禁止 |
| Domain直接JSON化 | 禁止 |
| JSON Naming | `snake_case` |
| Enum API表現 | Backed Value |
| VO API表現 | BoundaryでPrimitive化 |
| Nullable Value | `null` |
| Missing / Null | 意味を区別 |
| Instant Domain型 | `DateTimeImmutable` |
| Instant Application型 | `DateTimeImmutable` |
| Current Time | `Clock` Port |
| Carbon in Domain | 禁止 |
| Backend Timezone | UTC |
| DB Session Timezone | UTC |
| Instant DB Type | `timestamptz` |
| Local Timestamp | Requirementがある場合のみ |
| API Instant | RFC 3339 timezone付き |
| Date API | `YYYY-MM-DD` |
| Date DB | `date` |
| YearMonth Domain | Value Object |
| YearMonth API | `YYYY-MM` |
| YearMonth DB | 月初日の`date` |
| Experience Period | Total Months |
| Experience DB | integer months |
| Eloquent Date Cast | `immutable_datetime` |
| DB ID | bigint |
| ID Generation | PostgreSQL Sequence |
| Domain ID | Typed ID VO |
| API ID | string |
| OpenAPI ID | string |
| UUID / ULID | 不採用 |
| External Serializer | 不採用 |
| Date Library追加 | 不採用 |

---

## 60. 最終Architecture

Serialization：

```text
PostgreSQL
    ↓
Eloquent / Query Builder
    ↓
Mapper / Query Service
    ↓
Domain / Read Model
    ↓
API Resource
    ↓
JSON
```

Instant：

```text
PostgreSQL
    ↓
timestamptz

Infrastructure
    ↓
Immutable Date Object

Domain / Application
    ↓
DateTimeImmutable UTC

Presentation
    ↓
RFC 3339

API
    ↓
2026-09-12T10:03:24Z
```

YearMonth：

```text
PostgreSQL
    ↓
date
    ↓
2026-09-01

Mapper
    ↓
YearMonth

Domain
    ↓
2026-09

API Resource
    ↓
"2026-09"
```

ID：

```text
PostgreSQL
    ↓
bigint / Sequence

Infrastructure
    ↓
PHP int

Domain / Application
    ↓
Typed ID

Presentation
    ↓
string

API / TypeScript
    ↓
"123"
```

---

## 61. 最終方針

Serialization・Date・IDでは、

> Database Representation・Domain Representation・API Representationを同一視しない

ことを最重要原則とする。

```text
Database
    ↓
Persistenceに最適な型

Domain / Application
    ↓
Business意味に最適な型

Presentation
    ↓
API Contractに最適な型
```

日時については、

```text
Instant
Date
YearMonth
Duration
```

を明確に分離する。

Instantは、

```text
PostgreSQL timestamptz
    ↓
DateTimeImmutable UTC
    ↓
RFC 3339
```

とする。

YearMonthは、

```text
PostgreSQL date（月初日）
    ↓
YearMonth Value Object
    ↓
YYYY-MM
```

とする。

IDについては、

```text
Database
    → bigint

Domain / Application
    → Typed ID

API
    → string
```

とし、JavaScript / TypeScript側の整数精度問題からAPI Contractを保護する。

外部Serialization / Date / ID Frameworkを追加せず、

> Laravel JsonResource + PHP Native Types + Project Value Objects + PostgreSQL Native Types

という構成を採用する。
