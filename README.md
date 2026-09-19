# Engineer Skill Management App

社員が保有する技術・スキルを管理し、組織内の技術保有状況を把握するためのWebアプリケーションです。

## Overview

Engineer Skill Management Appでは、社員ごとの技術、経験期間、スキルレベル、最終利用時期などを管理します。

主な管理対象は以下です。

- Employee
- Department
- Skill Category
- Skill
- Employee Skill
- Access Control

詳細な要件は[`docs/01_要件定義`](./docs/01_要件定義/)を参照してください。

## Architecture

Frontend / BFFとBackend APIを分離した構成を採用します。

```text
Browser
   │
   ▼
Next.js Frontend / BFF
   │
   │ HTTP API
   ▼
Laravel Backend API
   │
   ▼
PostgreSQL
```

主な技術構成：

- Frontend / BFF: Next.js
- Backend API: Laravel
- Database: PostgreSQL
- Authentication: Auth.js / Laravel Sanctum
- API Contract: OpenAPI
- Container: Docker

詳細は以下を参照してください。

- [`docs/02_アーキテクチャ`](./docs/02_アーキテクチャ/)
- [`docs/03_システム設計`](./docs/03_システム設計/)
- [`docs/04_技術選定`](./docs/04_技術選定/)

## Repository Structure

```text
engineer-skill-management-app/
├── backlog/
├── backend/
├── docs/
├── frontend/
└── README.md
```

### `frontend/`

Next.jsによるFrontend / BFFを管理します。

### `backend/`

LaravelによるBackend APIを管理します。

### `docs/`

要件定義、アーキテクチャ、システム設計、技術選定、MVP実装計画、開発・運用方針などのプロジェクトドキュメントを管理します。

### `backlog/`

開発タスクと進捗をRepository内で管理します。

## Documentation

プロジェクトの設計・方針は[`docs/`](./docs/)をSource of Truthとして管理します。

主なドキュメント：

```text
docs/
├── 01_要件定義/
├── 02_アーキテクチャ/
├── 03_システム設計/
├── 04_技術選定/
├── 05_MVP実装計画/
├── 06_開発・運用/
└── 07_非機能要件/
```

日々の実装タスクについては[`backlog/`](./backlog/)を参照してください。

## Development

開発は以下の流れを基本とします。

```text
docs
  ↓
backlog
  ↓
work branch
  ↓
Pull Request
  ↓
dev
  ↓
validation
  ↓
main
```

通常の作業Branchは`dev`から作成します。

Git / GitHub運用の詳細は[`docs/06_開発・運用/07_Git・GitHub運用.md`](./docs/06_開発・運用/07_Git・GitHub運用.md)を参照してください。

開発環境の構築方法は、環境構築完了後にこのREADMEまたは各ApplicationのREADMEへ追加します。

## Status

MVP開発準備中です。

現在は要件定義、アーキテクチャ、システム設計、技術選定、MVP実装計画を完了し、開発環境構築および実装開始に向けた準備を進めています。
