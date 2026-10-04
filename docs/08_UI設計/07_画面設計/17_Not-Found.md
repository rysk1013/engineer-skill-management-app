# Not Found

## 1. 目的

存在しないRouteまたはResourceへアクセスした場合に表示する共通Not Found画面とする。

利用者に「対象が見つからない」ことを明確に伝え、安全に利用可能な画面へ戻れる導線を提供する。

技術的な内部情報や不要なResource情報は表示しない。

---

## 2. 対象ケース

本画面は主に404相当のNot Foundを扱う。

例:

```text
存在しないRoute
    ↓
Not Found
```

```text
存在しないResource
    ↓
Not Found
```

対象例:

- 存在しないEmployee
- 存在しないSkill
- 存在しないSkill Category
- 存在しないUser
- 存在しないFrontend Route

---

## 3. Access Deniedとの区別

Not FoundとAccess Deniedは異なる状態として扱う。

```text
Resourceなし
    ↓
Not Found
```

```text
Resourceあり
権限なし
    ↓
Access Denied
```

ただし、Security上Resourceの存在を利用者へ開示しない方針が既存認可設計で採用されている場合は、その仕様を正とする。

UI設計側だけで403 / 404の使い分けを変更しない。

---

## 4. Route

Not Found専用の固定Routeへ必ずRedirectする構成とはせず、Next.jsのNot Found機構を利用することを基本とする。

概念上:

```text
Unknown Route
    ↓
Next.js Not Found
```

```text
Resource Lookup
    ↓
Not Found Result
    ↓
Next.js Not Found
```

具体的な実装方式はFrontend実装設計を正とする。

---

## 5. 画面種別

本画面は共通状態画面として扱う。

特定Featureに依存しない。

Featureごとに独自の404画面を作成することを基本としない。

---

## 6. 基本構成

基本構造は以下とする。

```text
Not Found Page
│
├── Status / Icon
├── Title
├── Description
└── Actions
    ├── Back
    └── Dashboard
```

情報量を増やしすぎず、利用者が状態と次の操作を理解できる構成とする。

---

## 7. Title

利用者向けTitleは以下を基本とする。

```text
ページが見つかりません
```

Resource単位で扱う場合でも、共通UIでは過度にFeature固有の表現へ寄せない。

必要に応じて、

```text
対象が見つかりません
```

等を利用してよい。

Application全体で表現を統一する。

---

## 8. Description

Descriptionでは、対象が存在しない、または利用できない可能性があることを簡潔に伝える。

例:

```text
指定されたページは存在しないか、移動された可能性があります。
```

Resource Not Foundの場合:

```text
指定された情報が見つかりませんでした。
```

技術的なError Messageをそのまま表示しない。

---

## 9. Status Code表示

`404` を補助情報として表示してもよいが、必須としない。

表示する場合でも利用者向けMessageを主とする。

例:

```text
404

ページが見つかりません
```

Status Codeだけで状態を説明しない。

---

## 10. Icon

Not Found状態を補助するIconを表示してよい。

Lucide Icon等の利用を候補とする。

例:

- FileQuestion
- SearchX
- CircleHelp

Iconだけで状態を表現せず、Title・Descriptionを必ず併用する。

---

## 11. Action

利用者が安全に操作を続けられるActionを提供する。

主な候補:

```text
[ 戻る ]
[ ダッシュボードへ ]
```

必要なActionのみ表示する。

---

## 12. 戻るAction

直前画面へ戻るActionを提供してよい。

```text
[ 戻る ]
```

ただし、以下を考慮する。

- Browser Historyが存在しない
- 直前画面も無効なRouteである
- 直前Resourceも存在しない

そのため、戻るActionだけを唯一の復帰手段としない。

---

## 13. ダッシュボードAction

安全な復帰先としてDashboardへのActionを提供することを基本候補とする。

```text
[ ダッシュボードへ ]
```

遷移先:

```text
/
```

Dashboardへのアクセス可否については既存認可設計を正とする。

Dashboardへアクセスできない場合は、別の安全な復帰先を採用する。

---

## 14. Feature一覧への復帰

Resource Not Foundが特定Feature内で発生した場合、既存Contextから安全な一覧画面を判断できる場合はFeature一覧への導線を提供してよい。

例:

```text
/employees/[employeeId]
        ↓
Employee Not Found
        ↓
/employees
```

ただし、共通Not Found Component自体にFeature判定Logicを過剰に持たせない。

Feature固有の復帰先が必要な場合は上位Page / Routing Logicで指定する。

---

## 15. App Shell

認証後Application内で発生するNot Foundでは、App Shell内で表示することを基本候補とする。

```text
App Shell
├── Header
├── Sidebar
└── Main Content
    └── Not Found
```

これにより、利用可能なNavigationへ移動できる状態を維持する。

---

## 16. App Shellを利用しない場合

認証前Routeや、App Shellを安全に構築できない状態では最小Layoutを利用してよい。

```text
Minimal Layout
└── Not Found
```

Not Found画面のためだけに不必要な認証済みUIを強制しない。

---

## 17. Breadcrumb

Not Foundは共通状態画面であるためBreadcrumbは必須としない。

表示する場合は単純な構造とする。

例:

```text
Not Found
```

存在しないResource名をBreadcrumbへ残す必要はない。

---

## 18. Resource Name

Resource Not Foundの場合でも、URL Parameter等の内部値をそのまま表示しない。

非推奨:

```text
Employee 123456 was not found.
```

必要に応じて利用者が入力・選択した公開上問題のない名称を表示してもよいが、必須としない。

---

## 19. Resource ID

内部Resource IDをError Messageとして表示しない。

非推奨:

```text
Employee ID: 12345 が存在しません。
```

IDが利用者向け識別子として正式に利用される仕様である場合のみ、その仕様に従う。

---

## 20. Unknown Route

存在しないFrontend Routeへのアクセスでは共通Not Foundを表示する。

例:

```text
/unknown-page
    ↓
Not Found
```

Feature Routeへ誤ってRedirectしない。

---

## 21. Resource Not Found

存在しないResourceへアクセスした場合も共通Not Found方針を利用する。

例:

```text
/employees/[employeeId]
        ↓
Employee取得
        ↓
存在しない
        ↓
Not Found
```

```text
/access-control/[userId]/edit
        ↓
User取得
        ↓
存在しない
        ↓
Not Found
```

---

## 22. Dialog内Resource Not Found

一覧からDialogを開いた後、対象Resourceが削除等によって存在しなくなる場合がある。

例:

```text
SkillEditDialog
    ↓
Update Request
    ↓
404
```

この場合は必ずしもPage全体のNot Foundへ遷移するとは限らない。

候補:

- Dialogを閉じる
- 一覧を最新化する
- 対象が存在しないことをFeedbackする

例:

```text
対象のスキルが見つかりませんでした。
一覧を更新しました。
```

具体的な扱いは `08_UI状態設計.md` を正とする。

---

## 23. Page Resource Not Found

独立画面そのものがResourceに依存する場合は、Resource Not FoundによってPageを成立させられないため共通Not Foundを利用する。

対象例:

```text
/employees/[employeeId]
```

```text
/employees/[employeeId]/skills
```

```text
/access-control/[userId]/edit
```

---

## 24. Resource削除との競合

画面表示後に対象Resourceが別操作で削除された場合は、次回API Responseを正とする。

```text
Page表示時
Resourceあり
    ↓
別操作で削除
    ↓
次Request
    ↓
404
```

Frontend上の古いDataだけでResourceの存在を保証しない。

---

## 25. Authenticationとの関係

未認証状態で保護Routeへアクセスした場合は、Not Foundではなく既存Authentication Flowを正とする。

```text
未認証
    ↓
Authentication Flow
```

Not Foundを認証処理の代替として利用しない。

---

## 26. Authorizationとの関係

権限不足の場合は原則Access Deniedとして扱う。

ただし、Resourceの存在を秘匿するために404として扱う既存Security方針がある場合は、その仕様を優先する。

```text
Authorization / Security Design
    ↓
403 または 404
```

Frontend UIだけで使い分けを決定しない。

---

## 27. Loading

Resource取得完了前にNot Foundを表示しない。

```text
Loading
    ↓
Fetch Result
    ├── Found     → Page
    ├── Forbidden → Access Denied
    └── Not Found → Not Found
```

一瞬だけNot Foundが表示され、その後正常Contentへ切り替わる状態を避ける。

---

## 28. Browser Refresh

Not Found状態でBrowser Refreshしても、同等の状態を安全に表示できる構成とする。

一時的なClient Stateだけに依存しない。

---

## 29. Direct Access

利用者が存在しないRoute / Resource URLへ直接アクセスした場合も同じNot Found方針を適用する。

```text
Direct URL Access
    ↓
Route / Resource Resolution
    ↓
Not Found
```

---

## 30. UI状態

### 30.1 Default

Not Found Messageと復帰Actionを表示する。

---

### 30.2 App Shell

認証済みContextでApp Shellを利用可能な状態。

---

### 30.3 Minimal Layout

App Shellを利用しないRoute / Contextで最小Layoutを利用する状態。

---

## 31. Mutation

本画面自体ではMutationを行わない。

Submit Loading・Validation Error等のForm Stateは持たない。

---

## 32. Errorとの区別

Not Foundは一般的なAPI / Network Errorと区別する。

```text
404
    ↓
Not Found
```

```text
500 / Network Failure / Unexpected Error
    ↓
Error State
```

取得失敗を安易にNot Foundとして扱わない。

---

## 33. 利用する共通UI

### 33.1 shadcn/ui Component

利用候補:

- Button
- Alert
- Card

必要になったComponentのみ導入する。

### 33.2 Application共通Component

利用候補:

- AppShell
- PageHeader
- ErrorState

既存 `ErrorState` で十分表現できる場合は専用Componentを過剰に追加しない。

---

## 34. Component候補

概念上、以下を候補とする。

```text
NotFoundPage
└── NotFoundState
    ├── Icon
    ├── Title
    ├── Description
    └── Actions
```

Feature固有のDomain Logicは持たせない。

---

## 35. Responsive

### 35.1 Desktop

Main Content中央付近へ状態Messageを配置する。

過度に横幅を広げない。

以下のResponsive例およびWireframeでは、安全な復帰先の代表例としてDashboard Actionを表示する。

実際に表示する復帰Actionは現在Userの認可状態および既存Routing方針に従い、Dashboardへアクセスできない場合は別の安全な復帰先を利用する。

例:

```text
Icon

ページが見つかりません

指定されたページは存在しないか、
移動された可能性があります。

[ 戻る ] [ ダッシュボードへ ]
```

---

### 35.2 Tablet

Desktopと同じ情報構造を維持する。

Viewport幅に応じてAction配置を調整する。

---

### 35.3 Mobile

Mobileでは1 Columnを基本とする。

例:

```text
[ Icon ]

ページが見つかりません

指定されたページは
存在しないか、
移動された可能性があります。

[ ダッシュボードへ ]
[ 戻る ]
```

Actionは必要に応じて縦配置する。

---

## 36. Accessibility

以下を基本とする。

- Page Titleを明確にする
- Not Found状態をTextで説明する
- Iconだけで状態を表現しない
- Main HeadingをSemanticに設定する
- Actionに明確なAccessible Nameを設定する
- Keyboardのみで復帰Actionを操作可能にする
- Focus状態を視認可能にする
- Colorだけで状態を表現しない
- Page遷移後にHeading等へ適切にFocusを移すことを検討する

---

## 37. Desktop Wireframe

```text
+------------------------------------------------------------------+
| Header                                                           |
+------------------+-----------------------------------------------+
| Sidebar          |                                               |
|                  |                                               |
|                  |                  [ Icon ]                     |
|                  |                                               |
|                  |          ページが見つかりません              |
|                  |                                               |
|                  |   指定されたページは存在しないか、           |
|                  |   移動された可能性があります。               |
|                  |                                               |
|                  |       [ 戻る ] [ ダッシュボードへ ]          |
|                  |                                               |
+------------------+-----------------------------------------------+
```

---

## 38. Mobile Wireframe

```text
+----------------------------+
| Menu | App | User          |
+----------------------------+
|                            |
|          [ Icon ]          |
|                            |
| ページが見つかりません     |
|                            |
| 指定されたページは         |
| 存在しないか、             |
| 移動された可能性が         |
| あります。                 |
|                            |
| [ ダッシュボードへ       ] |
| [ 戻る                   ] |
|                            |
+----------------------------+
```

---

## 39. Error Message例

基本候補:

```text
ページが見つかりません

指定されたページは存在しないか、移動された可能性があります。
```

Resource向け候補:

```text
対象が見つかりません

指定された情報が存在しない可能性があります。
```

Application全体で必要以上に文言Variationを増やさない。

---

## 40. 避ける表現

以下のような表現は避ける。

```text
404
```

だけを表示する。

```text
ModelNotFoundException
```

のような内部Exceptionを表示する。

```text
User ID 12345 does not exist.
```

のように不要な内部情報を露出する。

復帰手段を提供しない。

---

## 41. Security

Not Found UIはSecurity Boundaryではない。

Resource存在確認・AuthorizationはBackendで適切に実施する。

```text
Frontend Not Found UI
    ↓
利用者向け表示

Backend
    ↓
Resource存在確認
Authorization
```

FrontendでRouteを隠すことをSecurity対策として扱わない。

---

## 42. Information Disclosure

404 Responseによって、本来利用者が知る必要のないResource情報を露出しない。

特にAccess Deniedとの使い分けは既存Security設計を正とする。

Resource存在の秘匿が必要な場合はBackend側のResponse方針に従う。

---

## 43. Logging

Not Found発生時のLogging・Monitoring要件は既存非機能要件・Backend / Frontend設計を正とする。

UI側ではDebug情報を表示しない。

通常の存在しないURLアクセスと、Application上異常なResource Not Foundを同一の重大Errorとして扱うかどうかはMonitoring設計に委ねる。

---

## 44. MVPで扱わないもの

現時点では以下を本画面の必須機能としない。

- Featureごとの個別404画面
- 検索機能
- Suggested Pages
- Recent Pages
- Resource Recovery Workflow
- 自動Redirect Countdown
- Support Ticket作成
- Debug情報表示
- Not Found履歴表示

必要性が明確になった場合に別途検討する。

---

## 45. Next.jsとの関係

FrontendではNext.js App RouterのNot Found機構を利用することを基本とする。

具体的な、

- `not-found` の配置
- Nested Route単位のNot Found
- `notFound()` 呼び出し
- Server Component / Client Component境界

はFrontend実装設計で決定する。

Phase 1ではUI上の責務と表示方針のみ定義する。

---

## 46. APIとの関係

Backend APIから返される404等のResource Not Found Errorは、既存API共通エラー仕様を正とする。

Frontendでは既存Error ResponseをNot Found UIまたは操作Context内のFeedbackへ適切に変換する。

Backend内部Messageをそのまま利用者へ表示しない。

---

## 47. 本画面で定義しないもの

以下は既存仕様またはFrontend実装の責務とする。

- Next.js `not-found` の具体Path
- `notFound()` の呼び出し位置
- Backend Resource Lookup実装
- 404 Response Bodyの具体型
- BFF Error変換実装
- Redirect実装
- Server / Client Component境界
- React Component分割
- Tailwind CSS Class
- Design Tokenの具体値
- Logging実装
- Monitoring実装

---

## 48. 関連ドキュメント

本画面設計は以下を前提とする。

- `01_UI設計方針.md`
- `02_画面一覧.md`
- `03_画面遷移.md`
- `04_共通レイアウト.md`
- `05_デザインシステム.md`
- `06_共通コンポーネント.md`
- `16_Access-Denied.md`

Resource Not Found・Authentication・Authorization・API Errorについては、既存の要件定義・アーキテクチャ・システム設計・API共通仕様・非機能要件を正とする。

UI状態の共通方針は `08_UI状態設計.md`、Responsiveの共通方針は `09_レスポンシブ設計.md` で定義する。
