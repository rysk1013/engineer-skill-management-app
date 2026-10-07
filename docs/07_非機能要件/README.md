# 非機能要件

## 1. 目的

本ディレクトリでは、Engineer Skill Management App における非機能要件を管理する。

機能要件だけでは定義しきれない、可用性、性能、セキュリティ、データ保護、監視、保守性、API品質、運用、ユーザビリティ、互換性、国際化等について、システムとして満たすべき要件を定義する。

本プロジェクトではMVP段階から必要な品質を確保しつつ、過度なInfrastructureや運用負荷を持ち込まないことを基本方針とする。

---

## 2. 対象システム

Engineer Skill Management App の主要構成は以下とする。

```text
Browser
   │
   │ HTTPS
   ▼
Next.js
Frontend / BFF
   │
   │ HTTPS + Sanctum Token
   ▼
Laravel API
   │
   ▼
PostgreSQL
```

主要Technology:

- Frontend / BFF: Next.js
- Application User Authentication: Laravel
- Browser Session Management: Better Auth
- Session / Credential Store: Redis
- Backend: Laravel
- BFF → Backend Authentication: Laravel Sanctum
- Database: PostgreSQL
- Development / Deployment: Docker
- API Design: OpenAPI First
- Backend Architecture:
  - Clean Architecture
  - DDD
  - Lightweight CQRS

---

## 3. 非機能要件一覧

| Document | 主な内容 | 状態 |
|---|---|---|
| `01_可用性・信頼性.md` | 稼働率、RTO / RPO、Transaction、障害復旧 | 決定済み |
| `02_性能・スケーラビリティ.md` | Response Time、想定規模、Pagination、Scale方針 | 決定済み |
| `03_セキュリティ.md` | Authentication、Authorization、CSRF、XSS、Secret管理 | 決定済み |
| `04_データ保護・バックアップ.md` | Backup、Restore、Retention、Production Data保護 | 決定済み |
| `05_ログ・監査.md` | Application Log、Security Log、Audit Log、Request ID | 決定済み |
| `06_監視・Observability.md` | Health Check、Metrics、Alert、DB / Backup監視 | 決定済み |
| `07_保守性・品質.md` | Lint、Static Analysis、Test、CI、ADR、品質Gate | 決定済み |
| `08_API品質.md` | OpenAPI First、Versioning、Error形式、互換性 | 決定済み |
| `09_デプロイ・運用.md` | Environment分離、CI/CD、Migration、Rollback | 決定済み |
| `10_ユーザビリティ・アクセシビリティ.md` | Responsive、Keyboard、WCAG、Form / UI State | 決定済み |
| `11_互換性・動作環境.md` | Browser、Device、Runtime、Version Policy | 決定済み |
| `12_国際化・日時.md` | Locale、UTC、Asia/Tokyo、Date / DateTime / YearMonth | 決定済み |

---

## 4. ディレクトリ構成

```text
docs/
└── 07_非機能要件/
    ├── README.md
    ├── 01_可用性・信頼性.md
    ├── 02_性能・スケーラビリティ.md
    ├── 03_セキュリティ.md
    ├── 04_データ保護・バックアップ.md
    ├── 05_ログ・監査.md
    ├── 06_監視・Observability.md
    ├── 07_保守性・品質.md
    ├── 08_API品質.md
    ├── 09_デプロイ・運用.md
    ├── 10_ユーザビリティ・アクセシビリティ.md
    ├── 11_互換性・動作環境.md
    └── 12_国際化・日時.md
```

---

## 5. 主要な非機能要件

### 5.1 可用性・障害復旧

| 項目 | 決定 |
|---|---|
| 目標稼働率 | 99.5% |
| 利用可能時間 | 原則24時間 |
| 計画停止 | 許容 |
| Zero Downtime Deployment | MVPでは不要 |
| RTO | 4時間以内 |
| RPO | 24時間以内 |
| 完全冗長構成 | MVPでは不要 |

MVPでは過度な高可用性構成を要求せず、障害発生時に現実的な時間内で復旧可能な状態を重視する。

---

## 6. 性能・スケーラビリティ

主要な性能目標は以下とする。

| 項目 | 目標 |
|---|---:|
| 主要画面 | 2秒以内 |
| 比較的重い画面 | 3秒以内 |
| 通常CRUD API | p95 500ms以内 |
| 検索・一覧API | p95 1秒以内 |
| 集計API | p95 1秒以内 |

MVPの設計基準となる想定規模:

| 項目 | 想定 |
|---|---:|
| 在籍社員 | 〜1,000人 |
| Skill Master | 〜5,000件 |
| EmployeeSkill | 〜100,000件 |
| 利用者 | 〜100人 |
| 同時利用者 | 〜20人 |
| API負荷 | 数十req/s程度 |

一覧APIでは原則Paginationを利用し、MVPではOffset Paginationを採用する。

---

## 7. セキュリティ

以下をMVPから必須とする。

- HTTPS
- LaravelによるApplication User Authentication
- Better AuthによるBrowser Session Management
- RedisによるSession / Backend Credential管理
- Sanctum TokenによるBFF → Laravel Authentication
- Backend Authorization
- RBAC
- Resource Scope確認
- IDOR / Broken Access Control対策
- CSRF対策
- XSS対策
- SQL Injection対策
- Request Validation
- Rate Limiting
- Security Headers
- Secret管理
- Dependency Vulnerability確認

BrowserからLaravel APIへの直接通信は原則禁止する。

Permission管理では以下を満たすAdministratorを最低1人維持する。

```text
role = ADMINISTRATOR

AND

can_manage_permissions = true
```

---

## 8. データ保護・バックアップ

DatabaseはPostgreSQLを使用する。

主要方針:

| 項目 | 決定 |
|---|---|
| Database Backup | 必須 |
| Backup頻度 | 最低1日1回 |
| Daily Backup保持 | 30日 |
| Backup暗号化 | 必須 |
| Restore手順 | 必須 |
| 本番導入前Restore Test | 必須 |
| 運用開始後Restore Test | 半年に1回 |
| PITR | MVPでは必須ではない |

Production DataをDeveloper PCやDevelopment環境へコピーすることを原則禁止する。

退職Employeeは退職後3年間保持し、その後管理ユーザーの確認を経て削除する。

Skillは物理削除せず無効化して保持する。

---

## 9. ログ・監査

MVPでは以下の4種類を扱う。

```text
Application Log
Access Log
Security Log
Audit Log
```

保持期間:

| Log | Retention |
|---|---:|
| Application Log | 90日 |
| Access Log | 90日 |
| Security Log | 90日 |
| Audit Log | 3年 |

Request IDを利用し、Next.js BFFとLaravel API間の処理を追跡可能にする。

Audit LogはPostgreSQLへ保存し、原則Append Onlyとする。

重要操作とAudit Logは原則同一Transaction内で保存する。

---

## 10. 監視・Observability

Observabilityは以下を基本とする。

```text
Logs
Metrics
Traces
```

MVP:

```text
Logs       → 必須
Metrics    → 基本Metrics必須
Traces     → 将来対応
```

最低限以下を監視する。

- Health Check
- Service Availability
- HTTP 5xx
- Response Time
- CPU
- Memory
- Disk
- Container Restart
- PostgreSQL接続状態
- DB Connection数
- Backup状態

以下をAlert対象とする。

- Service Down
- Health Check連続失敗
- HTTP 5xxの重大な増加
- Database接続不能
- Disk容量逼迫
- Backup失敗
- 24時間以上Backup成功なし

Alert Severityは `Critical` / `Warning` の2段階を基本とする。

---

## 11. 保守性・品質

Frontend:

- TypeScript `strict`
- ESLint
- Prettier
- Typecheck

Backend:

- PSR-12
- Laravel Pint
- PHPStan / Larastan
- Complexity監視

Test:

- Unit Test
- Integration Test
- Feature / API Test
- 主要FlowのE2E Test

Coverage目標:

| 対象 | 目標 |
|---|---:|
| Backend | 80% |
| Frontend | 70% |

Coverageだけを品質保証とは扱わず、重要Domain RuleやAuthorizationはCoverage値に関係なく必須Test対象とする。

Pull RequestではCI Quality Gateを利用し、CI失敗時のMergeを原則禁止する。

ADRを採用し、重要なArchitecture Decisionを記録する。

---

## 12. API品質

APIはOpenAPI Firstで設計する。

基本方針:

```text
Requirement
    ↓
API Design
    ↓
OpenAPI
    ↓
Review
    ↓
Implementation
    ↓
Test
```

主要決定:

| 項目 | 決定 |
|---|---|
| API Contract | OpenAPI |
| Data Format | JSON |
| API Version | `/api/v1` |
| Versioning | URL Path Versioning |
| Response Envelope | 統一 |
| Error Response | 統一 |
| Application Error Code | 採用 |
| API ID型 | string |
| DB PK | bigint |
| DateTime | ISO 8601 / UTC |
| Pagination | Offset |

同一Major Version内では可能な限りBackward Compatibilityを維持する。

---

## 13. デプロイ・運用

Environmentは以下の3つを使用する。

```text
Development
Staging
Production
```

以下をEnvironmentごとに分離する。

- Database
- Credential
- Secret
- Environment Variable
- Backup

Production Deployは以下を基本とする。

```text
CI
 ↓
Build
 ↓
Container Image
 ↓
Staging
 ↓
Verification
 ↓
Approval
 ↓
Production
```

MVPではZero Downtime Deploymentは必須としない。

Database MigrationはGit管理し、Production適用前にStagingで確認する。

Productionで使用するApplication / Container ImageはGit Commit SHA、Release Version、Image Digest等で識別可能にする。

---

## 14. ユーザビリティ・アクセシビリティ

MVPではDesktop Firstとする。

| Device | 方針 |
|---|---|
| Desktop | 主要Support |
| Tablet | 利用可能 |
| Smartphone | 基本操作可能 |

主要要件:

- Responsive Design
- Semantic HTML
- Keyboard操作
- Focus Indicator
- Dialog Focus Management
- Form Label
- Field単位のValidation Error
- Loading State
- Success Feedback
- Empty State
- Error State
- 二重送信防止
- 重要操作のConfirmation
- 色だけに依存しない情報表現

WCAG 2.2 Level AAを設計・実装上の目標とする。

MVPでは正式な完全準拠認証までは要求しない。

---

## 15. 互換性・動作環境

正式Support Browser:

- Google Chrome
- Microsoft Edge
- Safari
- Firefox

Version Policy:

```text
Latest Stable Major
+
Previous Stable Major
```

Internet ExplorerおよびEOL BrowserはSupport対象外とする。

その他主要要件:

| 項目 | 決定 |
|---|---|
| Windows | 主要対象 |
| macOS | 主要対象 |
| Linux | Support Browser範囲で利用可能 |
| JavaScript | 必須 |
| Cookie | 必須 |
| Desktop主要Viewport | 1280px以上を目安 |
| Browser Zoom | 200%で主要操作可能を目標 |
| MVP E2E Browser | Chromium |

Development / CI / ProductionではNode.js、PHP、PostgreSQL等のMajor Versionを可能な限り統一する。

---

## 16. 国際化・日時

MVPの正式対応言語は日本語のみとする。

| 項目 | 決定 |
|---|---|
| Language | 日本語 |
| Locale | `ja-JP` |
| Character Encoding | UTF-8 |
| Internal DateTime | UTC |
| API DateTime | ISO 8601 / UTC |
| Display Timezone | `Asia/Tokyo` |
| User Timezone設定 | MVPでは不要 |
| Time表示 | 24時間表記 |

日時Valueは以下を明確に区別する。

```text
DateTime
→ Instant

Date
→ Calendar Date

YearMonth
→ 年月
```

API Format:

```text
DateTime  → YYYY-MM-DDTHH:mm:ssZ
Date      → YYYY-MM-DD
YearMonth → YYYY-MM
```

UI Format:

```text
DateTime  → YYYY/MM/DD HH:mm
Date      → YYYY/MM/DD
YearMonth → YYYY/MM
```

退職後3年間保持等のCalendar Dateを基準とするBusiness Ruleは `Asia/Tokyo` を基準とする。

---

## 17. MVPに含めない高度な要件

以下はMVPでは必須としない。

- 99.9%以上の高可用性
- Multi-AZ完全冗長構成
- Automatic Failover
- Zero Downtime Deployment
- Blue / Green Deployment
- Canary Deployment
- Redis Cache
- Database Sharding
- Read Replica
- Distributed Tracing
- OpenTelemetry
- Prometheus / Grafana自己運用
- SIEM
- WAF
- Multi-Factor Authentication
- Point-in-Time Recovery必須化
- Cross-region Backup
- Architecture Test
- 全Browser EngineでのE2E
- Accessibility正式Audit
- 多言語UI
- UserごとのTimezone

必要性が発生した段階で追加・再評価する。

---

## 18. 非機能要件変更方針

非機能要件を変更する場合は、関連する設計・実装への影響を確認する。

主な関連Document:

```text
非機能要件
   │
   ├── Architecture
   ├── Database設計
   ├── API設計
   ├── OpenAPI
   ├── Infrastructure
   ├── Test設計
   └── 運用手順
```

例えばRPOを24時間から1時間へ変更する場合、単に本Documentを書き換えるだけではなくBackup方式・Infrastructure・Monitoring等も再設計する必要がある。

非機能要件とTechnical Designの不一致を長期間放置しない。

---

## 19. RequirementとTechnical Designの責務

本ディレクトリでは主に **「システムとして何を保証するか」** を定義する。

具体的な実現方式は各Technical Design Documentで定義する。

例:

```text
docs/07_非機能要件/12_国際化・日時.md
    ↓
DateTimeはUTC
表示TimezoneはAsia/Tokyo

docs/03_システム設計/01_データベース/08_Date・Time設計.md
    ↓
PostgreSQLで使用する型
Mapping
Applicationでの変換方法
```

同様に、SecurityやAvailability等についてもRequirementとImplementation Detailを分離する。

---

## 20. 現在の状態

現在、MVPに必要な主要非機能要件はすべて初期決定済みとする。

```text
可用性・信頼性                  決定済み
性能・スケーラビリティ          決定済み
セキュリティ                    決定済み
データ保護・バックアップ        決定済み
ログ・監査                      決定済み
監視・Observability             決定済み
保守性・品質                    決定済み
API品質                         決定済み
デプロイ・運用                  決定済み
ユーザビリティ・アクセシビリティ 決定済み
互換性・動作環境                決定済み
国際化・日時                    決定済み
```
