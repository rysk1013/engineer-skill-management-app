# Date・Utility

## 1. 目的

本ドキュメントでは、FrontendにおけるDate / DateTime / Year-Monthの取り扱い、および汎用Utilityの技術選定と実装方針を定義する。

対象：

- Date Library
- Date
- DateTime
- Year-Month
- Timezone
- Parse / Format
- Date Calculation
- Experience Duration
- Utility Function
- Native JavaScript API
- Invalid Date Handling
- Test

本Projectでは特に以下を扱う。

- 最終利用年月
- 退職日
- 作成日時
- 更新日時
- 経験期間

API上の日付ContractについてはOpenAPI、
BackendでのDomain RuleについてはBackend Architecture、
国際化・Timezoneについては非機能要件に従う。

---

# 2. 基本方針

Date Utility Libraryには **date-fns** を採用する。

Locale依存の表示には
JavaScript標準の **Intl API** を利用する。

基本構成：

    API
     ↓
    ISO / Explicit String
     ↓
    Frontend Boundary
     ↓
    +-----------------------------+
    |                             |
    v                             v
date-fns                     Intl API
Calculation                  Presentation
Comparison                   Locale Format
Parse

Project固有のDate Ruleについては
Application Utilityとして明示的に実装する。

以下を基本原則とする。

- API BoundaryではDate / DateTimeをStringとして扱う
- Year-MonthをJavaScript Dateとして扱わない
- DateTimeのTimezoneを曖昧にしない
- Date Calculationにはdate-fnsを利用する
- Locale依存表示にはIntlを優先する
- Date FormattingをComponentへ散在させない
- Project固有RuleをGeneric Date Utilityへ混在させない
- Invalid Dateを暗黙的に処理しない
- Moment.js等の複数Date Libraryを併用しない

---

# 3. Date Library

## 3.1 採用

Date Libraryには **date-fns** を採用する。

主な用途：

- Date Calculation
- Date Comparison
- Date Manipulation
- Parse補助
- Start / End Calculation
- Difference Calculation

---

## 3.2 採用理由

主な理由：

- Function単位のAPI
- TypeScript対応
- Immutableな利用方法
- Tree-shakingしやすい
- 必要なFunctionだけ利用できる
- Native `Date` と組み合わせやすい
- React / Next.jsへ依存しない
- Date Calculationを明示的に記述しやすい

---

## 3.3 Day.js

Day.jsは採用しない。

軽量で扱いやすいLibraryではあるが、
本Projectではdate-fnsのFunction-based APIを採用する。

複数Date Libraryを併用しない。

---

## 3.4 Luxon

LuxonはTimezoneやDateTime処理に強いが、
本ProjectのMVPでは必要以上に高機能である。

採用しない。

---

## 3.5 Moment.js

Moment.jsは採用しない。

新規Projectで採用する理由がない。

---

## 3.6 Temporal

Temporalは将来の再評価候補とする。

本ProjectではMVP時点で
Date処理の中心技術には採用しない。

Runtime / Ecosystem / Project要件を確認し、
将来的にNative Temporalへ移行する価値が出た場合に再評価する。

Temporalを採用するまでは、
独自Date Wrapperを大量に作って将来のTemporal APIを模倣しない。

---

# 4. Date / DateTime / Year-Monthの扱い

## 4.1 値の種類を区別する

以下を同じ「日付」として扱わない。

    Date
    DateTime
    Year-Month
    Duration

それぞれ意味が異なる。

---

## 4.2 Date

日付だけを表す値。

例：

    2026-09-11

API BoundaryではStringとして扱う。

主な用途：

- 退職日
- 日単位のBusiness Date

---

## 4.3 DateTime

日時を表す値。

例：

    2026-09-11T10:30:00+09:00

または、

    2026-09-11T01:30:00Z

API BoundaryではISO 8601形式のStringとして扱う。

主な用途：

- created_at
- updated_at
- Audit Timestamp

---

## 4.4 Year-Month

年月だけを表す値。

例：

    2026-09

主な用途：

- 最終利用年月

Year-MonthをJavaScript `Date` へ変換しない。

避ける：

    new Date("2026-09")

Year-Monthには、

- Day
- Time
- Timezone

という概念が存在しないためである。

---

## 4.5 Year-Month表現

Frontendでは基本的に、

    YYYY-MM

形式のStringとして扱う。

必要に応じてType Aliasを利用できる。

概念：

    type YearMonth = string

ただし単なるType AliasだけではRuntime Safetyを保証できない。

External Inputから取得する場合は
Runtime Validationを行う。

---

## 4.6 Branded Type

Year-Monthの取り違えが実際に問題になった場合は、
将来的にBranded Type等を検討できる。

MVPでは過度なType Abstractionを導入しない。

---

## 4.7 Duration

経験期間はDateとは別の概念として扱う。

例えば、

    3 years 6 months

を特定Timestampとして表現しない。

---

# 5. Timezone

## 5.1 基本方針

DateTimeではTimezoneを明示する。

Timezoneなしの曖昧なDateTimeを
API Contractで利用しない。

避ける：

    2026-09-11 10:30:00

推奨：

    2026-09-11T10:30:00+09:00

または、

    2026-09-11T01:30:00Z

---

## 5.2 API

API DateTimeは
ISO 8601 / RFC 3339互換形式を基本とする。

FrontendでTimezoneを推測しない。

---

## 5.3 Storage

Database StorageのTimezone方針は
Backend / Database設計に従う。

FrontendがDatabase Storage形式へ依存しない。

---

## 5.4 Display

UserへDateTimeを表示する場合は、
Applicationで定義されたTimezone Policyに従う。

Timezone変換をComponentごとに独自実装しない。

---

## 5.5 Date / Year-Month

DateおよびYear-Monthについては
不要なTimezone変換を行わない。

例えば、

    2026-09

をTimezone変換して
別のMonthになるような処理を行わない。

---

# 6. Parse・Format

## 6.1 Parse

API BoundaryではStringとして受け取り、
Date Calculationが必要な場合のみParseする。

    API String
        ↓
    Parse
        ↓
    Date
        ↓
    Calculation

すべてのAPI Responseを受信直後に
Dateへ変換しない。

---

## 6.2 Format

Locale依存の表示には
**Intl.DateTimeFormat** を優先する。

例えば、

    2026-09-11
        ↓
    2026/09/11

などの表示を行う。

---

## 6.3 Formatting Utility

同じFormatを複数箇所で利用する場合は
Utilityとして共通化する。

概念：

    formatDate()
    formatDateTime()
    formatYearMonth()

Component内でFormat Stringを
大量に直接記述しない。

---

## 6.4 Year-Month Format

Year-Monthについては
Dateへ変換せず直接Formatする。

例えば、

    2026-09
       ↓
    2026年9月

とする。

---

## 6.5 API FormatとDisplay Format

API FormatとDisplay Formatを分離する。

    API
    2026-09-11

        ↓

    Display
    2026/09/11

Display用StringをAPIへ送り返さない。

---

## 6.6 Input Format

HTML Input等が要求するFormatと
Display Formatも分離する。

例えば、

    API
    2026-09

    <input type="month">
    2026-09

    Display
    2026年9月

とする。

---

# 7. Experience Duration

## 7.1 基本方針

経験期間をDateTimeとして扱わない。

経験期間はDurationとして扱う。

例えば、

    years
    months

または、

    totalMonths

として表現する。

---

## 7.2 内部計算

Frontendで経験期間を計算する場合は、
**totalMonths** を基準にする。

例えば、

    3 years 6 months

は、

    42 months

として計算できる。

表示時に、

    42
      ↓
    3年6か月

へ変換する。

---

## 7.3 理由

`years` と `months` を別々に計算すると、

    1 year 14 months

のような不正な状態が発生しやすい。

CalculationではtotalMonthsへNormalizeする。

---

## 7.4 Minimum Experience

実務経験ありの場合、

    totalMonths >= 1

をFrontend Validationでも確認する。

ただし最終的なInvariantは
Backend Domain Layerで保証する。

---

## 7.5 未経験

実務未経験の場合は
経験期間を0か月としてBusiness Data化するのではなく、
API Contract / Domain Modelの定義に従って
「経験期間なし」と明確に区別する。

Frontend独自の意味付けを追加しない。

---

## 7.6 表示Utility

Project固有Utilityとして、

    formatExperienceDuration()

のようなFunctionを利用できる。

例えば、

    1
      ↓
    1か月

    12
      ↓
    1年

    42
      ↓
    3年6か月

とする。

これはGeneric Date Utilityではなく
Engineer Skill Management App固有のUtilityとして扱う。

---

# 8. Comparison・Calculation

## 8.1 Date Calculation

Date Calculationが必要な場合は
date-fnsを利用する。

例えば、

- add
- subtract
- difference
- compare
- startOf
- endOf

などである。

---

## 8.2 Native Arithmetic

Millisecondsを直接計算するような実装を避ける。

避ける：

    date.getTime() + 30 * 24 * 60 * 60 * 1000

Calendar Calculationでは、

- DST
- Month Length
- Leap Year

などを考慮する必要がある。

date-fns等のDate Operationを利用する。

---

## 8.3 Year-Month Comparison

Year-MonthはDateへ変換せず比較できる構成を優先する。

`YYYY-MM` のCanonical Formatを保証している場合、

    2026-08
    2026-09

のような値として扱える。

ただしExternal Inputは事前にValidationする。

---

## 8.4 Business Calculation

Business RuleをGeneric Date Utilityへ持たせない。

例えば、

    isRetiredEmployeeDeletable()

のようなRuleは
Generic `date.ts` に配置しない。

Business Ruleを担当するFeature / Domain相当のLayerへ配置する。

---

# 9. Utility Function設計

## 9.1 基本方針

Utility Functionを
巨大な `utils.ts` へ集約しない。

避ける：

    utils.ts
      ├── formatDate
      ├── formatMoney
      ├── buildEmployeeName
      ├── calculateExperience
      ├── parseURL
      └── ...

---

## 9.2 責務単位

Utilityは責務単位で分離する。

概念：

    lib/
      date/
      format/
      validation/

Feature固有UtilityはFeature側へ配置する。

---

## 9.3 Generic Utility

Generic Utility候補：

- Date Format
- Date Parse
- Year-Month Format
- Safe Conversion

Application固有Ruleを含めない。

---

## 9.4 Feature Utility

例えば、

    formatExperienceDuration()

のようにSkill Management固有の意味を持つFunctionは
Skill Feature側へ配置する。

---

## 9.5 Utility化の基準

1回しか利用しない単純処理を
機械的にUtility化しない。

以下の場合に共通化を検討する。

- 複数箇所で利用
- Ruleを統一する必要がある
- Test対象として独立させる価値がある
- Componentから責務を分離したい

---

## 9.6 Pure Function

Utilityは可能な限りPure Functionとする。

同じInputに対して
同じOutputを返す構成を優先する。

Environment / Global Stateへ
暗黙的に依存させない。

---

# 10. Native APIとの使い分け

## 10.1 基本方針

Libraryを利用する前に、
Native APIで十分な処理か確認する。

ただし複雑なDate Calculationを
無理にNative APIだけで実装しない。

---

## 10.2 Intl

Locale依存Formatには
Native `Intl` APIを利用する。

主な用途：

- Date Format
- DateTime Format
- Number Format
- Relative表示が必要な場合

---

## 10.3 String

Year-Monthなど、
Date Objectを必要としない値は
Stringとして扱う。

---

## 10.4 Date Object

JavaScript `Date` は、

- Timestamp
- DateTime Calculation
- Date LibraryとのIntegration

が必要な場合に利用する。

すべての日付関連値を
`Date` へ統一しない。

---

# 11. Error・Invalid Date Handling

## 11.1 基本方針

Invalid Dateを暗黙的に表示しない。

例えば、

    Invalid Date

をUserへそのまま表示しない。

---

## 11.2 API Data

OpenAPI Contractに適合するInternal API Dataについては
通常の型・Contract Testを信頼する。

ただしParseに失敗した場合は
Unexpected / Contract Errorとして扱う。

---

## 11.3 External Input

以下はValidationする。

- URL
- Form
- Browser Storage
- External API
- Unknown JSON

---

## 11.4 Fallback

DisplayでDataが存在しないことが正常な場合は、
明示的なFallbackを利用する。

例えば、

    -

    未設定

などをFeature要件に応じて表示する。

Invalid DataとMissing Dataを同一視しない。

---

## 11.5 Silent Correction

不正なDateを
Frontendで勝手に補正しない。

例えば、

    2026-02-31
       ↓
    2026-03-03

のようなNormalizationを
Business Dataに対して行わない。

Validation Errorとして扱う。

---

# 12. Test

## 12.1 基本方針

Date Utilityは
Boundary Caseを重点的にTestする。

---

## 12.2 Test対象

主な対象：

- Month Boundary
- Year Boundary
- Leap Year
- Invalid Date
- Nullable Value
- Year-Month Format
- Timezone Boundary
- Experience Duration

---

## 12.3 Experience Duration

例えば以下をTestする。

    1 month
        → 1か月

    11 months
        → 11か月

    12 months
        → 1年

    13 months
        → 1年1か月

    24 months
        → 2年

    42 months
        → 3年6か月

---

## 12.4 Time依存Test

現在時刻へ依存するTestでは、
System Clockへ直接依存しない。

Test FrameworkのFake Timer / System Time固定機能等を利用する。

---

## 12.5 Timezone依存Test

Timezoneによって結果が変わる処理は、
Test Environmentの暗黙Timezoneへ依存しない。

Expected Timezoneを明示してTestする。

---

# 13. 採用技術一覧

| 分類 | 採用技術 / 方針 |
|---|---|
| Date Library | date-fns |
| Locale Format | Native `Intl` |
| Date API Representation | `YYYY-MM-DD` String |
| DateTime API Representation | ISO 8601 / RFC 3339 compatible String |
| Year-Month | `YYYY-MM` String |
| Duration | totalMonthsを基本 |
| Date Calculation | date-fns |
| Date Comparison | date-fns / 適切なNative比較 |
| Year-Month Comparison | Validated Canonical String |
| Generic Utility | Pure Function中心 |
| Feature Utility | Feature内へ配置 |
| Runtime Validation | External / Untrusted Boundary |
| Date Test | Unit Test + Boundary Test |

---

## 13.1 不採用

| 技術 / 方針 | 理由 |
|---|---|
| Day.js | Date Libraryをdate-fnsへ統一 |
| Luxon | MVP要件に対して過剰 |
| Moment.js | 新規Projectでは採用しない |
| TemporalのMVP採用 | Runtime / Ecosystemを見て将来再評価 |
| 複数Date Library併用 | Responsibility / Bundle / APIの複雑化 |
| Year-Monthを `Date` 化 | Day / Timezoneという不要な概念が入る |
| API DateTimeのTimezone省略 | Interpretationが曖昧になる |
| Display FormatをAPIへ送信 | Transport / Presentation責務を分離 |
| Millisecond直接Calendar計算 | DST / Calendar Boundary問題 |
| 巨大 `utils.ts` | Responsibilityが不明確になる |
| Business RuleをGeneric Date Utilityへ配置 | Domain / Feature責務を維持 |
| Invalid Dateの自動補正 | Data Errorを隠す可能性がある |

---

# 14. 決定事項

Date Libraryには **date-fns** を採用する。

Locale依存のFormattingには
JavaScript標準の **Intl API** を利用する。

基本構成：

    API
     ↓
    Date / DateTime / Year-Month String
     ↓
    Frontend
     │
     ├── date-fns
     │      → Calculation / Comparison / Parse
     │
     ├── Intl
     │      → Locale-aware Presentation
     │
     └── Application Utility
            → Experience Duration等

以下をProject標準方針とする。

1. Date Libraryにはdate-fnsを利用する。
2. Locale依存FormatにはNative `Intl` を優先する。
3. 複数のDate Libraryを併用しない。
4. Day.jsは採用しない。
5. Luxonは採用しない。
6. Moment.jsは採用しない。
7. Temporalは将来的な再評価候補とする。
8. API BoundaryではDate / DateTimeをStringとして扱う。
9. Dateは `YYYY-MM-DD` を基本とする。
10. DateTimeはTimezoneを含むISO 8601 / RFC 3339互換表現を基本とする。
11. Timezoneなしの曖昧なDateTimeをAPI Contractで利用しない。
12. Year-Monthは `YYYY-MM` Stringとして扱う。
13. Year-MonthをJavaScript `Date` へ変換しない。
14. Date / DateTime / Year-Month / Durationを異なる概念として扱う。
15. API FormatとDisplay Formatを分離する。
16. Date Calculationが必要な場合のみStringからDateへParseする。
17. Date FormattingをComponentへ散在させない。
18. Year-MonthはDateへ変換せずFormatする。
19. 経験期間はDurationとして扱う。
20. Frontend内部の経験期間計算ではtotalMonthsを基本とする。
21. 実務経験ありの場合の1か月以上というRuleはFrontendでもValidationする。
22. Domain Invariantの最終保証はBackendで行う。
23. Project固有Date RuleをGeneric Date Utilityへ配置しない。
24. Generic UtilityとFeature Utilityを分離する。
25. 巨大な `utils.ts` を作らない。
26. Utilityは可能な限りPure Functionとする。
27. 単純処理を機械的にUtility化しない。
28. Calendar CalculationをMillisecondsの直接演算で実装しない。
29. External / Untrusted Date InputはRuntime Validationする。
30. Invalid DateとMissing Dateを区別する。
31. Invalid DateをUserへそのまま表示しない。
32. 不正なBusiness DateをFrontendで暗黙的に補正しない。
33. Date UtilityではMonth / Year / Leap Year / Timezone等のBoundaryをTestする。
34. Time依存TestではSystem Timeを固定する。
35. Timezone依存TestではEnvironmentの暗黙Timezoneへ依存しない。

以上を `Frontend/09_Date・Utility.md` の決定版とする。
