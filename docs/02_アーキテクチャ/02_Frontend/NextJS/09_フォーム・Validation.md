# 09_フォーム・Validation

## 1. 目的

本プロジェクトでは、Form State・Frontend Validation・Server Action・Laravel Validation・Domain Invariantの責務を明確に分離する。

目的は以下とする。

- Form StateをFeature内部へ閉じ込める
- Frontend ValidationをUX改善に限定する
- Client InputをServer側で再検証する
- Laravel Request ValidationとDomain Invariantを分離する
- Form ModelとAPI Request DTOの差異を適切に吸収する
- Laravel 422 Validation ErrorをFrontend FormへMapping可能にする
- Business RuleをFrontendへ過剰に複製しない
- Form送信時のNormalizationを明示する
- Server ActionをTrust Boundaryとして扱う
- Error / Pending / Revalidationの扱いを統一する

基本Flowを以下とする。

```text id="cigzjx"
Browser
  ↓
Form State
  ↓
Frontend Schema Validation
  ↓
Server Action
  ↓
Server-side Validation / Normalization
  ↓
Laravel API
  ↓
Laravel Request Validation
  ↓
Laravel Domain
```

責務を以下とする。

```text id="n9xh99"
Frontend Validation
=
UX / Input Assistance

Laravel Request Validation
=
API Request Correctness

Laravel Domain
=
Business Invariant
```

---

## 2. Formの基本配置

FormはFeature単位で管理する。

例：

```text id="02xxmo"
features/
└── employees/
    ├── components/
    │   └── employee-form.tsx
    ├── actions/
    │   ├── create-employee.ts
    │   └── update-employee.ts
    └── schemas/
        └── employee-form-schema.ts
```

Form Logicを`app/page.tsx`やGlobal Storeへ配置しない。

---

## 3. Form State

Form入力中の状態はForm Stateとして扱う。

主な例：

```text id="fzyzsk"
Input Value
Touched
Dirty
Field Error
Submitting
```

Form StateはFormのLifetimeへ閉じ込める。

```text id="thb77o"
Employee Form
     ↓
Employee Form State
```

---

## 4. Form StateをGlobal Storeへ置かない

以下の構成は採用しない。

```text id="otmyin"
Global Store
├── employeeForm
├── skillForm
├── permissionForm
└── ...
```

Form StateはFeature / Form Scopeで管理する。

---

## 5. Form Library

Form Libraryは **React Hook Formを第一候補**とする。

理由は以下とする。

- Field State管理
- Dirty / Touched管理
- Validation Error管理
- Server Error設定
- Schema Resolverとの連携
- Dynamic Field対応
- 不要な再Renderを抑えやすい

ただしArchitecture上、

```text id="nnfi9i"
React Hook Form必須
```

とはしない。

採用時点では、

```text id="npqk8u"
Form Library
=
React Hook Formを第一候補
```

とする。

---

## 6. Validation Schema

Frontend Validation SchemaはFeature内へ配置する。

```text id="8aen7x"
features/
└── employees/
    └── schemas/
        └── employee-form-schema.ts
```

Schemaの主な責務は以下とする。

```text id="4zv3w4"
required
string length
numeric format
date format
basic range
selectable value
入力間の単純な関連Validation
Parsing
Basic Normalization
```

---

## 7. Schema Library

Schema Validation Libraryは **Zodを第一候補**とする。

理由は以下とする。

- TypeScriptとの親和性
- Client / Server双方で利用可能
- React Hook Formとの連携
- parse / transform / preprocessが扱いやすい
- Search Params等へも応用可能

ただしZodを使ってFrontend Domain Modelを再構築しない。

---

## 8. Frontend Validationの責務

Frontend ValidationはUXのために行う。

例：

```text id="n2y3fw"
名前必須
文字数
数値形式
年月形式
選択必須
入力可能範囲
```

目的は、

```text id="rdm34e"
入力ミスを早く知らせる
```

ことである。

---

## 9. Frontend ValidationをSecurity Boundaryにしない

Browser上のValidationは回避可能である。

したがって、

```text id="6mofrp"
Frontend Validation
=
Security Guarantee
```

とは扱わない。

Server ActionおよびLaravelで再Validationする。

---

## 10. Laravel Request Validation

LaravelではAPI Requestとして正しい入力かを検証する。

例：

```text id="br25hm"
required
integer
string
max
exists
date_format
enum
```

Frontend Schemaが存在していてもLaravel Request Validationを省略しない。

---

## 11. Domain Validation

Business InvariantはLaravel Domainで最終保証する。

今回の代表例：

```text id="ejctgk"
実務未経験
→ Skill Level 1のみ

実務経験あり
→ 経験期間1か月以上

実務経験あり
→ 最終利用年月必須
```

Frontend Schemaのみで保証しない。

---

## 12. 三層Validation

Validationを以下の三層へ分離する。

```text id="32ju2x"
Frontend Schema
      ↓
Laravel Request Validation
      ↓
Laravel Domain Invariant
```

それぞれの責務：

```text id="xpfvwx"
Frontend
=
UX

Laravel Request Validation
=
Transport / Input Correctness

Laravel Domain
=
Business Correctness
```

---

## 13. Ruleの意図的な重複

同じRuleがFrontendとBackend双方に存在してよい。

例えば、

```text id="ekbesm"
実務経験あり
→ 最終利用年月必須
```

はFrontendでも即時Feedbackを行い、Laravel Domainでも最終保証する。

```text id="7k28a3"
Frontend
=
Early Feedback

Backend
=
Final Guarantee
```

という意図的な重複とする。

---

## 14. Business RuleをFrontendへ完全再実装しない

Laravel Domain RuleをFrontendへ完全コピーする構成は採用しない。

例えば以下のようなFrontend Domain Validatorを作らない。

```text id="qq8btu"
EmployeeSkillDomainValidator
```

FrontendではUI / Form UXに必要な範囲のみValidationする。

---

## 15. Frontendへ重複してよいRule

Backend RuleをFrontendにも置く場合は、以下を基準とする。

```text id="l86m16"
Userへ即時Feedbackする価値がある
UI制御に必要
単純でBackend Ruleと乖離しにくい
Backendでも必ず再検証される
```

---

## 16. Frontendで保証しないRule

以下のようなRuleはFrontend Schemaで保証しない。

```text id="u7j47h"
Permission管理者最低1人
複雑なResource Authorization
DB整合性
Transactionに依存するRule
他Aggregateとの整合性
Concurrencyに依存するRule
```

これらはLaravel / Database側で保証する。

---

## 17. Form Model

Form State用TypeはAPI Request DTOと分けてよい。

例：

```ts id="w7cvge"
type EmployeeSkillFormValues = {
  experienceYears: string;
  experienceMonths: string;
};
```

APIでは、

```ts id="tf8n6i"
{
  experienceYears: number;
  experienceMonths: number;
}
```

である場合がある。

したがって、

```text id="32b7m2"
Form Model
≠
API Request DTO
```

を許可する。

---

## 18. Form Data変換

送信時は以下のFlowで変換する。

```text id="lavfsf"
Form State
 ↓
Validation
 ↓
Normalization
 ↓
API Request DTO
```

例：

```text id="3heqd0"
"1"
↓
1
```

```text id="v5mni4"
""
↓
null / undefined
```

NormalizationはServer Action側を基本とする。

---

## 19. Client / Server Schema共有

必要に応じて同一Frontend SchemaをClient ComponentとServer Actionで共有する。

```text id="qx3ov4"
Client Form
   ↓
Schema

Server Action
   ↓
同じSchema
```

これにより、

```text id="i7hw34"
Client UX Validation
+
Server Boundary Validation
```

を同一Schema Definitionから実施できる。

---

## 20. Server Actionで再Validationする

Client側でValidation済みでもServer Actionでは必ず再Validationする。

```text id="a9wi64"
Client
 ↓
Validation成功
 ↓
Server Action
 ↓
再Validation
```

Client InputをTrustしないためである。

---

## 21. Form Submit

Form SubmissionにはServer Actionを第一候補とする。

基本Flow：

```text id="vk780m"
Form Submit
   ↓
Server Action
   ↓
Authentication
   ↓
Frontend Authorization
   ↓
Schema Validation
   ↓
Normalization
   ↓
API Request DTO
   ↓
API Client
   ↓
Laravel API
```

---

## 22. Server Actionの責務

Server Actionは以下を担当する。

```text id="phsimg"
Authentication
Frontend Authorization
Server-side Schema Validation
Normalization
API Request構築
API Client呼び出し
API Error Mapping
Revalidation
Redirect / Action Result
```

---

## 23. Server ActionをBusiness Logic Layerにしない

以下はServer Actionへ置かない。

```text id="2gw1v6"
Business Invariant
Domain Behavior
Transaction Rule
Aggregate間整合性
Persistence Rule
```

これらはLaravelへ置く。

---

## 24. Create / Update Form

Create / Updateで同じForm Componentを利用してよい。

例：

```text id="svh0bw"
EmployeeForm
├── Create
└── Edit
```

ただしConditional Logicが過度に増える場合はForm Componentを分離する。

共通化自体を目的としない。

---

## 25. Edit Form初期値

Edit Formの初期値はServer側で取得する。

```text id="x2qvg5"
Server Component
      ↓
getEmployee()
      ↓
EmployeeForm
      ↓
defaultValues
```

以下を標準としない。

```text id="hyy2jc"
Client Component Mount
      ↓
useEffect
      ↓
GET /employee
```

---

## 26. Initial Values変換

API DTOとForm Modelが異なる場合は必要に応じてMapperを利用する。

```text id="tu6le4"
API DTO
 ↓
toEmployeeFormValues()
 ↓
Form Model
```

例：

```text id="6w0bfk"
null
↓
""
```

など、Form表示向けRepresentation変換がある場合に利用する。

---

## 27. Submit Mapper

送信時は必要に応じて逆方向のMappingを行う。

```text id="vu986s"
Form Model
 ↓
toUpdateEmployeeRequest()
 ↓
Generated Request DTO
```

単純な変換であればServer Action内で直接変換してよい。

---

## 28. Mapperを過剰に作らない

以下のように実質的なRepresentation差分がない場合、専用Mapperを作らない。

```text id="olode6"
name
↓
name
```

Mapperは意味のある変換が存在する場合のみ利用する。

---

## 29. FormData

Server Actionで受け取る`FormData`はUntrusted Inputとして扱う。

```text id="vvabhn"
FormData
=
Unknown / Untrusted Input
```

そのままAPI Clientへ渡さない。

---

## 30. FormData Parsing

基本Flowを以下とする。

```text id="uvikx8"
FormData
 ↓
Plain Object化
 ↓
Schema Parse
 ↓
Typed Form Values
 ↓
Normalization
 ↓
API DTO
```

---

## 31. HTML Inputの型

HTML Formでは`input type="number"`等でもFormData上はStringとして扱われるケースを考慮する。

必要に応じてSchemaの、

```text id="f6ebar"
coerce
transform
preprocess
```

等を利用する。

---

## 32. Empty String / Null / Undefined

Form上の未入力値とAPI Contract上の未設定値を明示的に変換する。

```text id="8kvh1m"
""
↓
null / undefined
```

どちらへ変換するかはOpenAPI Contractに従う。

---

## 33. Optional / Nullable

OpenAPI上のOptional / Nullable Semanticsを維持する。

```text id="8c2h9v"
undefined
=
Fieldを送信しない

null
=
明示的に値なし
```

Frontend都合で、

```text id="8wo4an"
""
null
undefined
```

を無差別に扱わない。

---

## 34. Checkbox / Boolean

Checkbox等は明示的にBooleanへ正規化する。

```text id="eua7o2"
checked
→ true

unchecked
→ false
```

FormData上でField自体が存在しない可能性も考慮する。

---

## 35. Enum

Select等で利用する値はGenerated API Contractと整合させる。

```text id="0vm2ej"
UI Option
 ↓
Generated Enum Value
```

API ValueとUI Labelは分離する。

```text id="1pvus5"
API Value
=
ACTIVE

UI Label
=
在籍
```

---

## 36. Number

経験年数・月数等について、

```text id="yuaxac"
Form
=
string

API
=
number
```

の違いを許可する。

送信時に明示的にNumberへ変換する。

---

## 37. Date / Year-Month

年月等はAPI Contractで定義したFormatへ正規化する。

例：

```text id="8nrfp1"
API
=
YYYY-MM
```

表示時の、

```text id="ovm9bg"
2026年9月
```

とは分離する。

```text id="hvt8wd"
Presentation Format
≠
API Format
```

---

## 38. Conditional Fields

EmployeeSkill等の条件付きFormでは、Client側でInput状態を切り替えてよい。

例えば、

```text id="0f63bh"
WorkExperience
=
NO_EXPERIENCE
```

の場合、

```text id="jfd2nn"
Skill Level
→ Level 1のみ

Experience Duration
→ 非表示 / Disabled

Last Used
→ 非表示 / Disabled
```

とする。

これはUX上の制御とする。

---

## 39. Conditional UIとDomain Invariant

Frontendでは、

```text id="bqfzyh"
未経験
↓
Level 2〜5を選択不可
```

としてよい。

ただしLaravel Domainでも、

```text id="lrf9lo"
未経験
+
Level 2
=
Reject
```

を保証する。

Conditional UIをDomain Invariantの代替にはしない。

---

## 40. Disabled Field

Disabled FieldはSubmitされない可能性があるため、Server Action側で最終Request DTOを明示的に構築する。

例：

```text id="1lv0oi"
実務未経験
↓
experienceYears = null
experienceMonths = null
lastUsed = null
```

Browserから送られた不要値をそのまま信用しない。

---

## 41. Hidden Field

Hidden FieldもUntrusted Inputとして扱う。

```html id="rfk5rv"
<input type="hidden" name="employeeId" />
```

Browser上で変更可能であるため、

```text id="cykkn5"
hidden
=
trusted
```

とはしない。

Resource IDを利用するAuthorizationはLaravelでも必ず実施する。

---

## 42. Field Error

Field単位のValidation Errorは対象Fieldの近くへ表示する。

例：

```text id="xb3vqc"
experienceMonths
↓
「1か月以上入力してください」
```

---

## 43. Form-level Error

特定Fieldへ紐づけにくいErrorはForm-level Errorとして表示する。

例：

```text id="6pcde9"
この社員は現在更新できません
```

すべてのErrorをField Errorへ押し込まない。

---

## 44. Form Error分類

Form周辺のErrorを概ね以下へ分類する。

```text id="uvznox"
Field Error
Form Error
Authentication Error
Authorization Error
Conflict Error
System Error
```

Error Typeに応じてUI処理を分ける。

---

## 45. Laravel 422

Laravel Request Validation Errorは422として受け取り、Form ErrorへMappingする。

```text id="w0bmvs"
Laravel
 ↓
422
 ↓
API Error
 ↓
Server Action
 ↓
Field Error / Form Error
```

---

## 46. API Field NameとForm Field Name

Frontend Field NameとAPI Field Nameが異なる場合は明示的にMappingする。

例：

```text id="ob3uq7"
API
experience_months

Frontend
experienceMonths
```

Mapping処理を複数箇所へ散在させない。

---

## 47. Backend Validation Message

LaravelのValidation MessageをそのままUIへ表示することへ依存しない。

基本的には、

```text id="14xylp"
Backend Field / Error Code
      ↓
Frontend Message
```

へのMappingを優先する。

API MessageがFrontend表示用としてContract上保証されている場合のみ直接利用を許可する。

---

## 48. Localization

Validation MessageはFrontendの表示言語方針に従う。

MVPでは日本語を基本とする。

API Error Messageへ全面依存せず、将来的なInternationalizationを妨げない設計とする。

---

## 49. Submission State

Form Submit中は必要最小限の状態を管理する。

例：

```text id="rkqgkj"
Idle
Pending
Success
Error
```

用途：

```text id="sb1yz4"
Submit Button Disable
Loading表示
Double Submit抑制
Error表示
```

---

## 50. Double Submit

Submit中はButtonをDisableする等で二重送信を抑制する。

ただし、

```text id="4gx7xt"
Button Disable
=
Backend二重実行保証
```

ではない。

必要な整合性はLaravel側で保証する。

---

## 51. Pending UI

Server Action利用時はReact / Next.jsが提供するPending Stateを第一候補とする。

Formごとに独自のGlobal Loading Storeを作らない。

---

## 52. Create Success Flow

Create成功後は以下を基本とする。

```text id="tqtp0c"
Server Action
 ↓
Laravel成功
 ↓
必要範囲Revalidation
 ↓
Redirect
```

例：

```text id="du18zi"
Employee Create
↓
/employees/{employeeId}
```

具体的な遷移先はFeature UXに応じて決定する。

---

## 53. Update Success Flow

Update成功後はUXに応じて、

```text id="eysszk"
Revalidation
+
同画面維持
```

または、

```text id="09mg16"
Revalidation
+
Redirect
```

を選択する。

すべてのFormで同一遷移を強制しない。

---

## 54. Revalidation

Mutation成功後は影響するDataのみRevalidateする。

```text id="31siht"
Mutation成功
↓
Affected DataのみRevalidation
```

具体的なCache / Revalidation Strategyは`11_キャッシュ戦略.md`で定義する。

---

## 55. Validation Failure時のRevalidation

Validation Failureでは通常Server Stateは変化していないため、無条件Revalidationしない。

```text id="2wgtsl"
422
↓
Form Error返却
```

を基本とする。

---

## 56. Validation Failure時の入力保持

Validation Error時はUserの入力値を可能な限り維持する。

```text id="3vnd3r"
Submit
 ↓
Validation Error
 ↓
入力値維持
 ↓
Error表示
```

入力を最初からやり直させない。

---

## 57. Sensitive Form Data

Password等のSensitive Inputが存在する場合、Validation Error後に不必要に値を再表示・永続化しない。

以下へ不要に残さない。

```text id="vqcrpt"
Log
Error Object
Browser Storage
Global State
```

---

## 58. File Upload

File Uploadが必要になった場合は通常JSON Formとは別に設計する。

```text id="mrlmcb"
FormData
Route Handler
Streaming
Upload Size
Content Type
```

等を考慮し、通常Formの抽象化へ無理に押し込めない。

---

## 59. Dynamic Form

条件付きFormでは、

```text id="rrtfld"
watch
conditional rendering
derived state
```

等を利用してよい。

既存Stateから計算可能な値を不要に追加Stateへ保存しない。

---

## 60. Field Array

複数Skill一括登録等が将来必要になった場合はField Arrayを検討する。

MVPで単一登録が十分なら、先に複雑なDynamic Formを構築しない。

---

## 61. Form Component責務

Form Componentは主に以下を担当する。

```text id="2zj9jf"
Input Rendering
Form State
Client Validation
Field Error表示
Interaction
Submit Trigger
```

API通信詳細を直接担当させない。

---

## 62. Schema責務

Schemaは以下を担当する。

```text id="fyza88"
Input Shape
Frontend Validation
Parsing
Basic Normalization
```

以下を置かない。

```text id="qfhf5d"
API通信
Database Access
Laravel Authorization
Complex Domain Behavior
```

---

## 63. SchemaからAPI Clientへ依存しない

以下は禁止する。

```text id="k27qz9"
Schema
 ↓
API Client
```

Schemaは可能な限りPureなInput Validationへ寄せる。

---

## 64. Async Validation

Server問い合わせが必要なValidationをFrontend Schemaへ安易に組み込まない。

例：

```text id="6c06df"
社員番号重複
Skill Name重複
```

基本的にはSubmit後にLaravelでValidationする。

UX上明確な必要性がある場合だけ個別のClient-side Checkを検討する。

---

## 65. Uniqueness

Unique RuleはFrontend Validationだけでは保証できない。

基本防御：

```text id="ul0f4p"
Frontend
→ Early Feedback

Laravel
→ Validation / Application Rule

Database
→ UNIQUE Constraint
```

最終的な整合性はBackend / DBで保証する。

---

## 66. Race Condition

Submit前に重複Checkをして成功しても、その後に別RequestがDataを登録する可能性がある。

したがって、

```text id="w6v383"
Check API成功
=
登録可能保証
```

とはしない。

---

## 67. Confirmation Dialog

Delete / Disable等の破壊的操作ではConfirmation UIを利用する。

```text id="5myr6a"
Action Button
 ↓
Confirmation
 ↓
Server Action
```

ただしConfirmationはSecurity Mechanismではない。

---

## 68. Destructive Action

破壊的操作では以下を明確にする。

```text id="lam2bg"
対象
実行内容
不可逆性
復元可能性
```

今回Skillは物理削除ではなく無効化するため、UI上も「削除」と「無効化」のTerminologyを混同しない。

---

## 69. Accessibility

Formでは以下を考慮する。

- LabelとInputの関連付け
- Error MessageとInputの関連付け
- Keyboard操作
- Focus Management
- Required State
- Invalid State
- Screen Reader通知

既存のユーザビリティ・アクセシビリティ要件に従う。

---

## 70. Error時Focus

Submit時にValidation Errorがある場合、可能な限り最初のInvalid FieldへFocusする。

Dialog内Form等ではFocus Trapとの整合性も考慮する。

---

## 71. `disabled`と`readOnly`

`disabled`と`readOnly`の意味を区別する。

```text id="gj6795"
disabled
=
操作不可
Submit対象外になる可能性あり

readOnly
=
表示するが編集不可
```

FormDataの挙動を理解して選択する。

---

## 72. Controlled / Uncontrolled

全Fieldを無条件にControlled Componentへしない。

採用するForm Libraryの推奨方法に従い、不要な再Renderを増やさない。

---

## 73. Form Reset

State ResetはForm Ownerが担当する。

Create後に連続登録するUXならResetを検討する。

Edit後は、

```text id="jnqpv5"
最新Server Stateへ同期
```

または、

```text id="8d3t25"
Redirect
```

をUXに応じて選択する。

---

## 74. Unsaved Changes

入力項目が多く誤Navigationの影響が大きいFormではUnsaved Changes警告を検討する。

MVPからすべてのFormへ一律導入しない。

---

## 75. Browser Native Validation

HTML標準の、

```text id="0hzxkr"
required
min
max
type
```

等はUX補助として利用してよい。

ただしFrontend Schema / Server Validationの代替とはしない。

---

## 76. `noValidate`

Schema / Form LibraryでValidation表示を統一する場合、Browser Native Validationとの二重表示を避けるため`noValidate`を利用できる。

実装時に採用Libraryと合わせて決定する。

---

## 77. API ErrorとForm Error

すべてのAPI ErrorをForm Validation Errorとして扱わない。

基本的に以下のように分ける。

```text id="dfwngt"
422
→ Field / Form Validation Error

409
→ Conflict

401
→ Re-authentication

403
→ Forbidden

404
→ Not Found

5xx
→ System Error
```

詳細は`10_エラーハンドリング.md`で統一する。

---

## 78. Conflict

409等のConflictは、

```text id="c83jjj"
Userの入力Formatが誤っている
```

とは限らない。

Concurrency / Current State / Unique Conflict等とField Validationを区別する。

---

## 79. Form Action Result

Server ActionからClientへ返す結果は必要最小限とする。

概念例：

```ts id="ezpfec"
type FormActionResult = {
  success: boolean;
  fieldErrors?: Record<string, string[]>;
  formError?: string;
};
```

具体形は採用するReact / Next.js Form APIに合わせて調整する。

---

## 80. Success Data

Mutation成功後に最新DataをServer Renderingで再取得できる場合、Action ResultへEntity全体を返さない。

```text id="0ak24s"
Mutation
 ↓
Revalidation
 ↓
Server再取得
```

を基本とする。

---

## 81. Frontend Form SchemaとOpenAPI Schema

Frontend Form SchemaとOpenAPI Schemaは異なる責務を持つ。

```text id="x6hft3"
OpenAPI Schema
=
API Contract

Frontend Form Schema
=
User Input UX / Parsing
```

Form SchemaをOpenAPI Schemaから機械的に完全生成することを前提としない。

---

## 82. Generated TypeとFrontend Schema

Generated API TypeとFrontend Form Schemaを組み合わせる。

```text id="l8r86b"
FormData
 ↓
Frontend Schema
 ↓
Form Values
 ↓
Normalization
 ↓
Generated API Request Type
```

この境界を維持する。

---

## 83. EmployeeSkill Form Flow

EmployeeSkill Formでは以下を基本Flowとする。

```text id="mtltqp"
WorkExperience選択
       ↓
Frontend UI制御
       ↓
Skill Level / Duration / Last Used入力
       ↓
Frontend Schema Validation
       ↓
Server Action
       ↓
Server-side Validation
       ↓
Normalization
       ↓
Laravel API
       ↓
Request Validation
       ↓
Domain Invariant
```

---

## 84. EmployeeSkill：実務未経験

Frontendでは、

```text id="p5md4j"
WorkExperience
=
NO_EXPERIENCE
```

の場合、

```text id="mb7pwy"
Skill Level
→ Level 1のみ

Experience Duration
→ 非表示 / Disabled

Last Used
→ 非表示 / Disabled
```

とする。

送信Requestは意図した状態へ正規化する。

概念：

```text id="aakrq3"
workExperience = NO_EXPERIENCE
skillLevel = 1
experienceYears = null
experienceMonths = null
lastUsed = null
```

Laravel Domainでも同Invariantを最終保証する。

---

## 85. EmployeeSkill：実務経験あり

```text id="s9nhwx"
WorkExperience
=
EXPERIENCED
```

の場合、

```text id="p0kb13"
Skill Level
→ Level 1〜5

Experience Duration
→ 必須

Last Used
→ 必須
```

とする。

Frontendでは即時Feedbackを行い、Laravel Domainでも必ず再保証する。

---

## 86. Form Architecture全体像

```text id="z1d4kb"
┌─────────────────────────────────────┐
│ Browser                             │
│                                     │
│ Form Component                      │
│ Form State                          │
│ Frontend Schema Validation          │
│ Pending / Field Error               │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│ Next.js Server                      │
│                                     │
│ Server Action                       │
│ Authentication                      │
│ Frontend Authorization              │
│ Server-side Schema Validation       │
│ Normalization                       │
│ API Request Mapping                 │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│ Laravel                             │
│                                     │
│ Request Validation                  │
│ Authorization                       │
│ Application Use Case                │
│ Domain Invariant                    │
│ Transaction / Persistence           │
└─────────────────────────────────────┘
```

---

## 87. 責務境界

最終的な責務を以下とする。

```text id="f6p6ci"
Form Component
=
Input / Interaction / Form State

Frontend Schema
=
UX Validation / Parsing

Server Action
=
Trust Boundary / Validation / Normalization / API Call

OpenAPI Type
=
API Contract

Laravel Request Validation
=
Request Correctness

Laravel Domain
=
Business Correctness
```

---

## 88. 決定事項

FrontendのForm・Validationとして、以下を正式採用する。

- Form StateはFeature内部へ閉じ込める
- Form StateをGlobal Storeへ置かない
- Form LibraryはReact Hook Formを第一候補とする
- Schema Validation LibraryはZodを第一候補とする
- Feature固有Schemaは`features/<feature>/schemas/`へ配置する
- Frontend ValidationはUX / Input Assistanceを目的とする
- Frontend ValidationをSecurity Boundaryとは扱わない
- Laravel Request Validationを必須とする
- Business InvariantはLaravel Domainで最終保証する
- ValidationをFrontend Schema / Laravel Request / Laravel Domainの三層へ分離する
- UX上有益な単純RuleはFrontendへ意図的に重複してよい
- Laravel Domain RuleをFrontendへ完全再実装しない
- Form ModelとAPI Request DTOの分離を許可する
- Form DataをValidation / Normalization後にAPI DTOへ変換する
- Client ComponentとServer ActionでFrontend Schemaを共有してよい
- Client Validation済みでもServer Actionで必ず再Validationする
- Form SubmissionはServer Actionを第一候補とする
- Server ActionをTrust Boundaryとして扱う
- Server ActionをBusiness Logic Layerとは扱わない
- Edit Formの初期値はServer側で取得する
- Client Mount後の`useEffect`初期Fetchを標準としない
- API DTOとForm Modelに意味のある差分がある場合のみMapperを利用する
- Mapperを過剰に作らない
- `FormData`をUntrusted Inputとして扱う
- String / Number / Boolean / Empty String / Null / Undefinedを明示的にNormalizationする
- OpenAPIのOptional / Nullable Semanticsを維持する
- API Enum ValueとUI Labelを分離する
- API FormatとPresentation Formatを分離する
- Conditional UIをUX改善に利用する
- Conditional UIをDomain Invariantの代替とはしない
- Disabled / Hidden Fieldの値を信用しない
- Resource IDを含むClient InputをUntrustedとして扱う
- Field ErrorとForm-level Errorを分離する
- Laravel 422をField ErrorへMapping可能にする
- API Field NameとFrontend Field NameのMappingを明示する
- Backend Validation Messageの直接表示へ過度に依存しない
- Form Submit中のPending Stateを必要最小限に管理する
- Double SubmitをUIでも抑制する
- Mutation成功後は必要範囲のみRevalidateする
- Validation Failure時は不要なRevalidationを行わない
- Validation Error時の入力値を可能な限り維持する
- Sensitive Inputを不要に再表示・保存・Loggingしない
- SchemaからAPI Clientへ依存させない
- Async ValidationをFrontend Schemaへ安易に組み込まない
- Unique / Race ConditionはBackend / DBで最終保証する
- Delete / Disable等の破壊的操作ではConfirmation UIを利用する
- Form AccessibilityとFocus Managementを考慮する
- Browser Native Validationは補助として扱う
- API ErrorをValidation / Conflict / Authentication / Authorization / System Errorへ分類する
- Frontend Form SchemaとOpenAPI Schemaの責務を分離する
- Generated API TypeとFrontend Form Schemaを組み合わせる
- EmployeeSkillの重要RuleはFrontendでUX制御しLaravel Domainでも最終保証する

以上をFrontendのForm・Validation方針とする。
