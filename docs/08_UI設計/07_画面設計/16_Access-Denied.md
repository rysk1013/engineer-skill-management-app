# Access Denied

## 1. 目的

認証済みユーザーが、アクセス権限を持たない画面・機能・Resourceへアクセスした場合に表示する共通Access Denied画面とする。

利用者に「権限がないためアクセスできない」ことを明確に伝え、安全に利用可能な画面へ戻れる導線を提供する。

技術的な認可情報や内部実装情報は表示しない。

---

## 2. 対象ケース

本画面は、主に認証済みユーザーに対する403相当のAccess Deniedを扱う。

例:

```text
認証済み
    ↓
対象Resource / 機能への権限なし
    ↓
Access Denied
```

以下とは区別する。

```text
未認証
    ↓
Login / Authentication

Resourceが存在しない
    ↓
Not Found
```

---

## 3. Route

共通Routeとして以下を基本とする。

```text
/forbidden
```

Access Denied発生時の具体的なRedirect / Error Handling方式は、Frontend・BFF・Backendの既存認証認可設計を正とする。

---

## 4. 画面種別

本画面は共通状態画面として扱う。

特定Featureに依存しない。

対象例:

- Employee
- EmployeeSkill
- Skill
- Skill Category
- Access Control
- Dashboard
- その他認可対象機能

Featureごとに個別の403画面を作成しないことを基本とする。

---

## 5. 認証との区別

Access Deniedは「認証されているが権限がない」状態として扱う。

```text
Authentication
    ↓
成功
    ↓
Authorization
    ↓
拒否
    ↓
Access Denied
```

未認証状態では本画面を表示せず、既存Authentication Flowに従う。

---

## 6. Not Foundとの区別

Access DeniedとNot Foundは異なる状態として扱う。

```text
Resourceあり
権限なし
    ↓
Access Denied
```

```text
Resourceなし
    ↓
Not Found
```

ただし、Security上Resourceの存在を利用者へ開示しない方針が既存認可設計で採用されている場合は、その仕様を正とする。

UI設計側だけで403 / 404の使い分けを変更しない。

---

## 7. 基本構成

基本構造は以下とする。

```text
Access Denied Page
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

## 8. Title

利用者向けのTitleは以下を基本とする。

```text
アクセスできません
```

または、

```text
このページへのアクセス権限がありません
```

Application全体で統一した表現を採用する。

技術用語として `403 Forbidden` のみを表示する構成にはしない。

---

## 9. Description

Descriptionでは、権限不足によってアクセスできないことを簡潔に説明する。

例:

```text
このページを表示する権限がありません。
```

必要に応じて以下のような補足を加えてよい。

```text
利用可能な画面へ戻って操作を続けてください。
```

具体的なRole・Permission内部値を表示しない。

---

## 10. Status Code表示

`403` 等のStatus Codeを補助情報として表示してもよいが、必須としない。

表示する場合でも利用者向けMessageを主とする。

例:

```text
403

アクセスできません
```

Status Codeだけで状態を説明しない。

---

## 11. Icon

Access Denied状態を補助するIconを表示してよい。

Lucide Icon等の利用を候補とする。

例:

- Shield
- ShieldAlert
- Lock

Iconのみで意味を表現せず、Title・Descriptionを必ず併用する。

---

## 12. Action

利用者が安全に操作を続けられるActionを提供する。

主な候補:

```text
[ 戻る ]
[ ダッシュボードへ ]
```

現在のNavigation Contextや既存Routing方針に応じて、必要なActionのみ表示する。

---

## 13. 戻るAction

直前画面へ戻るActionを提供してよい。

例:

```text
[ 戻る ]
```

ただし、直前画面自体がアクセス不可である可能性や、ブラウザ履歴が存在しない可能性を考慮する。

そのため、戻るActionだけを唯一の復帰手段としない。

---

## 14. ダッシュボードAction

安全な復帰先としてDashboardへのActionを提供することを基本候補とする。

```text
[ ダッシュボードへ ]
```

遷移先:

```text
/
```

Dashboardへのアクセス可否についても既存認可設計を正とする。

Dashboardへアクセスできない場合は別の安全な復帰先を利用する。

---

## 15. Feature一覧への復帰

Access Deniedが特定Feature内で発生した場合でも、共通画面側でFeature固有の復帰先を複雑に判定することを必須としない。

例:

```text
Employee詳細へのアクセス拒否
    ↓
Access Denied
    ↓
Dashboard
```

または、既存Frontend側で安全な一覧Routeを判断できる場合はFeature一覧へ戻すことを検討してよい。

Phase 1では共通UIとしての責務を優先する。

---

## 16. App Shell

認証済みユーザー向けの共通画面であるため、基本的にはApp Shell内で表示することを候補とする。

```text
App Shell
├── Header
├── Sidebar
└── Main Content
    └── Access Denied
```

これにより利用可能なNavigationへ移動しやすくする。

ただし、認可状態によってNavigation自体を安全に構築できない場合は、最小Layoutを利用してよい。

---

## 17. App Shell利用時のNavigation

App Shellを表示する場合も、現在Userが利用できないNavigation ItemをAccess Denied画面上だけ特別に表示しない。

通常のPermission Based Navigation方針を維持する。

```text
User Permission
    ↓
利用可能Navigationのみ表示
```

Sidebar自体に新しい認可Ruleを追加しない。

---

## 18. Breadcrumb

Access Deniedは共通状態画面であるため、Breadcrumbは必須としない。

表示する場合は単純な構造とする。

例:

```text
Access Denied
```

アクセス拒否されたResource名をBreadcrumbへ表示するかどうかは、情報開示方針を考慮して決定する。

---

## 19. Resource情報

Access Denied画面では、アクセス拒否されたResourceの内部情報を過度に表示しない。

非推奨例:

```text
Employee ID: 12345
Permission: employee.update
Policy: EmployeePolicy::update
```

利用者向けUIへ内部Permission Name・Policy Class・Resource ID等をそのまま表示しない。

---

## 20. Role情報

Access Denied理由として現在UserのRoleや不足Permissionを詳細表示することを標準としない。

例:

```text
あなたは MANAGER のため employee.delete がありません。
```

のような内部認可構造を直接表示しない。

必要な場合は一般的な案内に留める。

---

## 21. 管理者への問い合わせ

運用上必要であれば、管理者への問い合わせを促す説明を追加してよい。

例:

```text
アクセスが必要な場合は、管理者へお問い合わせください。
```

ただし、MVPでは問い合わせ先・Support Workflowを本画面の必須機能としない。

---

## 22. Error詳細

以下の情報は通常UIへ表示しない。

- Exception Message
- Stack Trace
- Policy Class
- Permission Code
- Internal User ID
- Internal Resource ID
- Backend Endpoint
- Database情報
- Debug情報

これらはLogging / Monitoring側で扱う。

---

## 23. API Access Denied

Page Load時ではなく、画面操作中のAPI Requestで403が返る場合がある。

例:

```text
画面表示
    ↓
権限変更
    ↓
操作Request
    ↓
403
```

この場合、必ずしも即座に `/forbidden` へ遷移するとは限らない。

操作Contextに応じて、

- 現在画面上でOperation Errorを表示する
- 最新のPermission状態へUIを更新する
- Access Denied画面へ遷移する

等を使い分ける。

具体的な判断は `08_UI状態設計.md` を正とする。

---

## 24. Page Access Denied

Pageそのものを表示する権限がない場合は、Access Denied画面を利用する。

例:

```text
/access-control
        ↓
参照権限なし
        ↓
/forbidden
```

---

## 25. Action Access Denied

画面参照権限はあるが特定Actionのみ権限がない場合は、通常はActionを非表示または利用不可とする。

例:

```text
Skill一覧
├── 参照可能
└── 編集不可
        ↓
編集Actionを表示しない
```

Action単位の権限不足で毎回Access Denied画面へ遷移させない。

ただし、直接Request等によってBackendから403が返された場合は既存Error Handling方針に従う。

---

## 26. Permission変更によるAccess Denied

画面表示後にUserの権限が変更される可能性を考慮する。

```text
画面表示時
権限あり
    ↓
別操作で権限変更
    ↓
次Requestで403
```

Frontend上の古いPermission状態だけを根拠として処理を続行しない。

Backend Responseを正とする。

---

## 27. Browser Refresh

Access Denied状態でBrowser Refreshしても、安全に同等の状態を表示できる構成とする。

一時的なClient Stateだけに依存しない。

---

## 28. Direct Access

利用者がURLを直接入力して権限のないRouteへアクセスした場合も同じAccess Denied方針を適用する。

```text
Direct URL Access
        ↓
Authorization
        ↓
Denied
        ↓
Access Denied
```

NavigationからActionを隠すだけで認可を保証しない。

---

## 29. Loading

Authorization判定または必要Data取得中にAccess Deniedを早期表示しない。

判定完了前は適切なLoading状態を利用する。

```text
Loading
    ↓
Authorization Result
    ├── Allowed → Page
    └── Denied  → Access Denied
```

一瞬だけ本来アクセスできないContentを表示する状態を避ける。

---

## 30. UI状態

### 30.1 Default

Access Denied Messageと復帰Actionを表示する。

---

### 30.2 Navigation Available

App Shellおよび許可されたNavigationを表示可能な状態。

---

### 30.3 Minimal Layout

Navigationを安全に表示できない場合は最小LayoutでAccess Deniedを表示する。

---

## 31. Success / Mutation

本画面自体ではMutationを行わない。

そのため、Submit Loading・Validation Error等のForm Stateは持たない。

---

## 32. 利用する共通UI

### 32.1 shadcn/ui Component

利用候補:

- Button
- Alert
- Card

必要になったComponentのみ導入する。

### 32.2 Application共通Component

利用候補:

- AppShell
- PageHeader
- ErrorState

Access Denied専用Componentを作成する場合も、Feature固有ではなく共通UIとして扱う。

---

## 33. Component候補

概念上、以下を候補とする。

```text
AccessDeniedPage
└── AccessDeniedState
    ├── Icon
    ├── Title
    ├── Description
    └── Actions
```

既存 `ErrorState` で十分に表現できる場合は、専用Componentを過剰に作成しない。

---

## 34. Responsive

### 34.1 Desktop

Main Content中央付近へ状態Messageを配置する。

過度に横幅を広げない。

以下のResponsive例およびWireframeでは、安全な復帰先の代表例としてDashboard Actionを表示する。

実際に表示する復帰Actionは現在Userの認可状態および既存Routing方針に従い、Dashboardへアクセスできない場合は別の安全な復帰先を利用する。

例:

```text
Icon

アクセスできません

このページを表示する権限がありません。

[ 戻る ] [ ダッシュボードへ ]
```

---

### 34.2 Tablet

Desktopと同じ情報構造を維持する。

Viewport幅に応じてAction配置を調整する。

---

### 34.3 Mobile

Mobileでは1 Columnを基本とする。

例:

```text
[ Icon ]

アクセスできません

このページを表示する
権限がありません。

[ ダッシュボードへ ]
[ 戻る ]
```

Actionは必要に応じて縦配置する。

---

## 35. Accessibility

以下を基本とする。

- Page Titleを明確にする
- Access Denied状態をTextで説明する
- Iconだけで状態を表現しない
- Main HeadingをSemanticに設定する
- Actionに明確なAccessible Nameを設定する
- Keyboardのみで復帰Actionを操作可能にする
- Focus状態を視認可能にする
- ColorだけでError状態を表現しない
- 過度に刺激の強いError表現を使用しない
- Page遷移後にHeading等へ適切にFocusを移すことを検討する

---

## 36. Desktop Wireframe

```text
+------------------------------------------------------------------+
| Header                                                           |
+------------------+-----------------------------------------------+
| Sidebar          |                                               |
|                  |                                               |
|                  |                  [ Icon ]                     |
|                  |                                               |
|                  |             アクセスできません               |
|                  |                                               |
|                  |   このページを表示する権限がありません。     |
|                  |                                               |
|                  |       [ 戻る ] [ ダッシュボードへ ]          |
|                  |                                               |
+------------------+-----------------------------------------------+
```

---

## 37. Mobile Wireframe

```text
+----------------------------+
| Menu | App | User          |
+----------------------------+
|                            |
|          [ Icon ]          |
|                            |
| アクセスできません         |
|                            |
| このページを表示する       |
| 権限がありません。         |
|                            |
| [ ダッシュボードへ       ] |
| [ 戻る                   ] |
|                            |
+----------------------------+
```

---

## 38. Error Message例

基本候補:

```text
アクセスできません

このページを表示する権限がありません。
```

必要に応じた補足:

```text
アクセスが必要な場合は、管理者へお問い合わせください。
```

Application全体で文言を統一する。

---

## 39. 避ける表現

以下のような表現は避ける。

```text
Forbidden
```

だけを表示する。

```text
Permission denied: employee.update
```

のように内部Permissionを露出する。

```text
あなたには権限がありません。
```

だけで復帰手段を提供しない。

利用者が状態と次のActionを理解できる表現を優先する。

---

## 40. Security

本画面はSecurity Boundaryではない。

認可はBackendで必ず実施する。

```text
Frontend UI Control
    ↓
UX上の制御

Backend Authorization
    ↓
最終的な認可
```

Access Denied UIが存在することを理由に、Backend認可を省略しない。

---

## 41. Information Disclosure

Access Denied Responseによって、本来利用者が知る必要のないResource存在情報や内部認可構造を露出しない。

具体的な403 / 404使い分けは既存Security・Authorization設計を正とする。

---

## 42. Logging

Access Denied発生時のLogging・Monitoring要件は既存非機能要件・Backend設計を正とする。

UI側ではDebug情報を表示しない。

Phase 1ではLogging実装を定義しない。

---

## 43. MVPで扱わないもの

現時点では以下を本画面の必須機能としない。

- 権限申請Workflow
- Access Request Button
- 管理者への自動通知
- Support Ticket作成
- Permission詳細表示
- Role比較
- Debug情報表示
- Access Denied履歴
- Featureごとの個別403画面

必要性が明確になった場合に別途検討する。

---

## 44. APIとの関係

Backend APIから返される403等の認可Errorは、既存API共通エラー仕様を正とする。

Frontendでは既存Error ResponseをApplication向けUIへ変換する。

Backend内部Messageをそのまま利用者へ表示しない。

---

## 45. 本画面で定義しないもの

以下は既存仕様またはFrontend実装の責務とする。

- Backend Policyの具体実装
- Middleware構成
- Permission判定ロジック
- 403 Response Bodyの具体型
- Better Auth Session処理
- Backend認証処理
- Sanctum認証処理
- BFF Error変換実装
- Redirect実装
- Server / Client Component境界
- React Component分割
- Tailwind CSS Class
- Design Tokenの具体値
- Logging実装
- Monitoring実装

---

## 46. 関連ドキュメント

本画面設計は以下を前提とする。

- `01_UI設計方針.md`
- `02_画面一覧.md`
- `03_画面遷移.md`
- `04_共通レイアウト.md`
- `05_デザインシステム.md`
- `06_共通コンポーネント.md`
- `17_Not-Found.md`

Authentication / Authorization・Role・Permission・Access Controlについては、既存の要件定義・アーキテクチャ・システム設計・API共通仕様を正とする。

UI状態の共通方針は `08_UI状態設計.md`、Responsiveの共通方針は `09_レスポンシブ設計.md` で定義する。
