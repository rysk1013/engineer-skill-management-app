# データ取得・Server State

## 1. 目的

本ドキュメントでは、Engineer Skill Management AppのFrontendにおけるデータ取得およびServer State管理に利用する技術・Libraryと、その利用方針を管理する。

主に以下を対象とする。

- Server-side Data Fetching
- Client-side Data Fetching
- Server State
- Cache
- Mutation後のCache同期
- Loading
- Error

Frontend Architectureで定義したServer Firstの方針を前提とする。

API ClientおよびOpenAPIからの型・Client生成については `05_API-Client・OpenAPI.md` で管理する。

---

## 2. Server-side Data Fetching

### 2.1 基本方針

Server ComponentおよびNext.js Server側のデータ取得には、
Next.js / Reactで利用できる標準の `fetch` を基本とする。

追加のHTTP Client LibraryをServer-side Data Fetchingのためだけに導入しない。

基本構成は以下とする。

    Server Component
          ↓
        fetch
          ↓
      API Client
          ↓
      Laravel API

BrowserからLaravel APIを直接呼び出すことは原則として行わない。

---

### 2.2 Server First

データ取得はServer Firstを基本とする。

判断順序は以下とする。

    Dataが必要
        ↓
    Serverで取得可能か
        |
       Yes
        ↓
    Server Component

        |
       No
        ↓
    Client Component

Client-side Data FetchingをDefaultにしない。

---

### 2.3 `fetch` の採用理由

主な理由は以下とする。

- Web標準APIである
- Next.js / Reactと自然に統合できる
- 追加Dependencyが不要
- Server Componentから利用できる
- `Request` / `Response` APIとの整合性が高い
- Next.jsのCache / Revalidation機構と組み合わせられる
- API ClientのTransportとして利用しやすい

AxiosなどのHTTP Client Libraryは、
明確な追加要件がない限り導入しない。

---

## 3. Client-side Data Fetching

### 3.1 基本方針

Client ComponentでServer Stateを取得する必要がある場合は、
TanStack Queryを利用する。

基本構成は以下とする。

    Serverで取得可能
          ↓
    Server Component

    Client Interactionが必要
          ↓
    Client Component
          ↓
    TanStack Query

---

### 3.2 利用するケース

TanStack Queryは主に以下の場合に利用する。

- Client操作による再取得
- Search
- Filter
- Sort
- Pagination
- Mutation後の再取得
- Background Refetch
- Polling
- Client側でServer StateのCacheを共有する必要がある
- Optimistic Updateが必要

単純な初期表示データについては、
Server Componentで取得できないかを先に検討する。

---

### 3.3 `fetch + useEffect`

Client-side Server State取得の標準パターンとしては採用しない。

例えば、

    useEffect(() => {
      fetch(...)
        .then(...)
    }, [])

のような処理をApplication全体で繰り返さない。

この方式では、

- Loading
- Error
- Cache
- Retry
- Refetch
- Request重複
- Mutation後の同期

などをApplication側で個別に管理する必要がある。

Client-side Server StateについてはTanStack Queryへ責務を集約する。

---

## 4. Server State Library

### 4.1 候補

Server State Libraryとして以下を比較する。

- TanStack Query
- SWR
- React / Next.js標準機能のみ

---

### 4.2 採用

TanStack Queryを採用する。

Reactでは以下を利用する。

    @tanstack/react-query

---

### 4.3 採用理由

主な理由は以下とする。

- Server State管理に特化している
- Query Cacheを管理できる
- Loading / Error状態を統一的に扱える
- Refetchを制御できる
- Mutation後のCache更新を管理しやすい
- Query Invalidationを利用できる
- Paginationと組み合わせやすい
- Search / Filter画面と相性がよい
- Background Refetchを扱える
- Optimistic Updateへ拡張できる
- TypeScriptとの親和性が高い
- Server StateとClient Stateの責務を分離しやすい

本プロジェクトでは、

- Employee
- Skill
- EmployeeSkill
- Department

などの一覧・更新画面が存在し、

- Search
- Filter
- Pagination
- Mutation

を扱うため、Server State管理をApplication側で個別実装せずTanStack Queryへ集約する。

---

### 4.4 Stateの責務分離

TanStack QueryはServer Stateのみを管理する。

状態は以下のように分離する。

    Server State
         ↓
    TanStack Query

    Local UI State
         ↓
    React State

    URL State
         ↓
    URL / Search Params

    Form State
         ↓
    Form Library

TanStack Queryを汎用Global State Managerとして利用しない。

---

### 4.5 Query Key

Query KeyはApplication全体で一定のルールを持って管理する。

例えばEmployee関連では、

    employees

    employees / list

    employees / detail / {id}

のようにResource単位で整理する。

Query KeyをComponent内へ場当たり的に文字列で記述しない。

Query Key Factoryまたは共通定義を利用し、
同一ResourceでQuery Keyの形式が分散しないようにする。

---

### 4.6 Query Parameters

Search、Filter、Sort、Paginationなど、
取得結果へ影響する値はQuery Keyへ含める。

例えば、

    employeeList({
      page,
      keyword,
      departmentId,
      sort,
    })

のようなParameterをQuery Keyへ反映する。

同じQuery Keyで異なる条件のデータを保持しない。

---

### 4.7 SWR

SWRは採用しない。

SWRは軽量でシンプルなServer State Libraryであるが、
本プロジェクトでは、

- Mutation
- Query Invalidation
- Pagination
- Filter
- Search
- Server State Cache

などを体系的に管理する必要があるため、
TanStack Queryを採用する。

SWRとTanStack Queryを併用しない。

---

## 5. Cache

### 5.1 基本方針

CacheはServer側とClient側で責務を分離する。

    Server-side Cache
          ↓
       Next.js

    Client-side Cache
          ↓
     TanStack Query

ServerとClientで同一のCache機構を共有しようとしない。

---

### 5.2 Server-side Cache

Server ComponentおよびNext.js Server側のCacheには、
Next.js標準のCache機能を利用する。

追加のCache LibraryはMVPでは導入しない。

Cacheが不要なデータについては無理にCacheしない。

---

### 5.3 Cache Strategy

すべてのRequestをCacheする前提にしない。

データの性質に応じてCache Strategyを決定する。

基本的な考え方は以下とする。

    頻繁に変化するデータ
          ↓
    No Cache / Short Cache

    比較的変化しないデータ
          ↓
    Cacheを検討

社員情報や保有スキルなど、
更新後に利用者が最新状態を確認する必要があるデータについては、
長時間のCacheをDefaultにしない。

---

### 5.4 Cache Components

Next.jsのCache Componentsを利用する場合は、
Next.js標準のCache APIを利用する。

主に以下を利用する。

- `use cache`
- `cacheLife`
- `cacheTag`

Cacheの有効期間やInvalidation対象を明示する。

---

### 5.5 Master Data

以下のような更新頻度が比較的低いMaster Dataは、
Server-side Cacheの候補とする。

- Skill Category
- Skill Master
- Department Master

ただし、一律のCache期間を設定しない。

Resourceごとの更新頻度と整合性要件に応じて決定する。

---

### 5.6 Server Cache Invalidation

MutationによってServer Cacheが古くなる場合は、
Next.js標準のRevalidation機能を利用する。

主に以下を利用する。

- `updateTag`
- `revalidateTag`
- `revalidatePath`

Resource単位で制御可能な場合はTagによるInvalidationを優先する。

---

### 5.7 Client-side Cache

Client-side Server StateのCacheにはTanStack Queryを利用する。

    Client Component
          ↓
     TanStack Query
          ↓
      Query Cache
          ↓
      Backend API

TanStack QueryのCacheをLocal UI StateやForm Stateの保存場所として利用しない。

---

### 5.8 `staleTime`

TanStack Queryでは、
DataがFreshとみなされる期間を `staleTime` で管理する。

Resourceの性質に応じて設定する。

    Frequently Updated Data
          ↓
    Short staleTime

    Master Data
          ↓
    Longer staleTime

Application全体へ長い `staleTime` を一律設定しない。

---

### 5.9 `gcTime`

利用されなくなったQuery Cacheを保持する期間は `gcTime` で管理する。

役割を以下のように区別する。

    staleTime
        ↓
    Data Freshness

    gcTime
        ↓
    Unused Cache Lifetime

両者を混同しない。

---

### 5.10 Refetch

必要に応じて以下を制御する。

- Mount時のRefetch
- Window Focus時のRefetch
- Network再接続時のRefetch
- Manual Refetch

不要なNetwork Requestが増える場合は、
主に `staleTime` を調整する。

---

### 5.11 Cacheしない選択

CacheはPerformance改善の手段であり、
必ず利用するものではない。

以下の場合はCacheしないことを選択できる。

- 更新頻度が高い
- 常に最新状態が必要
- Performance Benefitが小さい
- Invalidationが複雑になる
- Userごとに内容が大きく異なる

CorrectnessとData Freshnessを優先し、
必要性が明確になった段階でCacheを追加・調整する。

---

## 6. Mutation後の再取得・更新

### 6.1 基本方針

Create、Update、DeleteなどのMutation後は、
変更されたServer StateとFrontend Cacheの整合性を維持する。

Client-sideではQuery InvalidationをDefaultとする。

基本フローは以下とする。

    User Action
         ↓
      Mutation
         ↓
    Backend API
         ↓
      Success
         ↓
    invalidateQueries
         ↓
       Refetch
         ↓
      Latest Data

---

### 6.2 Query Invalidation

Mutationによって古くなった可能性があるQueryは、
`invalidateQueries` を利用してInvalidationする。

更新対象だけでなく、
その変更によって影響を受ける一覧や関連Queryも対象とする。

Application全体のQueryを一括Invalidationすることは原則として避ける。

---

### 6.3 Create

Create成功後は、
作成されたResourceが含まれるList QueryをInvalidationする。

    Create
       ↓
    Success
       ↓
    List Invalidate
       ↓
    Refetch

---

### 6.4 Update

Update成功後は、
対象ResourceのDetailと変更内容が影響するList QueryをInvalidationする。

    Update
       ↓
    Success
       ↓
    +----------------+
    |                |
    v                v
    Detail         List
    |                |
    +-------+--------+
            ↓
        Invalidate

FilterやSort結果へ影響するFieldを変更した場合は、
関連List QueryもInvalidationする。

---

### 6.5 Delete

Delete成功後は、
対象Resourceを含むList QueryをInvalidationする。

必要に応じて対象Detail Queryも削除またはInvalidationする。

削除済みResourceのDetail画面に残らないようNavigationも適切に処理する。

---

### 6.6 Cacheの直接更新

Mutation ResponseだけでFrontend Cacheを正確に更新できる場合は、
`setQueryData` などによるCacheの直接更新を利用できる。

基本判断は以下とする。

    Simple / Reliable
          ↓
    invalidateQueries

    Responseだけで正確に更新可能
          ↓
      setQueryData

Cache Structureを複雑に同期する必要がある場合は、
Query Invalidationを優先する。

Cacheを直接更新する場合はImmutableに更新する。

---

### 6.7 Optimistic Update

Optimistic UpdateはDefaultでは採用しない。

UX上のメリットが明確で、
Rollbackが単純なUse Caseに限定して利用する。

候補としては、

- Toggle
- Favorite
- Simple Status Change

などがある。

社員情報や保有スキルなど、
複雑な業務データ更新ではDefaultとして利用しない。

複雑なBusiness RuleをFrontend側で再現して
Optimistic Stateを構築しない。

---

### 6.8 Server-side Mutation

Server-side MutationによってServer Cacheが古くなる場合は、
必要に応じてNext.jsのCacheもRevalidateする。

    Server-side Mutation
             ↓
        Backend API
             ↓
           Success
             ↓
      Next.js Cache
             ↓
        Revalidation

Client CacheとServer Cacheの両方が存在する場合は、
Mutation経路に応じて更新対象を明確にする。

---

### 6.9 Source of Truth

Frontend CacheをBusiness StateのSource of Truthにはしない。

最終的なBusiness StateはBackend APIが保持する。

    PostgreSQL
        ↓
      Laravel
        ↓
    Backend API
        ↓
    Frontend Cache

Frontend CacheはBackend Dataの一時的なRepresentationとして扱う。

---

## 7. Loading・Errorとの関係

### 7.1 基本方針

LoadingおよびErrorは、
Server-side Data FetchingとClient-side Data Fetchingで責務を分ける。

    Server-side
        ↓
      Next.js

    Client-side
        ↓
    TanStack Query

---

### 7.2 Server-side Loading

Server Componentでデータ取得する場合は、
Next.jsのLoading UIを利用する。

Route Segment単位で必要に応じて `loading.tsx` を配置する。

Server-side Data Fetching中の表示を管理するためだけに
Client Stateを追加しない。

---

### 7.3 Suspense

Server ComponentのStreamingが有効な画面では、
Suspense Boundaryを利用できる。

例えば、

    Page
      |
      +-- Header
      |
      +-- Suspense
              |
              +-- Employee List

のようにPageの一部をStreamingできる。

Suspense BoundaryはUX上意味のある単位で配置し、
細かく分割しすぎない。

---

### 7.4 Client-side Loading

TanStack Queryでは主に以下を利用する。

- `isPending`
- `isFetching`
- `status`
- `fetchStatus`

初回LoadingとBackground Refetchを区別する。

    isPending
        ↓
    Initial Loading

    isFetching
        ↓
    Fetching / Background Refetch

既存Dataが存在する場合、
Background Refetchのたびに画面全体をLoading UIへ戻さない。

---

### 7.5 Loading UI

基本的に以下のように使い分ける。

    Initial Loading
          ↓
    Skeleton / Loading UI

    Background Refetch
          ↓
    Existing Dataを維持
          +
    必要ならIndicator

    Mutation
          ↓
    操作対象付近でPending表示

Mutation中は必要に応じて対象操作をDisabledにし、
二重送信を防止する。

---

### 7.6 Server-side Error

Server ComponentまたはRoute Segmentで発生したErrorについては、
Next.jsの `error.tsx` を利用する。

必要に応じて、

- Error Message
- Retry
- Navigation

を提供する。

---

### 7.7 Not Found

Resourceが存在しない場合とSystem Errorは区別する。

例えばEmployee Detailで対象Employeeが存在しない場合は
Not Foundとして扱い、
Unexpected Errorと同じUIへまとめない。

---

### 7.8 Client-side Error

TanStack Queryで発生したErrorは、
主に以下を利用して処理する。

- `isError`
- `error`

Recover可能なQuery Errorは、
可能な限りQueryを利用しているFeatureに近い場所で表示する。

例えば、

    Employee List取得失敗
          ↓
    Employee List内でError表示
          +
        Retry

とする。

---

### 7.9 Error Boundaryとの使い分け

Query取得失敗をすべてApplication全体のError Boundaryへ送らない。

以下のようなErrorはError Boundaryで処理する。

- Render Error
- Unexpected Exception
- Pageを継続できないError

Recover可能なAPI ErrorはFeature単位で処理する。

---

### 7.10 Retry

Retry可能なErrorについては、
必要に応じてRetry UIを提供する。

Authentication ErrorやValidation Errorなど、
Retryしても解決しないErrorを無条件に自動Retryしない。

具体的なRetry条件はAPI Error設計と合わせて決定する。

---

### 7.11 Loading・Error・Empty State

以下を明確に区別する。

    Loading
      ↓
    Loading UI / Skeleton

    Error
      ↓
    Error UI

    Success + 0件
      ↓
    Empty State

0件をLoadingまたはErrorとして扱わない。

---

### 7.12 Accessibility

LoadingやErrorを視覚表現だけで伝えない。

必要に応じて、

- Accessible Text
- `aria-busy`
- Status Message
- Focus Management

を利用する。

Error発生時には、
利用者が次の操作を理解できるようにする。

---

## 8. 採用技術一覧

データ取得・Server Stateでは以下の技術を採用する。

| 分類 | 採用技術 | 主な責務 |
|---|---|---|
| Server-side Data Fetching | Next.js / React標準 `fetch` | Server Component / Server側からのデータ取得 |
| Client-side Data Fetching | TanStack Query | Client Componentからのデータ取得 |
| Server State | TanStack Query | Client-side Server State管理 |
| Server-side Cache | Next.js標準Cache | Server側のCache / Revalidation |
| Client-side Cache | TanStack Query Query Cache | Client側のServer State Cache |
| Mutation | TanStack Query Mutation | Client-side Mutation |
| Client Cache Invalidation | `invalidateQueries` | Mutation後のCache同期 |
| Server Cache Invalidation | Next.js標準Revalidation | Server-side Cache同期 |
| Server Loading / Error | Next.js標準機能 | Route / Server Component単位の状態表示 |
| Client Loading / Error | TanStack Query Query State | Client-side Query状態管理 |

追加のData Fetching LibraryやCache LibraryはMVPでは導入しない。

---

## 9. 決定事項

Frontendのデータ取得・Server Stateは以下を基本構成とする。

    Browser
       |
       v
    Next.js
       |
       +-----------------------------+
       |                             |
       v                             v
    Server Component            Client Component
       |                             |
       v                             v
    Next.js / React             TanStack Query
       |                             |
       |                       Query Cache
       |                             |
       +--------------+--------------+
                      |
                      v
                 API Client
                      |
                      v
                 Laravel API
                      |
                      v
                 PostgreSQL

データ取得はServer Firstを基本とする。

Server-side Data FetchingにはNext.js / React標準の `fetch` を利用する。

Client-side Data FetchingおよびServer State管理にはTanStack Queryを利用する。

Cacheは、

    Next.js
       ↓
    Server-side Cache

    TanStack Query
       ↓
    Client-side Cache

として責務を分離する。

Mutation成功後はQuery InvalidationをDefaultとする。

    Mutation
       ↓
    Success
       ↓
    invalidateQueries
       ↓
    Refetch

Cacheの直接更新はMutation Responseだけで正しい状態を安全に構築できる場合に利用する。

Optimistic UpdateはDefaultでは利用せず、
UX上のメリットが明確でRollbackが単純なUse Caseに限定する。

Loading / Errorについては、

    Server-side
        ↓
    Next.js標準機能

    Client-side
        ↓
    TanStack Query

として分離する。

SWRは採用しない。

`fetch + useEffect` をClient-side Server State管理の標準パターンにしない。

Axiosなどの追加HTTP Client Libraryは、
Server-side Data Fetchingのためだけには導入しない。

Frontend CacheをBusiness StateのSource of Truthとせず、
Laravel Backend APIを最終的なSource of Truthとする。

追加Libraryや複雑なCache Strategyは先行導入せず、
必要性が明確になった段階で追加・最適化する。
