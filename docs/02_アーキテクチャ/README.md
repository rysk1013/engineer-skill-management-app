# アーキテクチャ

Engineer Skill Management App のアーキテクチャ方針と、Laravel Backendの内部設計を管理するディレクトリです。

このディレクトリでは、技術製品の選定結果ではなく、システムをどのような責務と依存関係で構成するかを定義します。採用技術は[`04_技術選定`](../04_技術選定/README.md)、データベースや認証・APIの具体設計は[`03_システム設計`](../03_システム設計/README.md)で管理します。

## 基本方針

Laravel Backendでは、次の方針を採用します。

- Clean ArchitectureによってBusiness LogicとFramework・Databaseを分離する
- DDDによって業務概念とBusiness RuleをDomain Modelとして表現する
- Lightweight CQRSによってWrite処理とRead処理の責務を分離する
- Presentation、Application、Domain、InfrastructureのLayer境界を明確にする
- DomainをLaravel、Eloquent、PostgreSQL、HTTPから独立させる
- 学習目的に必要な範囲で、MVPにおける設計上の複雑さを許容する

基本的な依存方向は次のとおりです。

```text
Presentation
    ↓
Application
    ↓
Domain

Infrastructure
    └── Application / Domainが定義するInterfaceを実装
```

## ディレクトリ構成

| パス | 内容 |
| --- | --- |
| [Backend Architecture 全体方針](./01_Backend/Laravel/01_Backend%20Architecture%20全体方針.md) | Backend全体の構成と主要なアーキテクチャ判断をまとめます。 |
| [`01_Backend/Laravel/`](./01_Backend/Laravel/README.md) | Laravel Backendの内部アーキテクチャを管理します。 |
| [`01_Backend/Laravel/02_ディレクトリ構成.md`](./01_Backend/Laravel/02_ディレクトリ構成.md) | Laravel Backendのディレクトリ配置とLayer構成を管理します。 |
| [`01_Backend/DDD設計/`](./01_Backend/DDD設計/README.md) | Bounded Context、Aggregate、Value Objectなどの具体設計を管理します。 |

## 主要なアーキテクチャ決定

### 基礎方針

- [Clean Architecture採用](./01_Backend/Laravel/01_Backend%20Architecture%20全体方針.md)
- [DDD採用](./01_Backend/Laravel/01_Backend%20Architecture%20全体方針.md)
- [Lightweight CQRS採用](./01_Backend/Laravel/08_CQRS.md)
- [基本依存方向](./01_Backend/Laravel/01_Backend%20Architecture%20全体方針.md)
- [DomainのFramework非依存](./01_Backend/Laravel/03_Domain%20Layer設計.md)

### DomainとPersistence

- [Bounded Context](./01_Backend/Laravel/03_Domain%20Layer設計.md)
- [Aggregate Root](./01_Backend/Laravel/03_Domain%20Layer設計.md)
- [Domain Model](./01_Backend/Laravel/03_Domain%20Layer設計.md)
- [Repository](./01_Backend/Laravel/07_Repository・Mapper.md)
- [Eloquent](./01_Backend/Laravel/06_Infrastructure%20Layer設計.md)
- [Mapper](./01_Backend/Laravel/07_Repository・Mapper.md)

### Applicationとデータ整合性

- [Application Layer](./01_Backend/Laravel/04_Application%20Layer設計.md)
- [CQRS](./01_Backend/Laravel/08_CQRS.md)
- [Read処理](./01_Backend/Laravel/08_CQRS.md)
- [Transaction](./01_Backend/Laravel/09_Transaction.md)
- [Concurrency](./01_Backend/Laravel/09_Transaction.md)
- [Database整合性](./01_Backend/Laravel/06_Infrastructure%20Layer設計.md)

### 外部境界と品質

- [Presentation Layer](./01_Backend/Laravel/05_Presentation%20Layer設計.md)
- [Authorization](./01_Backend/Laravel/05_Presentation%20Layer設計.md)
- [API](./01_Backend/Laravel/05_Presentation%20Layer設計.md)
- [Error Handling](./01_Backend/Laravel/10_Exception設計.md)
- [Authentication](./01_Backend/Laravel/06_Infrastructure%20Layer設計.md)
- [Testing](./01_Backend/Laravel/12_テスト戦略.md)
- [コード品質](./01_Backend/Laravel/12_テスト戦略.md)

## DDD設計

具体的なDomain設計は、次の順序で整理しています。

1. [Bounded Context設計](./01_Backend/DDD設計/01_Bounded-Context設計.md)
2. [Aggregate設計](./01_Backend/DDD設計/02_Aggregate設計.md)
3. [Aggregate Root](./01_Backend/DDD設計/03_Aggregate-Root/)
4. [Value Object設計](./01_Backend/DDD設計/04_Value-Object設計.md)
5. [Application Layer設計](./01_Backend/DDD設計/05_Application-Layer設計.md)
6. [Repository・Mapper設計](./01_Backend/DDD設計/06_Repository・Mapper設計.md)
7. [Persistence設計](./01_Backend/DDD設計/07_Persistence設計.md)
8. [Transaction・Lock・Concurrency設計](./01_Backend/DDD設計/08_Transaction・Lock・Concurrency設計.md)
9. [Presentation Layer設計](./01_Backend/DDD設計/09_Presentation-Layer設計.md)
10. [Access Control設計](./01_Backend/DDD設計/10_Access-Control設計.md)

## 推奨する読み順

1. [Backend Architecture 全体方針](./01_Backend/Laravel/01_Backend%20Architecture%20全体方針.md)で、Backend全体の構成を把握する。
2. 基礎方針の決定事項で、採用するArchitectureとLayerの依存方向を確認する。
3. `01_Backend/Laravel/`の各設計文書で、実装時に守る個別ルールを確認する。
4. `01_Backend/DDD設計/`で、各Domain ModelとUse Caseの具体設計を確認する。
5. 必要に応じてシステム設計と技術選定を参照し、Infrastructureとの接続方法を確認する。

## 文書管理ルール

- `01_Backend/Laravel/`には、実装時に適用する方針をLayerやトピックごとの設計文書に記録します。
- `01_Backend/DDD設計/`には、複数の決定事項を組み合わせた具体的なDomain・Application設計を記録します。
- 方針を変更した場合は、関連するDDD設計、システム設計、技術選定との整合性を確認します。
- 旧設計は削除や上書きをせず、該当する`archive/`へ移動します。
