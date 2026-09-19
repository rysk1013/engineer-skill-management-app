# Frontend 基本技術・Runtime

## 1. 目的

本ドキュメントでは、Engineer Skill Management AppのFrontendおよびBFFで利用する基本技術・Runtimeを定義する。

対象は以下とする。

- Node.js
- TypeScript
- React
- Next.js
- Package Manager

個別のUI Library、状態管理、Form、API Clientなどについては、Frontend技術選定の各ドキュメントで管理する。

---

## 2. 採用技術

FrontendおよびBFFの基本技術として以下を採用する。

| 分類 | 採用技術 |
| --- | --- |
| Runtime | Node.js 24 LTS |
| Language | TypeScript |
| UI Library | React 19 |
| Framework | Next.js |
| Router | App Router |
| Package Manager | pnpm |
| BFF | Next.js |

FrontendとBFFは別Applicationには分割せず、1つのNext.js Applicationとして構成する。

---

## 3. Node.js

### 3.1 採用

Next.jsのRuntimeとしてNode.jsを採用する。

    Runtime
        ↓
    Node.js 24 LTS

LTS系列を利用し、Current系列は原則として採用しない。

---

### 3.2 採用理由

主な理由は以下とする。

- Next.jsの主要なRuntimeとして利用できる
- TypeScript / React / Next.js Ecosystemとの親和性が高い
- 開発環境、CI、Dockerで統一しやすい
- LTSによる安定した運用が可能
- Package Ecosystemが成熟している

---

### 3.3 Version方針

Node.jsはLTS系列を利用する。

本プロジェクトではNode.js 24 LTSを基本とする。

Patch Versionは本ドキュメントでは固定せず、実際のVersionはリポジトリ側で管理する。

ローカル開発環境、Docker、CIでは可能な限り同一Versionを利用する。

    Local
      │
      ├── Node.js 24.x
      │
    Docker
      │
      ├── Node.js 24.x
      │
    CI
      │
      └── Node.js 24.x

環境ごとに異なるNode.js Major Versionを利用しない。

---

## 4. TypeScript

### 4.1 採用

FrontendおよびBFFの実装言語としてTypeScriptを採用する。

JavaScriptによるApplication Codeは原則として作成しない。

---

### 4.2 採用理由

主な理由は以下とする。

- Compile時に型の不整合を検出できる
- React / Next.jsとの親和性が高い
- IDE / Editorによる補完を活用できる
- Refactoringを安全に行いやすい
- OpenAPIから生成した型を利用できる
- FrontendとBackend API間の型安全性を高められる

---

### 4.3 TypeScript設定

TypeScriptでは `strict` を有効にすることを基本とする。

    {
      "compilerOptions": {
        "strict": true
      }
    }

具体的な `tsconfig.json` の設定はFrontend Architectureおよび実装時に決定する。

以下を基本方針とする。

- `strict` を有効にする
- `any` の安易な利用を避ける
- 不要なType Assertionを避ける
- `unknown` を適切に利用する
- API型を手動で重複定義しない
- 型だけでRuntime Validationを代替しない

---

### 4.4 Version方針

TypeScriptのVersionはNext.jsとの互換性を確認した上で決定する。

本ドキュメントでは特定のPatch Versionを固定しない。

実際のVersionは `package.json` および `pnpm-lock.yaml` で管理する。

---

## 5. React

### 5.1 採用

UI LibraryとしてReactを採用する。

    React 19

Next.jsと組み合わせて利用する。

---

### 5.2 採用理由

主な理由は以下とする。

- Next.jsのUI基盤である
- ComponentベースでUIを構築できる
- TypeScriptとの親和性が高い
- Ecosystemが充実している
- Server Componentsを利用できる
- Next.js App Routerと組み合わせてServer Firstな構成を実現できる

---

### 5.3 Component方針

Function Componentを利用する。

Class Componentは原則として新規作成しない。

Next.js App RouterではServer Componentsを基本とする。

    Server Component
        ↓
    Default

    Client Component
        ↓
    必要な場合のみ

Client Componentは以下のような場合に利用する。

- ユーザー操作を伴うInteractive UI
- Browser APIを利用する
- Local Stateを持つ
- Client側のHookを利用する
- Client側でのみ動作するLibraryを利用する

不要な `"use client"` を避ける。

詳細なServer / Client境界についてはFrontend Architectureで管理する。

---

### 5.4 Version方針

React 19系列を利用する。

ただし、ReactのVersionをNext.jsから独立して追従することは原則として行わない。

採用するNext.jsが正式にサポートするReact Versionを利用する。

Patch Versionは `package.json` および `pnpm-lock.yaml` で管理する。

---

## 6. Next.js

### 6.1 採用

Frontend FrameworkとしてNext.jsを採用する。

Next.jsは以下の2つの責務を持つ。

    Next.js
    ├── Frontend
    └── BFF

FrontendとBFFを1つのNext.js Applicationとして構成する。

---

### 6.2 App Router

RoutingにはApp Routerを採用する。

Pages Routerは利用しない。

基本構成は以下とする。

    app/
    ├── layout.tsx
    ├── page.tsx
    ├── ...
    └── api/
        └── ...

App Routerを前提としてFrontend Architectureを構成する。

---

### 6.3 採用理由

主な理由は以下とする。

- Reactとの統合性が高い
- Server Componentsを利用できる
- App Routerを利用できる
- Server-side Renderingを利用できる
- Route HandlersをBFFとして利用できる
- Server Actionsを利用できる
- FrontendとBFFを同一Application内で構成できる
- TypeScriptを標準的に利用できる
- Cache / RevalidationなどのFramework機能を利用できる

---

### 6.4 BFF

Next.jsをBackend for Frontendとして利用する。

基本的な通信経路は以下とする。

    Browser
       |
       v
    Next.js
    Frontend / BFF
       |
       v
    Backend API
       |
       v
    PostgreSQL

BrowserからBackend APIを直接利用することは原則として行わない。

また、Next.jsから業務データを保持するPostgreSQLへ直接アクセスしない。

Backend APIとの通信方法やServer Components / Route Handlers / Server Actionsの使い分けについてはFrontend Architectureで管理する。

---

### 6.5 Version方針

Next.jsは安定版を利用する。

Major Version Updateについては以下を確認した上で実施する。

- Reactとの互換性
- Node.jsとの互換性
- 利用Libraryとの互換性
- Breaking Changes
- Migration Guide
- Security Update
- Productionでの安定性

新しいMajor Versionが公開されたことだけを理由に即時Upgradeしない。

Patch / Minor Updateについては、互換性とSecurityを確認しながら継続的に更新する。

具体的なVersionは `package.json` および `pnpm-lock.yaml` で管理する。

---

## 7. Package Manager

### 7.1 候補

Package Managerとして以下を比較対象とする。

- npm
- pnpm
- Yarn
- Bun

---

### 7.2 採用

pnpmを採用する。

    Package Manager
        ↓
    pnpm

---

### 7.3 採用理由

本プロジェクトではMonorepoを採用するため、Workspace管理との親和性を重視してpnpmを採用する。

主な理由は以下とする。

- Workspaceをサポートしている
- Monorepoで複数Packageを管理しやすい
- Workspace全体でLockfileを管理できる
- `workspace:` protocolを利用できる
- Content-addressable Storeにより依存Packageを効率的に共有できる
- npm互換の `package.json` を利用できる
- 宣言していない依存Packageを暗黙的に利用しにくい
- CI / Docker環境で利用しやすい
- TypeScript / Next.js Ecosystemとの親和性が高い

---

### 7.4 Monorepoでの利用

JavaScript / TypeScript Packageはpnpm Workspaceで管理する。

構成イメージ：

    engineer-skill-management/
    ├── frontend/
    │   └── package.json
    │
    ├── packages/
    │   └── ...
    │
    ├── backend/
    │   └── Laravel
    │
    ├── docs/
    │
    ├── pnpm-workspace.yaml
    ├── package.json
    └── pnpm-lock.yaml

Laravel BackendのPHP依存関係はComposerで管理する。

pnpmとComposerの責務を分離する。

    JavaScript / TypeScript
        ↓
    pnpm

    PHP
        ↓
    Composer

---

### 7.5 Lockfile

`pnpm-lock.yaml` をGitで管理する。

開発環境、CI、Dockerで同一の依存関係を再現できる状態を維持する。

CIではLockfileを変更しないInstallを基本とする。

    pnpm install --frozen-lockfile

---

### 7.6 pnpm Version管理

pnpmのVersionはプロジェクト単位で固定する。

`package.json` の `packageManager` フィールドを利用する。

例：

    {
      "packageManager": "pnpm@<version>"
    }

具体的なVersionはリポジトリ側で管理する。

---

### 7.7 npm

採用しない。

npmはNode.jsに標準で付属し、Workspaceも利用できるため、本プロジェクトを構築するための機能は備えている。

一方、本プロジェクトではMonorepoを前提とし、Workspace運用や依存関係管理を重視するためpnpmを優先する。

---

### 7.8 Yarn

採用しない。

YarnもWorkspaceなどMonorepo向けの機能を備えている。

ただし、本プロジェクトではYarn固有の機能を必要とせず、pnpmで必要な要件を満たせるため採用しない。

---

### 7.9 Bun

採用しない。

BunはRuntime、Package ManagerなどJavaScript / TypeScript開発に必要な複数機能を提供する。

ただし、本プロジェクトではRuntimeとしてNode.jsを採用する。

Package Managerのみを目的としてBunを追加する必要性がないため、MVPでは採用しない。

---

## 8. Version管理

技術選定ドキュメントとリポジトリではVersion管理の責務を分ける。

### 技術選定ドキュメント

Major VersionやLTS系列など、Architectureや互換性に影響するVersion方針を管理する。

例：

    Node.js 24 LTS
    React 19
    Next.js
    TypeScript
    pnpm

### Repository

実際に利用する正確なVersionを管理する。

主に以下をSource of Truthとする。

    package.json
    pnpm-lock.yaml
    Dockerfile
    Node.js Version管理ファイル

これによりPatch Updateのたびに技術選定ドキュメントを変更することを避ける。

---

## 9. 環境間の統一

ローカル開発環境、Docker、CIで可能な限り同一のRuntimeおよびPackage Manager Versionを利用する。

    Local Development
          │
          ├── Node.js
          └── pnpm
                │
                │ Same Version
                ↓
    Docker
          │
          ├── Node.js
          └── pnpm
                │
                │ Same Version
                ↓
    CI
          │
          ├── Node.js
          └── pnpm

「ローカルでは動くがCIやDockerでは動かない」という環境差異を可能な限り減らす。

---

## 10. 決定事項

FrontendおよびBFFの基本技術を以下とする。

| 分類 | 決定 |
| --- | --- |
| Runtime | Node.js 24 LTS |
| Language | TypeScript |
| TypeScript | `strict` を基本とする |
| UI Library | React 19 |
| Component | Function Component |
| Framework | Next.js |
| Router | App Router |
| Frontend方針 | Server Componentsを基本とする |
| BFF | Next.js |
| Package Manager | pnpm |
| Workspace | pnpm Workspace |
| Lockfile | `pnpm-lock.yaml` |
| Backend Package Manager | Composer |

基本構成は以下とする。

    Node.js 24 LTS
           |
           v
       Next.js
           |
           +-- React 19
           |
           +-- TypeScript
           |
           +-- Frontend
           |
           +-- BFF
           |
           v
      Backend API

Package管理は以下とする。

    Monorepo
       |
       +-- JavaScript / TypeScript
       |       |
       |       └── pnpm
       |
       └-- PHP
               |
               └── Composer

具体的なPatch Versionはリポジトリで管理し、本ドキュメントでは基本技術およびVersion方針を管理する。
