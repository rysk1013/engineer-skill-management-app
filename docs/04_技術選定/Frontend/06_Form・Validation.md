# Form・Validation

## 1. 目的

本ドキュメントでは、FrontendにおけるForm管理およびValidationの技術選定と運用方針を定義する。

対象：

- Form State管理
- Form Library
- Schema Validation
- Client-side Validation
- Server-side Validation
- API Validation Errorとの連携
- Form StateとAPI Request Typeの境界
- Dynamic Form / Array Field
- Default Value / Edit Form
- Submission
- Accessibility

FormのUI Component設計については `03_UI・Styling.md`、
API Request / Error Contractについては `05_API-Client・OpenAPI.md` に従う。

---

# 2. 基本方針

Form State管理には **React Hook Form** を採用する。

Runtime Schema Validationには **Zod** を採用する。

React Hook FormとZodの連携には
**`@hookform/resolvers`** を利用する。

基本構成：

    User Input
        ↓
    React Hook Form
        ↓
    Zod Schema
        ↓
    Validated Form Data
        ↓
    Transform
        ↓
    Generated API Request Type
        ↓
    API Client
        ↓
    Laravel API

以下を基本原則とする。

- Form StateはReact Hook Formで管理する
- Validation SchemaはZodで定義する
- Form StateとAPI Request Typeを分離する
- Client ValidationとServer Validationを両方利用する
- Backend Validationを最終防衛線とする
- API Validation ErrorをFieldへMappingする
- Form ComponentへBusiness Logicを持たせすぎない
- Schemaの重複を必要以上に増やさない
- Validation MessageをUIから分離可能な構成にする
- AccessibilityをForm設計の一部として扱う

---

# 3. Form Library

## 3.1 採用

Form Libraryには **React Hook Form** を採用する。

主な責務：

- Form State
- Field Registration
- Validation State
- Error State
- Dirty State
- Touched State
- Submission State
- Default Value
- Dynamic Field
- Array Field

---

## 3.2 採用理由

React Hook Formを採用する主な理由：

- Reactとの親和性
- TypeScript対応
- Schema Validation Libraryとの統合
- Uncontrolled Componentを中心としたForm管理
- Form Stateの局所化
- Dynamic Formへの対応
- Field Arrayへの対応
- 大規模Formでも利用しやすい
- shadcn/uiとの組み合わせが容易

---

## 3.3 不採用候補

候補：

- Formik
- TanStack Form
- 手書きReact State

### Formik

成熟したLibraryではあるが、
新規ProjectではReact Hook Formを優先する。

### TanStack Form

型安全性や設計思想は魅力的であるが、
本ProjectではTanStack Query以外までTanStack Ecosystemへ
必要以上に統一する必要はない。

React Hook Formの成熟度・利用実績・UI Libraryとの統合性を優先する。

### 手書きReact State

小規模Formでは可能だが、

- Validation
- Dirty管理
- Error管理
- Submission State
- Dynamic Field

を個別実装する必要があるため、
標準方式にはしない。

---

# 4. Schema Validation Library

## 4.1 採用

Schema Validation Libraryには **Zod** を採用する。

Zod SchemaをRuntime Validationの
Source of Truthとして利用する。

ZodはTypeScript-firstのSchema Validation Libraryであり、
Runtime ValidationとStatic Type Inferenceを提供する。 citeturn266184search3turn266184search5

---

## 4.2 React Hook Formとの統合

`@hookform/resolvers/zod` を利用する。

概念：

    Zod Schema
        ↓
    zodResolver
        ↓
    React Hook Form

SchemaからFormの型を推論できる構成とする。 citeturn765834search0

---

## 4.3 Zodを採用する理由

主な理由：

- TypeScriptとの親和性
- Static Type Inference
- Runtime Validation
- React Hook Formとの成熟したIntegration
- Schema APIが理解しやすい
- Ecosystemが大きい
- Form以外のRuntime Validationにも利用可能
- Server / Client双方で利用可能
- Zod 4が安定版

---

## 4.4 Valibotとの比較

Valibotも有力候補である。

Valibotは、

- Type-safe
- Modular
- Runtime Validation
- Static Type Inference
- 小さいBundle Size

を特徴とする。公式ドキュメントでは、最小構成が非常に小さいことも特徴としている。 citeturn266184search2turn266184search4

ただし本Projectでは、

- React Hook Formとの一般的なIntegration
- Documentation
- Ecosystem
- Developer Experience
- 将来的な保守性
- 学習コスト

を総合してZodを採用する。

Bundle Sizeが明確な課題になった場合は
Valibotを再評価できる。

---

## 4.5 Schemaの責務

Zod Schemaは、

- Required
- String / Number
- Minimum / Maximum
- Format
- Range
- Cross-field Validation
- Form Input Transformation

など、
Frontendで検証可能なInput Ruleを担当する。

Backend Domain RuleすべてをZodへ複製しない。

---

# 5. Form StateとAPI Request Type

## 5.1 基本方針

Form StateとOpenAPI Generated Request Typeは
別の型として扱う。

    Form State
        ↓
    Validation
        ↓
    Transform
        ↓
    API Request Type

Form StateをAPI DTOそのものにしない。

---

## 5.2 分離する理由

HTML Form Inputでは、
APIが期待するData Typeと異なる状態が存在する。

例えば、

    experienceYears: ""

のような入力途中状態があり得る。

API側では、

    experienceYears: number

であっても、
Form StateではStringとして扱う場合がある。

---

## 5.3 Form Type

Form TypeはZod Schemaから推論する。

概念：

    const employeeSchema = ...

    type EmployeeFormValues =
        z.infer<typeof employeeSchema>

Form TypeをSchemaとは別に重複定義しない。

---

## 5.4 Request変換

Submit時にForm Stateを
Generated Request Typeへ変換する。

    EmployeeFormValues
          ↓
       Mapper
          ↓
    CreateEmployeeRequest

ただし単純なFormでは、
Dedicated Mapperを作らずSubmit Handler内の小さな変換でもよい。

---

## 5.5 Mapperを作るケース

以下の場合はForm Mapperを検討する。

- String → Number変換
- Empty String → null
- Date変換
- 複数Fieldから1 Request Fieldを生成
- API Enumへの変換
- Form専用Fieldを除外
- Nested Data変換

単純なPass-through Mapperを量産しない。

---

# 6. Client-side Validation

## 6.1 基本方針

Client-side Validationは
UX改善を目的として実施する。

主な対象：

- Required
- Length
- Format
- Number Range
- Date Range
- Cross-field Rule
- 入力形式

---

## 6.2 Client Validationの目的

Client Validationは、

- 早いFeedback
- 不要なAPI Request削減
- Input Errorの分かりやすい表示

を目的とする。

Security Boundaryとしては扱わない。

---

## 6.3 Validation Timing

DefaultではSubmit時を基本とする。

必要に応じて、

- Blur
- Change

でValidationする。

すべての入力を1文字ごとにValidationして
利用者へ過剰なError表示を行わない。

---

## 6.4 Cross-field Validation

複数Field間のRuleは
Zod Schemaで表現できる場合はSchemaへ配置する。

例えばEmployee Skillでは、

    WorkExperience = NONE
        ↓
    SkillLevel = Level1 only

    WorkExperience = EXPERIENCED
        ↓
    Experience >= 1 month
    Last Used required

といったForm上のValidationを実装できる。

ただしDomain Invariantそのものの最終保証は
Backend Domain Layerで行う。

---

# 7. Server-side Validation

## 7.1 基本方針

Laravel Backendでも必ずValidationを実施する。

Client-side Validationを通過したDataであっても
信頼しない。

    Browser
       ↓
    Client Validation
       ↓
    Laravel Validation
       ↓
    Application / Domain

---

## 7.2 Backendを最終防衛線とする

以下はBackendで必ず検証する。

- Required
- Type
- Range
- Authorization
- Resource existence
- Uniqueness
- Business Invariant
- Database Integrity

Frontend Validationのみで
Data Integrityを保証しない。

---

## 7.3 Validationの重複

一部RuleがFrontendとBackendで重複することは許容する。

例えば、

    name required

はFrontend / Backend双方でValidationする。

これは、

    Frontend
        → UX

    Backend
        → Integrity / Security

という異なる責務を持つためである。

---

## 7.4 Business Rule

重要なBusiness Ruleを
Frontend Validationだけへ実装しない。

Employee SkillのInvariantなどは
Backend Domain Layerを最終保証とする。

Frontend側では
利用者がErrorを事前に理解できる範囲で同じRuleを表現する。

---

# 8. API Validation Errorとの連携

## 8.1 基本方針

Laravel APIから返るField Validation Errorを、
React Hook FormのField ErrorへMappingする。

    Laravel API
        ↓
    Validation Error
        ↓
    ApiClientError
        ↓
    React Hook Form
        ↓
    Field Error

---

## 8.2 `422`

Input Validation Errorには
`422 Unprocessable Content` を利用する。

ResponseにはField単位のErrorを含める。

概念：

    {
      "code": "VALIDATION_ERROR",
      "errors": {
        "name": [...],
        "skillLevel": [...]
      }
    }

具体的なResponse Schemaは
API Error Contractに従う。

---

## 8.3 Field Error Mapping

API Field Errorは
React Hook Formの `setError` 等を利用して
該当Fieldへ反映する。

例えば、

    API
      ↓
    errors.name
      ↓
    Form name field

とする。

---

## 8.4 Global Error

特定Fieldへ紐付かないErrorは
Form-level Errorとして表示する。

例えば、

- Resource Conflict
- Permission変更競合
- Unexpected Server Error

などである。

Field Errorへ無理にMappingしない。

---

## 8.5 Error Source

Client Validation Errorと
Server Validation Errorを
利用者が意識する必要はない。

UIとして一貫したError Presentationを行う。

ただし内部実装ではError Sourceを区別できるようにする。

---

# 9. Field Error・Form Error

## 9.1 Field Error

Field固有Errorは
対象Inputの近くへ表示する。

例えば、

    [ Skill Level ]
    Level 5

    未経験の場合はLevel 1のみ選択できます

のようにする。

---

## 9.2 Form Error

Form全体に関係するErrorは、
Form上部またはAction付近へ表示する。

Field ErrorとGlobal Errorを
同じ場所へ大量にまとめない。

---

## 9.3 Error Message

Error Messageは、

- 何が問題か
- どう修正すればよいか

を理解できる内容にする。

内部Exception Messageを直接表示しない。

---

## 9.4 Error Message管理

Validation Messageを
Component内へ無秩序に埋め込まない。

Schemaまたは共通Message定義へ配置する。

ただし小規模なFeature固有Messageまで
過剰にCentralizeしない。

---

# 10. Dynamic Form・Array Field

## 10.1 Dynamic Field

条件によって表示Fieldが変わるFormでは、
React Hook Formを利用して状態を管理する。

例えば、

    Work Experience
       ├── None
       │     ↓
       │  Last Used非表示
       │
       └── Experienced
             ↓
          Experience Duration
          Last Used表示

とする。

---

## 10.2 Hidden Field

非表示になったFieldの値を
そのままAPIへ送らないよう注意する。

Condition変更時に、

- Reset
- Unregister
- Request変換時に除外

などを適切に行う。

---

## 10.3 Array Field

可変長Fieldが必要な場合は
React Hook FormのField Array機能を利用する。

手書きでArray IndexやState管理を構築しない。

---

## 10.4 過度なGeneric Form

すべてのFormを1つのGeneric Form Engineで
表現しようとしない。

Feature固有FormはFeature側で管理する。

再利用性が明確になった部分のみComponent化する。

---

# 11. Default Value・Edit Form

## 11.1 Create Form

Create Formでは
明示的なDefault Valueを定義する。

`undefined` とEmpty Stringを
場当たり的に混在させない。

---

## 11.2 Edit Form

Edit FormではAPI Responseを
Form Stateへ変換する。

    API Response
        ↓
    Form Default Values
        ↓
    React Hook Form

API Responseを直接FormへSpreadすることを
Defaultとしない。

---

## 11.3 Date

Date / Year-Monthなどは
Form Controlが要求する形式へ変換する。

例えば、

    API
    2026-09

       ↓

    Form
    "2026-09"

のようにBoundaryを明示する。

---

## 11.4 Reset

Edit対象が変わった場合などは、
React Hook FormのReset機能を利用して
Default Valueを更新する。

Stateを個別に書き換えない。

---

# 12. Submission

## 12.1 基本Flow

基本：

    User
      ↓
    Submit
      ↓
    Client Validation
      ↓
    Request Transform
      ↓
    Mutation
      ↓
    API
      ↓
    Success / Error

---

## 12.2 Double Submit

Submission中は、
同一Mutationの重複送信を防ぐ。

React Hook Form / TanStack Queryの
Pending Stateを利用する。

---

## 12.3 Pending State

Submit中は、

- Button Disabled
- Loading Indicator
- Processing Message

など、
利用者が処理中と認識できるUIを提供する。

---

## 12.4 Mutation

Client-side Form Submissionでは
TanStack Query Mutationを基本とする。

Generated Mutation Hookを利用できる場合は
Orval Generated Hookを利用する。

    React Hook Form
         ↓
    Generated Mutation Hook
         ↓
     TanStack Query
         ↓
       Next.js BFF

---

## 12.5 Success

Mutation成功後の、

- Cache Invalidation
- Navigation
- Toast
- Form Reset

はUse Caseごとに決定する。

Generated Mutation Hookへ
Application Workflowを埋め込まない。

---

## 12.6 Error

Mutation Errorは、

    Validation Error
        → Field / Form Error

    Business Conflict
        → Feature Error

    Unexpected Error
        → Generic Error UI

のように分類して扱う。

---

## 12.7 Server Action

Server Actionを利用するFormも許容する。

ただし同一Use Caseで、

- Server Action
- Client Mutation
- Route Handler

を理由なく混在させない。

Interaction要件に応じてBoundaryを選択する。

---

# 13. Accessibility

## 13.1 基本方針

Form Accessibilityを
追加対応ではなく基本要件として扱う。

---

## 13.2 Label

すべてのInputに
適切なLabelを関連付ける。

PlaceholderをLabel代わりにしない。

---

## 13.3 Error

Validation Errorは
該当FieldとProgrammatically関連付ける。

必要に応じて、

- `aria-invalid`
- `aria-describedby`

等を利用する。

---

## 13.4 Required

Required Fieldは
視覚的表示だけでなく
Semanticにも伝わる構成とする。

---

## 13.5 Focus

Submit時にValidation Errorが発生した場合は、
利用者が問題箇所へ移動しやすいFocus Behaviorを提供する。

---

## 13.6 Keyboard

すべてのForm操作を
Keyboardで実行できることを基本とする。

Custom Componentでも
Native Form Control相当の操作性を維持する。

---

## 13.7 Error Summary

長いFormなど、
複数Errorの把握が難しい場合は
Error Summaryの導入を検討する。

すべての小規模Formに必須とはしない。

---

# 14. 採用技術一覧

| 分類 | 採用技術 |
|---|---|
| Form State | React Hook Form |
| Schema Validation | Zod |
| RHF / Schema Integration | `@hookform/resolvers` |
| Form Type | Zod Schemaから推論 |
| API Request Type | OpenAPI / Orval Generated Type |
| Client Validation | React Hook Form + Zod |
| Server Validation | Laravel |
| API Validation Error | OpenAPI Error Contract |
| Server State / Mutation | TanStack Query |
| API Mutation Hook | Orval Generated Hook |
| Accessibility | Semantic HTML + shadcn/ui / Base UI + ARIA |

---

## 14.1 不採用

| 技術 / 方針 | 理由 |
|---|---|
| Formik | 新規ProjectではReact Hook Formを優先 |
| TanStack Form | 現時点ではReact Hook Formの成熟度・統合性を優先 |
| Valibot | 有力だがDX・Ecosystemを優先してZodを採用 |
| 手書きForm State | Error / Dirty / Submit管理等の重複実装を避ける |
| API Generated TypeをForm Stateに直接利用 | UI Input StateとAPI Contractの責務が異なる |
| Client Validationのみ | Integrity / Securityを保証できない |
| Backend Validationのみ | UXが低下する |
| Business RuleをFrontendのみで保証 | Backend Domainで最終保証する |
| Message文字列によるError判定 | Machine-readable Error Codeを利用する |

---

# 15. 決定事項

Form State管理には
**React Hook Form** を採用する。

Schema Validationには
**Zod** を採用する。

React Hook FormとZodの連携には
**`@hookform/resolvers`** を利用する。

基本構成：

    User Input
        ↓
    React Hook Form
        ↓
    Zod
        ↓
    Validated Form Values
        ↓
    Transform
        ↓
    Orval Generated Request Type
        ↓
    TanStack Query Mutation
        ↓
    Next.js BFF
        ↓
    Laravel API

以下をProject標準方針とする。

1. Form StateはReact Hook Formで管理する。
2. Runtime Form ValidationにはZodを利用する。
3. Form Typeは可能な限りZod Schemaから推論する。
4. Form StateとAPI Generated Request Typeを分離する。
5. Submit Boundaryで必要なData Transformationを行う。
6. 単純なFormに不要なMapperを作らない。
7. Client ValidationはUX改善を目的とする。
8. Laravel ValidationをData Integrityの最終防衛線とする。
9. 重要なDomain InvariantはBackend Domain Layerで保証する。
10. Frontendでも利用者へ早くFeedbackできるRuleはValidationする。
11. API Validation ErrorはReact Hook Form Field ErrorへMappingする。
12. Fieldに紐付かないErrorはForm-level Errorとして扱う。
13. API Error Message文字列からBusiness Logicを判定しない。
14. Dynamic Fieldの非表示値を意図せずAPIへ送信しない。
15. Array FieldにはReact Hook Formの標準機能を利用する。
16. Create / Edit FormでDefault Valueを明示する。
17. Edit FormではAPI ResponseからForm StateへのBoundaryを設ける。
18. Submission中のDouble Submitを防止する。
19. Client MutationにはTanStack Queryを基本として利用する。
20. Orval Generated Mutation Hookを利用可能な場合は活用する。
21. Mutation後のNavigation / Toast / Invalidation等はApplication側で管理する。
22. Server Action / Client Mutation / Route Handlerを理由なく混在させない。
23. Form Accessibilityを基本要件とする。
24. Label / Error Association / Keyboard / Focus Managementを考慮する。
25. Validation SchemaをAPI Contractの代わりにはしない。
26. OpenAPIはAPI Contract、ZodはFrontend Runtime Validationという責務を維持する。

以上を `Frontend/06_Form・Validation.md` の決定版とする。
