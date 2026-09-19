# Feedback・Error-UI

## 1. 目的

本ドキュメントでは、FrontendにおけるUser FeedbackおよびError UIの技術選定・表示方針を定義する。

対象：

- Toast
- Alert
- Inline Feedback
- Validation Error
- Confirmation Dialog
- Loading / Pending
- Empty / No Results
- Query Error
- Mutation Error
- Error Boundary
- HTTP Error
- Authentication / Authorization Error
- Conflict
- Rate Limit
- Unexpected Error
- Retry / Recovery
- Accessibility

Errorの分類・正規化については `05_API-Client・OpenAPI.md`、
Form Validationについては `06_Form・Validation.md`、
Server Stateについては `04_データ取得・Server-State.md`、
UI Componentについては `03_UI・Styling.md` に従う。

---

# 2. 基本方針

Feedbackの種類と影響範囲によって
表示方法を使い分ける。

すべてのSuccess / ErrorをToastへ集約しない。

基本：

    Field Error
        → Field Inline Error

    Form / Feature Error
        → Inline Alert

    Temporary Feedback
        → Toast

    Destructive Action Confirmation
        → Alert Dialog

    Loading
        → Skeleton / Pending UI

    Pageを成立させられないError
        → Error Page

    Render Error
        → Error Boundary

Feedback UIの責務：

    API / Application Error
            ↓
       Error Classification
            ↓
       UI Decision
            ↓
    +-----------------------+
    | Field Error           |
    | Inline Alert          |
    | Toast                 |
    | Dialog                |
    | Error Page            |
    | Error Boundary        |
    +-----------------------+

---

# 3. Feedback分類

Feedbackを以下に分類する。

| 種類 | 主なUI |
|---|---|
| Field Validation | Field Error |
| Form-level Error | Inline Alert |
| Operation Success | 必要な場合のみToast |
| Recoverable Error | Inline Alert / Toast |
| Confirmation | Alert Dialog |
| Loading | Skeleton / Spinner / Pending |
| Empty | Empty State |
| No Search Results | No Results State |
| Authentication Error | Authentication Flow |
| Authorization Error | 403 UI |
| Not Found | 404 UI |
| Conflict | Inline Alert / Dialog |
| Rate Limit | Inline Alert / Toast |
| Unexpected Page Error | Error Page |
| Render Error | Error Boundary |

Error Typeだけでなく、
**UserがどこでRecoveryできるか**を考慮してUIを決定する。

---

# 4. Toast / Notification

## 4.1 採用

Toast Libraryには **Sonner** を採用する。

shadcn/uiとのIntegrationを利用する。

---

## 4.2 用途

Toastは一時的なFeedbackに利用する。

例：

- 更新完了
- 無効化完了
- Copy完了
- Background Operation完了
- Page上に表示場所を持たない軽量Error

---

## 4.3 Success Toast

すべての成功操作にToastを表示しない。

例えば、

    保存
      ↓
    一覧へ戻る
      ↓
    更新済みDataが表示される

場合、
操作成功がUIから明確なら
Toastを省略できる。

---

## 4.4 Error Toast

Userがその場で対応する必要があるErrorを
Toastだけで伝えない。

例えばForm Validation Errorを

    toast.error("入力内容が正しくありません")

だけで終わらせない。

Field / Form上にErrorを表示する。

---

## 4.5 Toastの濫用防止

避ける：

- Page LoadごとのToast
- Validation Errorの大量Toast
- Background Refetch成功Toast
- Userが既に認識できるSuccess Toast
- 同一Errorの重複Toast

---

## 4.6 Toast Message

Toastは簡潔にする。

内部ExceptionやStack Traceを表示しない。

必要に応じてActionを持たせることはできるが、
複雑なRecovery FlowをToast内へ構築しない。

---

# 5. Alert・Inline Feedback

## 5.1 採用

Inline Feedbackには
**shadcn/ui Alert** を基本として利用する。

必要に応じてFeature固有UIを構築する。

---

## 5.2 用途

Inline Alertは、
Feedbackが特定のForm / Section / Featureに関連する場合に利用する。

例：

- Form全体Error
- Data取得失敗
- Permission不足
- Conflict
- Warning
- Feature固有Notice

---

## 5.3 Toastとの使い分け

基本：

    Contextが明確
        → Inline

    Temporary / Contextを持たない
        → Toast

UserがErrorを見ながら
Actionを修正する必要がある場合は
Inlineを優先する。

---

# 6. Validation Error

## 6.1 基本方針

Field Validation Errorは
対象Fieldの近くへ表示する。

構成：

    React Hook Form
        ↓
    Zod
        ↓
    Field Error

Backend：

    Laravel
        ↓
    422 Validation Error
        ↓
    ApiClientError
        ↓
    React Hook Form setError()
        ↓
    Field Error

---

## 6.2 Client Validation

Client-side Validationは
早期Feedbackのために利用する。

Security / Data Integrityの最終保証にはしない。

---

## 6.3 Server Validation

Backendから返されたField Errorは、
可能な限り対応するFieldへMappingする。

Global ErrorはForm上部等へ
Inline Alertとして表示する。

---

## 6.4 Error Summary

入力項目が多いFormでは
必要に応じてError Summaryを追加する。

ただし小規模Formへ
機械的に導入しない。

---

## 6.5 Focus

Submit失敗時は、
必要に応じて最初のInvalid FieldへFocusする。

Keyboard / Screen Reader利用者が
Error位置を把握できるようにする。

---

# 7. Confirmation Dialog

## 7.1 採用

破壊的操作の確認には
**shadcn/ui Alert Dialog** を利用する。

通常のModal UIには
**shadcn/ui Dialog** を利用する。

---

## 7.2 Alert Dialog対象

例：

- Employee削除
- Skill無効化
- Permission変更
- Assignment解除
- 元に戻せない操作

---

## 7.3 Confirmation濫用防止

すべての操作へConfirmationを追加しない。

簡単にUndoできる操作や
影響の小さい操作については
ConfirmationがUXを悪化させる可能性がある。

---

## 7.4 Dialog Message

Dialogでは、

- 何が起こるか
- 何が対象か
- 元に戻せるか

を明確にする。

避ける：

    本当によろしいですか？

だけの曖昧なMessage。

---

## 7.5 Destructive Action

Destructive Actionは
Visual上でも通常Actionと区別する。

ただしColorだけに依存して
危険性を表現しない。

---

# 8. Loading・Pending UI

## 8.1 基本方針

Loadingの範囲に応じてUIを変える。

    Page Loading
        → loading.tsx / Suspense

    Section Loading
        → Skeleton

    Query Initial Loading
        → Skeleton / Loading State

    Background Refetch
        → Existing Data + Subtle Indicator

    Mutation
        → Action-local Pending State

---

## 8.2 Skeleton

Skeletonには
shadcn/ui Skeletonを利用する。

実際のContent Layoutに近い形を基本とする。

---

## 8.3 Spinner

短時間の局所的な処理では
Spinner等を利用できる。

Page全体をSpinnerだけで覆う方式を
Defaultとしない。

---

## 8.4 Mutation Pending

Mutation実行中は、

- Button disabled
- Pending表示
- Duplicate Submit防止

を行う。

Page全体を操作不能にする必要がなければ
Action周辺だけをPendingにする。

---

## 8.5 Background Refetch

TanStack QueryのBackground Refetchでは
既存Dataを可能な限り維持する。

毎回Skeletonへ戻さない。

---

# 9. Empty・No Results UI

## 9.1 Empty State

Data自体が存在しない場合は
専用Empty Stateを表示する。

例：

    スキルがまだ登録されていません

必要に応じて
次のActionを提供する。

---

## 9.2 No Results

Search / Filter結果が0件の場合は
Empty Stateと区別する。

例：

    条件に一致する社員が見つかりません

必要に応じて、

- Filter解除
- Search条件Clear

を提供する。

---

## 9.3 Errorとの区別

Dataが0件であることを
Errorとして扱わない。

    Empty
    No Results
    Error

を別Stateとして扱う。

---

# 10. Query・Mutation Error

## 10.1 基本方針

TanStack Queryから受け取ったErrorは、
`ApiClientError` の分類を利用してUIへ変換する。

概念：

    API Error
       ↓
    ApiClientError
       ↓
    TanStack Query
       ↓
    Error UI

---

## 10.2 Query Error

Feature内でRecovery可能なQuery Errorは
Feature近辺へInline表示する。

例：

    社員一覧の取得に失敗しました
    [再試行]

Page全体が成立しない場合は
Page-level ErrorへEscalateする。

---

## 10.3 Mutation Error

Mutation Errorは
操作対象に近い場所でFeedbackする。

例えば：

    Form Mutation
        → Form Alert / Field Error

    Simple Action
        → Inline / Toast

    Conflict
        → Conflict UI

---

## 10.4 Errorの二重表示

同じErrorを、

    Inline Alert
    +
    Toast
    +
    Error Page

へ同時に表示しない。

Error Ownershipを明確にする。

---

# 11. Error Boundary

## 11.1 採用

Next.js App Routerの
Error Handling機構を利用する。

主に：

- `error.tsx`
- `global-error.tsx`

を利用する。

---

## 11.2 error.tsx

Route Segment単位で
予期しないRender Errorを処理する。

可能な限り
Application全体ではなく
影響範囲を限定する。

---

## 11.3 global-error.tsx

Root Layoutまで含めて
Application全体をRenderできないErrorに利用する。

通常Errorをすべて
`global-error.tsx` へ送らない。

---

## 11.4 Expected Error

Expected Application Errorを
Error Boundaryへ投げる設計をDefaultとしない。

例えば、

- Validation
- 403
- 404
- Conflict

などは可能な限り
明示的に処理する。

---

# 12. HTTP Error Page

HTTP / Application Errorは
意味に応じたUIへMappingする。

基本：

    401
      → Authentication Flow

    403
      → Forbidden UI

    404
      → Not Found UI

    409
      → Conflict UI

    429
      → Rate Limit UI

    5xx
      → Unexpected Error UI

Status Codeだけでなく、
`ApiClientError` のError Type / Application Error Codeを利用する。

---

# 13. 401・Authentication Error

## 13.1 基本方針

401はAuthentication Errorとして扱う。

単なるToastだけで終了しない。

---

## 13.2 Session

Auth.js Sessionが失効している場合は
Authentication Flowへ誘導する。

具体的なSession Handlingは
`05_認証方式.md` に従う。

---

## 13.3 Credential

Laravel CredentialをBrowser側で
独自にRefresh / Restoreしない。

BFF / Authentication Architectureに従う。

---

# 14. 403・Authorization Error

## 14.1 基本方針

403はAuthentication Errorと区別する。

    401
        → Who are you?

    403
        → You are authenticated but not allowed.

---

## 14.2 UI

Page全体へのAccessが拒否された場合は
403相当のPage UIを表示する。

Feature内のActionだけが拒否された場合は
Feature近辺でErrorを表示できる。

---

## 14.3 Security

FrontendでActionを非表示にしていても、
Backend Authorizationを必須とする。

403が返る可能性をFrontendでも考慮する。

---

# 15. 404・Not Found

## 15.1 採用

Next.js App Routerの

- `notFound()`
- `not-found.tsx`

を利用する。

---

## 15.2 用途

例えば、

    /employees/123

でEmployee 123が存在しない場合に利用する。

---

## 15.3 Emptyとの違い

404とEmpty Stateを混同しない。

    Resource自体が存在しない
        → 404

    Resourceは存在するがChild Dataが0件
        → Empty State

---

# 16. 409・Conflict

## 16.1 基本方針

409 Conflictは
Userが状況を理解してRecoveryできるUIを優先する。

---

## 16.2 想定例

本Projectでは例えば、

- Duplicate Registration
- Concurrent Update
- Permission Invariant
- Current Stateとの矛盾

などが考えられる。

---

## 16.3 UI

Conflictの内容に応じて、

- Inline Alert
- Dialog
- Refetch
- Retry
- User Actionのやり直し

を提供する。

単に、

    エラーが発生しました

へ変換しない。

---

## 16.4 Backend Message

BackendのApplication Error Codeを利用して
Frontend Messageを決定できる。

Message Stringの解析で
処理を分岐しない。

---

# 17. 429・Rate Limit

## 17.1 基本方針

429はRate Limit Errorとして明示的に扱う。

---

## 17.2 Retry

`Retry-After` が提供される場合は
それを考慮する。

無制限な自動Retryを行わない。

---

## 17.3 UI

Userへ、

- 一時的にRequestが制限されていること
- 少し待って再試行できること

を伝える。

内部Rate Limit値を
不必要に公開しない。

---

# 18. 5xx・Unexpected Error

## 18.1 基本方針

Unexpected Errorでは
内部情報をUserへ公開しない。

避ける：

- Stack Trace
- SQL
- Internal Exception Class
- Internal Path
- Credential
- Debug Information

---

## 18.2 User Message

Userには、

- 処理に失敗したこと
- Retry可能か
- Supportへ伝える情報

を必要に応じて表示する。

---

## 18.3 Development

Development Environmentでは
Developer Experienceのために
詳細情報を確認できる構成としてよい。

Production UIへそのまま露出させない。

---

# 19. Retry・Recovery

## 19.1 基本方針

Error UIでは可能な限り
次のActionを提示する。

例：

    再試行

    一覧へ戻る

    条件を解除する

    再読み込みする

    ログインする

---

## 19.2 Automatic Retry

すべてのErrorを自動Retryしない。

特に以下は原則として
同じRequestの無条件Retry対象にしない。

- 400
- 401
- 403
- 404
- 409
- 422

---

## 19.3 Query Retry

Network Errorや一時的なServer Errorについては
TanStack QueryのRetryを利用できる。

Retry Policyは
API特性とError Typeを考慮して決定する。

---

## 19.4 Mutation Retry

Mutationの自動Retryは慎重に扱う。

Non-idempotent Operationを
無条件に自動Retryしない。

---

# 20. Error Message・Observability

## 20.1 Error Message

User向けMessageと
Developer / Operator向け情報を分離する。

    User
      → 理解・Recoveryに必要な情報

    Developer / Operator
      → Technical Context

---

## 20.2 Request ID

Backend / Infrastructureから
Request ID / Trace IDが提供される場合は、
Support用途で表示できる。

例：

    問題が解決しない場合は、
    問い合わせ時に次のIDをお知らせください。

    Request ID: ...

常に大きく表示する必要はない。

---

## 20.3 Logging

FrontendでErrorを記録する場合も
Sensitive Dataを含めない。

特に、

- Password
- Token
- Session
- Credential
- Sensitive Form Data

をError Loggingへ含めない。

---

## 20.4 Error Code

Application Error Codeを
Technical Identificationとして利用できる。

User Messageの文言を
Program LogicのIdentifierとして利用しない。

---

# 21. Accessibility

## 21.1 基本方針

FeedbackをVisual表現だけに依存させない。

---

## 21.2 Validation

Field Errorでは、

- Label
- `aria-invalid`
- `aria-describedby`

等を適切に利用する。

---

## 21.3 Toast

Toastだけが
重要情報を伝える唯一の手段にならないよう注意する。

重要なErrorは
Context内にも残す。

---

## 21.4 Dialog

Alert Dialogでは、

- Focus Management
- Keyboard Operation
- Accessible Name
- Description

を適切に設定する。

Base UI / shadcn/uiのAccessibility機構を活用する。

---

## 21.5 Loading

Loading / Updating状態は
必要に応じて、

- `aria-busy`
- Status Message

等で通知する。

---

## 21.6 Color

Success / Warning / Errorを
Colorだけで区別しない。

Icon / Text / Label等を組み合わせる。

---

## 21.7 Focus Recovery

Dialog CloseやError Recovery後は、
必要に応じて適切なElementへFocusを戻す。

---

# 22. 採用技術一覧

| 分類 | 採用技術 / 方針 |
|---|---|
| Toast | Sonner |
| Alert | shadcn/ui Alert |
| Confirmation | shadcn/ui Alert Dialog |
| General Dialog | shadcn/ui Dialog |
| Loading | Next.js `loading.tsx` / Suspense |
| Skeleton | shadcn/ui Skeleton |
| Query State | TanStack Query |
| Form Error | React Hook Form |
| Client Validation | Zod |
| API Error | `ApiClientError` |
| Route Error | Next.js `error.tsx` |
| Global Error | Next.js `global-error.tsx` |
| Not Found | `notFound()` / `not-found.tsx` |
| 403 | Dedicated Forbidden UI |
| Conflict | Inline Alert / Recovery UI |
| Rate Limit | Explicit 429 Feedback |
| Unexpected Error | Error Boundary / Error Page |
| Error Identification | Application Error Code / Request ID |
| Accessibility | Semantic HTML + ARIA + shadcn/ui / Base UI |

---

## 22.1 不採用・非推奨

| 技術 / 方針 | 理由 |
|---|---|
| 複数Toast Library | UI / APIが分散する |
| すべてSuccess Toast | Feedbackが過剰になる |
| すべてError Toast | Context / Recovery情報を失う |
| Validation ErrorのToastのみ | Fieldとの関連が分からない |
| すべてError Boundaryへ送る | Expected ErrorまでUnexpected扱いになる |
| 401と403の同一処理 | Authentication / Authorizationの意味が異なる |
| 404をEmpty State扱い | Resource Not FoundとData 0件は異なる |
| 409をGeneric Error化 | UserがRecoveryできなくなる |
| Mutationの無条件Auto Retry | Duplicate Operationの危険 |
| Message StringによるError判定 | Contractとして不安定 |
| Stack TraceのProduction表示 | Security / UX上不適切 |
| ErrorのInline + Toast二重表示 | Noise / Responsibility重複 |
| Confirmationの全操作適用 | UXを悪化させる |
| ColorのみのError表現 | Accessibility上不十分 |

---

# 23. 決定事項

Feedback / Error UIは、
**Error Typeと影響範囲、Recovery方法によって表示方法を選択する。**

基本構成：

    API / Application
           ↓
      ApiClientError
           ↓
    TanStack Query / Form / Route
           ↓
       Error Ownership
           ↓
    +------------------------+
    | Field Error            |
    | Inline Alert           |
    | Toast                  |
    | Dialog                 |
    | Error Page             |
    | Error Boundary         |
    +------------------------+

以下をProject標準方針とする。

1. ToastにはSonnerを採用する。
2. Toast Libraryを複数併用しない。
3. Inline Alertにはshadcn/ui Alertを利用する。
4. Confirmationにはshadcn/ui Alert Dialogを利用する。
5. 通常Modalにはshadcn/ui Dialogを利用する。
6. Skeletonにはshadcn/ui Skeletonを利用する。
7. すべてのSuccessにToastを表示しない。
8. 操作結果がUIから明白な場合はSuccess Toastを省略できる。
9. Validation ErrorをToastだけで表示しない。
10. Field ErrorはField付近へ表示する。
11. Backend 422 Errorは可能な限りReact Hook FormへMappingする。
12. Form-level ErrorはInline Alertを基本とする。
13. UserがContextを見ながらRecoveryするErrorではInline表示を優先する。
14. Destructive Actionのみ必要に応じてConfirmationを利用する。
15. Confirmation Dialogでは操作対象と結果を明示する。
16. Loading UIは影響範囲に合わせる。
17. Page LoadingにはNext.js `loading.tsx` / Suspenseを利用する。
18. Mutation PendingはAction周辺へ表示する。
19. Background Refetchでは可能な限り既存Dataを維持する。
20. Empty / No Results / Errorを異なるStateとして扱う。
21. Query / Mutation Errorは `ApiClientError` を基準に分類する。
22. 同じErrorをInline / Toast / Error Pageへ重複表示しない。
23. Error Ownershipを明確にする。
24. Unexpected Render ErrorにはNext.js `error.tsx` を利用する。
25. Application全体をRenderできないErrorには `global-error.tsx` を利用する。
26. Expected Errorを機械的にError Boundaryへ送らない。
27. 401はAuthentication Errorとして扱う。
28. 403はAuthorization Errorとして401と区別する。
29. 404には `notFound()` / `not-found.tsx` を利用する。
30. Resource Not FoundとEmpty Stateを区別する。
31. 409 ConflictをGeneric Errorへ潰さない。
32. Conflictでは可能な限りRecovery方法を提示する。
33. 429を明示的に扱い、`Retry-After` がある場合は考慮する。
34. 5xx / Unexpected Errorで内部情報をUserへ公開しない。
35. Error UIでは可能な限り次のActionを提示する。
36. Client Errorを無条件にAuto Retryしない。
37. Network / Temporary Server ErrorのみRetry候補とする。
38. Mutationの無条件Auto Retryを行わない。
39. User MessageとTechnical Informationを分離する。
40. Message StringをProgram Logicの判定に利用しない。
41. Application Error CodeをError識別に利用できる。
42. Request ID / Trace IDをSupport用途に利用できる。
43. Sensitive DataをError Loggingへ含めない。
44. FeedbackをColorだけで表現しない。
45. Important Errorを一時的なToastだけに依存させない。
46. Form Errorでは適切なARIA属性とFocus Managementを行う。
47. DialogではKeyboard / Focus Managementを保証する。
48. Error Recovery後のFocusも必要に応じて管理する。

以上を `Frontend/10_Feedback・Error-UI.md` の決定版とする。
