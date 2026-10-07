# Date / Time 設計 決定版

## 1. 基本方針

日時情報は用途ごとに扱いを分ける。

### 日時として扱うもの

- created_at
- updated_at
- Session関連日時
- Token関連日時
- Audit / Log関連日時

### 日付として扱うもの

- retirement_date

### 年月として扱うもの

- last_used_date

`last_used_date` はDatabase上ではDate型として保存するが、
Application / API上では年月として扱う。

---

# 2. Timezone

## Database

PostgreSQLはUTCを基準として扱う。

## Laravel

Laravel内部のTimezoneはUTCを基本とする。

    APP_TIMEZONE=UTC

## Next.js

Next.js内部でも日時はUTC基準で扱う。

## Frontend表示

利用者向け表示ではApplication固定Timezoneを使用する。

    Asia/Tokyo

BrowserのTimezoneへ自動的に依存しない。

---

# 3. UTCを採用する理由

日時をUTCへ統一することで以下のメリットを得る。

- Server配置場所に依存しない
- Local / CI / Staging / Productionで挙動を揃えやすい
- 将来的なCloud変更に対応しやすい
- Timezone変換の責務を明確にできる
- Logの時系列を統一しやすい
- 複数Service間で日時を比較しやすい

---

# 4. PostgreSQL Timestamp

日時にはPostgreSQLの以下を使用する。

    timestamp with time zone

PostgreSQL上の表記：

    timestamptz

対象例：

- created_at
- updated_at
- Token Expiration
- Token Last Used
- Log日時

PostgreSQLで管理する日時はUTCを基本とする。

---

# 5. created_at / updated_at

Laravel標準の、

    created_at
    updated_at

を使用する。

意味：

    created_at
    → Record作成日時

    updated_at
    → Record最終更新日時

DatabaseではUTC基準で保存・取得する。

Frontendで表示する場合に、

    UTC
      ↓
    Asia/Tokyo

へ変換する。

---

# 6. API Timestamp形式

日時をAPIで返す場合はISO 8601形式を使用する。

基本：

    YYYY-MM-DDTHH:mm:ssZ

例：

    2026-08-19T11:30:00Z

UTCを基準とする。

必要がない限り、

    2026-08-19T20:30:00+09:00

のようなLocal Offset付き形式をBackend APIの標準にはしない。

---

# 7. retirement_date

社員の実際の退職日を表す。

Database Type：

    date

例：

    2026-08-31

Timezone変換は行わない。

理由：

`retirement_date` は時刻ではなく業務上の日付だから。

---

## API

OpenAPIでは：

    type: string
    format: date

例：

    "retirementDate": "2026-08-31"

---

## Validation

### ACTIVE

    retirement_date = NULL

### LEAVE

    retirement_date = NULL

### RETIRED

    retirement_date IS NOT NULL

Laravel ValidationとPostgreSQL CHECK Constraintの両方で保証する。

---

## 未来日

MVPでは未来の退職日は登録できないことを第一方針とする。

概念：

    retirement_date <= today

ただし現在日時に依存するValidationはLaravel側で行う。

Database CHECK Constraintには含めない。

将来的に「退職予定日」が必要になった場合は、
`retirement_date`とは別項目として設計する。

---

# 8. last_used_date

社員がそのSkillを最後に実務で利用した年月を表す。

業務上の意味：

    最終利用年月

例：

    2026年8月

---

## Database

Database Type：

    date

保存形式：

    YYYY-MM-01

例：

    2026年8月
        ↓
    2026-08-01

日部分の`01`には業務上の意味はない。

年月をDate型1カラムで正規化するために使用する。

---

## Application / API

ApplicationとAPIでは年月として扱う。

形式：

    YYYY-MM

例：

    2026-08

Databaseの、

    2026-08-01

をそのままFrontendへ公開する必要はない。

---

# 9. last_used_dateの業務ルール

## 実務経験なし

    has_work_experience = false

の場合：

    last_used_date = NULL

---

## 実務経験あり

    has_work_experience = true

の場合：

    last_used_date IS NOT NULL

---

## 未来年月

未来の年月は登録できない。

例えばApplication上の現在年月が、

    2026-08

の場合：

    2026-08
    → OK

    2026-09
    → NG

このValidationはLaravel側で行う。

---

# 10. last_used_date 月初日Constraint

Database上では設定されている`last_used_date`が
必ず月初日であることを保証する。

概念：

    CHECK (
        last_used_date IS NULL
        OR EXTRACT(DAY FROM last_used_date) = 1
    )

例：

    2026-08-01
    → OK

    2026-08-15
    → NG

---

# 11. EmployeeSkill Date Rule

EmployeeSkillでは以下の整合性を保証する。

概念：

    CHECK (
        (
            has_work_experience = false
            AND experience_months = 0
            AND skill_level = 1
            AND last_used_date IS NULL
        )
        OR
        (
            has_work_experience = true
            AND experience_months >= 1
            AND skill_level BETWEEN 1 AND 5
            AND last_used_date IS NOT NULL
        )
    )

Laravel側でも同じルールをValidationする。

---

# 12. DateとTimestampの使い分け

## Timestampを使用する

- created_at
- updated_at
- Session関連日時
- Token関連日時
- Login日時を将来保持する場合
- Log
- Audit Logを将来追加する場合

Timezone変換対象とする。

---

## Dateを使用する

- retirement_date

Timezone変換しない。

---

## Year-Monthとして扱う

- last_used_date

Database：

    YYYY-MM-01

API / Frontend：

    YYYY-MM

として扱う。

Timezone変換しない。

---

# 13. Frontend表示形式

基本候補：

## 日時

    YYYY/MM/DD HH:mm

例：

    2026/08/19 20:30

## 日付

    YYYY/MM/DD

例：

    2026/08/31

## 年月

    YYYY/MM

例：

    2026/08

具体的な表示コンポーネントはUI設計時に統一する。

---

# 14. Next.js

Next.jsではBackend APIから取得したISO 8601日時を
UTCとして扱う。

表示時：

    UTC
      ↓
    Asia/Tokyo

へ変換する。

Server Component / Client Componentで
異なるTimezone処理にならないよう、
日時変換処理を共通化することを検討する。

---

# 15. Laravel

Laravel内部TimezoneはUTCを使用する。

基本：

    APP_TIMEZONE=UTC

日時をLocal Timezoneへ変換してから
Databaseへ保存する実装は行わない。

API Responseでも日時はUTCを基本とする。

---

# 16. PostgreSQL

PostgreSQLのSession TimezoneもUTCを基本とする。

Server OSのTimezoneへ依存しない。

Local / CI / Staging / Productionで
同じTimezone方針を使用する。

---

# 17. Docker

開発環境の以下のContainerについても、
内部TimezoneはUTCを基本とする。

- frontend
- backend
- postgres

Application固有の表示Timezoneは、

    Asia/Tokyo

としてApplication Layerで扱う。

---

# 18. Better Auth Session

Better Auth SessionはRedisで管理する。

Session関連日時はUTC基準で扱う。

対象例：

- Session Expiration
- Session作成日時
- Session更新日時

Better Auth SessionはPostgreSQLへ保存しないため、
PostgreSQLの`timestamp` / `timestamptz`設計対象とはしない。

Session ExpirationとRedis TTLは整合させる。

具体的なSession Lifetime / Redis TTLは認証詳細設計で決定する。

Browserへは必要最小限のSession情報のみ公開する。

---

# 19. Laravel Sanctum

Sanctum Tokenで日時を扱う場合もUTCを使用する。

例：

- created_at
- last_used_at
- expires_at

Tokenの有効期限に関する具体的な時間は
認証詳細設計で決定する。

---

# 20. Log

Application LogのTimestampはUTCを基本とする。

対象：

- Next.js Log
- Laravel Log
- Authentication Log
- Authorization Failure
- Error Log

必要に応じてLog Viewer側でAsia/Tokyoへ変換する。

---

# 21. Test

日時に依存するTestでは現在時刻を固定する。

対象例：

- 退職後3年経過判定
- 未来退職日Validation
- 最終利用年月Validation
- Session期限
- Token期限

実際の現在日時へ直接依存するTestを避ける。

Laravelでは必要に応じてCarbonのTest Clock等を利用する。

---

# 22. 退職後3年判定

退職後3年の判定には、

    retirement_date

を使用する。

判定：

    retirement_date + 3 years <= current_date

例：

    retirement_date
    2026-08-31

の場合：

    2029-08-31
    → 3年経過

となる。

3年経過後も自動削除はしない。

    3年経過
        ↓
    削除確認対象
        ↓
    管理ユーザー確認
        ↓
    削除

とする。

---

# 23. OpenAPI Date / Time

用途ごとにOpenAPI Schemaを分ける。

## Timestamp

    type: string
    format: date-time

例：

    2026-08-19T11:30:00Z

---

## Date

    type: string
    format: date

例：

    2026-08-31

対象：

    retirementDate

---

## Year-Month

OpenAPI標準にはYear-Month専用Formatがないため、
String + Patternで表現する。

例：

    type: string
    pattern: '^\d{4}-(0[1-9]|1[0-2])$'

値：

    2026-08

対象：

    lastUsedMonth

---

# 24. 現在日時に依存するConstraint

以下のような条件はPostgreSQL CHECK Constraintへ入れない。

例：

    retirement_date <= CURRENT_DATE

    last_used_date <= CURRENT_DATE

現在日時に依存する業務ValidationはLaravel側で行う。

Databaseでは時間経過に依存しない
構造的整合性のみ保証する。

---

# 25. DatabaseとApplicationの責務

## PostgreSQL

以下を保証する。

- 日付型
- NULL / NOT NULL
- 月初日Constraint
- employment_statusとretirement_dateの整合性
- EmployeeSkillの構造的整合性

## Laravel

以下を保証する。

- 未来退職日の禁止
- 未来最終利用年月の禁止
- 退職後3年経過判定
- その他現在日時を基準とする業務ルール

## Next.js

以下を担当する。

- UTC日時の受け取り
- Asia/Tokyoへの表示変換
- Date / Year-Monthの表示形式統一

---

# 26. 決定事項

## Timezone

内部処理・保存：

    UTC

Frontend表示：

    Asia/Tokyo

---

## Timestamp

PostgreSQL：

    timestamptz

対象：

- created_at
- updated_at
- Session
- Token
- Log

---

## API Timestamp

ISO 8601 + UTC：

    2026-08-19T11:30:00Z

---

## retirement_date

Database：

    date

API：

    YYYY-MM-DD

Timezone変換しない。

---

## last_used_date

Database：

    date

保存：

    YYYY-MM-01

API / Frontend：

    YYYY-MM

Timezone変換しない。

---

## 現在日時依存Validation

Laravel側で行う。

---

## PostgreSQL CHECK

時間経過に依存しない構造的なConstraintのみ設定する。

---

## Test

日時を固定してTestする。
