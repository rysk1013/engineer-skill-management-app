# 監視・Observability

## 1. 目的

本ドキュメントでは、Engineer Skill Management App における監視およびObservabilityに関する非機能要件を定義する。

サービス停止、Application Error、性能劣化、Database障害、Backup障害等を適切に検知し、障害調査および復旧に必要な情報を取得できる状態を維持することを目的とする。

特定の監視製品の導入自体を目的とせず、「何を観測・検知できる必要があるか」を要件として定義する。

---

## 2. 基本方針

Observabilityは以下の3要素を基本とする。

```text
Logs
Metrics
Traces
```

MVPでは以下の方針とする。

| 項目 | MVP |
|---|---|
| Logs | 必須 |
| Metrics | 基本Metrics必須 |
| Traces | 将来対応 |

監視では最低限、以下を確認できる状態とする。

- サービスが正常に稼働しているか
- Application Errorが増加していないか
- Response Timeが悪化していないか
- Infrastructure Resourceが逼迫していないか
- PostgreSQLが正常に利用できるか
- Backupが正常に取得されているか
- 重大なSecurity Eventが発生していないか

---

## 3. Monitoring Infrastructure

MVPでは特定のMonitoring Stackを必須としない。

以下の優先順位を基本とする。

```text
Cloud / Hosting Provider標準監視
              │
              ▼
      SaaS Monitoring
              │
              ▼
      専用Monitoring Stack
```

MVPでは以下の自己運用を必須としない。

- Prometheus
- Grafana
- Loki
- ELK / Elastic Stack

監視基盤そのものの運用負荷を必要以上に増加させない。

---

## 4. Health Check

Applicationの状態を確認するためHealth Check Endpointを提供する。

Health Checkは以下の役割を分離可能な設計とする。

### Liveness

Application Process自体が正常に動作していることを確認する。

```text
Application
    │
    └── Alive ?
```

### Readiness

ApplicationがRequestを正常に処理可能な状態であることを確認する。

必要に応じてDatabase接続状態等を確認する。

```text
Application
     │
     ├── Application Ready
     │
     └── Database Available
```

MVPでは最低限以下を確認可能とする。

- Applicationが応答可能であること
- Databaseへ接続可能であること

---

## 5. Health Check Security

Health Check Responseには必要最小限の情報のみ含める。

以下を公開しない。

- Database Credential
- Secret
- Token
- Stack Trace
- Server内部Path
- Environment Variable
- 詳細なInfrastructure情報
- その他攻撃者に不要な内部情報

Health Check Endpoint自体が情報漏洩源とならないようにする。

---

## 6. 死活監視

Production環境では定期的な死活監視を行う。

最低限以下を対象とする。

- Next.js
- Laravel API
- Health Check Endpoint
- Database接続

以下の状態を検知可能とする。

```text
Next.js応答なし

Laravel API応答なし

Health Check失敗

Database接続不能
```

瞬間的な1回の失敗のみで重大障害と判断せず、原則として連続失敗または一定期間の失敗を基準にAlertを発生させる。

---

## 7. HTTP監視

HTTP Requestについて最低限以下を確認可能とする。

- Request数
- HTTP 2xx
- HTTP 4xx
- HTTP 5xx
- Response Time

HTTP 5xxの増加はAlert対象とする。

HTTP 4xxにはValidation Errorや通常のAuthorization Error等も含まれるため、一律でAlert対象とはしない。

---

## 8. Response Time監視

`性能・スケーラビリティ.md` で定義した性能目標を基準とする。

| API | p95目標 |
|---|---:|
| 通常CRUD API | 500ms以内 |
| 検索・一覧API | 1秒以内 |
| 集計API | 1秒以内 |

最低限以下を確認可能とする。

- Average Response Time
- p95 Response Time
- Slow Request

MVPでは性能目標超過をすべてリアルタイムAlertにすることは必須としない。

継続的な性能劣化を確認できる状態を維持する。

---

## 9. Infrastructure Metrics

Application Infrastructureについて最低限以下を監視可能とする。

- CPU Usage
- Memory Usage
- Disk Usage
- Network
- Container Restart

Cloud / Hosting Providerが提供するMetricsを優先して利用する。

---

## 10. CPU / Memory

CPUおよびMemoryの継続的な高負荷を確認可能とする。

一時的なSpikeのみで重大障害と判断せず、一定期間継続しているかを考慮する。

Resource不足によってApplicationのResponse TimeやAvailabilityへ影響している場合はAlert対象とする。

---

## 11. Disk

Disk使用量を監視する。

Disk容量逼迫によって以下が発生する可能性を考慮する。

- Database書き込み失敗
- Log書き込み失敗
- Application障害
- Backup失敗

Disk容量が危険な水準へ到達する前にWarningを発生させる。

---

## 12. Container監視

Docker Containerについて最低限以下を確認可能とする。

- Container稼働状態
- Restart回数
- 異常終了

ContainerのRestartが短時間に繰り返される状態を異常として検知可能にする。

---

## 13. PostgreSQL監視

PostgreSQLについて最低限以下を確認可能とする。

- Database接続可否
- Connection数
- CPU Usage
- Memory Usage
- Disk Usage
- Database Error
- Slow Query

特に以下を重要な障害として扱う。

```text
Database接続不能

Connection枯渇

Disk容量逼迫
```

Database接続不能はAlert対象とする。

---

## 14. Connection監視

PostgreSQLのConnection数を確認可能とする。

最大Connection数へ近づいている状態を検知できるようにする。

Connection PoolingはMVP必須要件とはしない。

必要性が確認された場合に導入を検討する。

---

## 15. Slow Query

Slow Queryを調査可能な状態とする。

性能問題が発生した場合は以下を利用する。

- Slow Query Log等のDatabase機能
- `EXPLAIN`
- `EXPLAIN ANALYZE`

Slow Queryの存在だけで即時AlertすることはMVPでは必須としない。

---

## 16. Backup監視

`データ保護・バックアップ.md` で定義したBackupについて監視する。

最低限以下を確認可能とする。

- Backup Job成功
- Backup Job失敗
- 最終Backup成功日時
- Backup Dataの存在

Backup Job失敗はAlert対象とする。

---

## 17. RPO監視

RPOは24時間以内とする。

そのため、

```text
最終Backup成功
      │
      ▼
24時間以上経過
      │
      ▼
Alert
```

とする。

24時間以上Backup成功が確認できず、RPOを満たせない状態を放置しない。

---

## 18. Security監視

`ログ・監査.md` で定義したSecurity Logを利用し、最低限以下を確認可能とする。

- Login失敗
- Authentication失敗
- Authorization失敗
- Rate Limit超過

これらの異常な増加を調査可能な状態とする。

MVPでは高度なBehavior Analysisや自動異常検知を必須としない。

---

## 19. Logs

以下のログを監視・障害調査に利用する。

- Application Log
- Access Log
- Security Log
- Audit Log

Structured Loggingを基本とする。

詳細なLogging要件については `ログ・監査.md` に従う。

---

## 20. Request ID

Request IDを利用して複数Layer間の処理を追跡可能にする。

```text
Browser
   │
   ▼
Next.js BFF
   │
   │ Request ID
   ▼
Laravel API
   │
   ├── Application Log
   ├── Access Log
   ├── Security Log
   └── Audit Log
```

Next.js BFFからLaravel APIへRequest IDを引き継ぐ。

障害調査時に同一Requestに関連するLogを検索可能にする。

---

## 21. Alert対象

MVPでは最低限以下をAlert対象とする。

### Availability

- サービスDown
- Health Check連続失敗

### Application

- HTTP 5xxの重大な増加

### Database

- Database接続不能
- Disk容量逼迫

### Backup

- Backup Job失敗
- 24時間以上Backup成功なし

PerformanceやSecurity Eventについては確認可能な状態を作り、必要性に応じてAlertを追加する。

---

## 22. Alert Severity

MVPでは以下の2段階を使用する。

### Critical

即時確認が必要な重大障害。

例:

- サービス停止
- Database接続不能
- BackupがRPOを満たせない状態
- HTTP 5xxの重大な増加

### Warning

直ちにサービス停止ではないが、確認が必要な状態。

例:

- Disk使用量増加
- CPU高負荷
- Memory高負荷
- Response Time悪化
- Authentication失敗増加

MVPでは必要以上に細かなSeverity分類を作らない。

---

## 23. Alert通知

Alertは最低1つ以上の通知経路へ送信する。

利用可能な例:

- Email
- Slack
- Cloud / Hosting Provider Notification

具体的な通知ServiceはInfrastructure決定時に選択する。

Critical Alertが誰にも通知されない状態を許容しない。

---

## 24. Alert Fatigue対策

不要なAlertの大量発生を避ける。

以下を基本とする。

- 同一障害を短時間に大量通知しない。
- 一時的なSpikeのみでCritical Alertを発生させない。
- 連続失敗または一定期間継続を判断基準とする。
- 復旧時にRecovery通知を行える構成を推奨する。
- 不要なAlert Ruleを定期的に見直す。

---

## 25. Dashboard

MVPでは専用Monitoring Dashboardの構築を必須としない。

Cloud / Hosting Provider標準Dashboard等で最低限以下を確認可能であればよい。

- Availability
- Request数
- HTTP Error
- Response Time
- CPU
- Memory
- Disk
- Database状態
- Backup状態

---

## 26. Distributed Tracing

Distributed TracingはMVPでは必須としない。

以下は将来対応とする。

- OpenTelemetry
- Trace ID
- Span ID
- Distributed Trace
- Trace Visualization

MVPではRequest IDによるCorrelationを利用する。

---

## 27. Monitoring障害

Monitoring Infrastructure自体の障害によってApplicationの通常処理を停止させない。

```text
Monitoring障害
     │
     ├── Application → 原則継続
     │
     └── Monitoring → 復旧対象
```

ただし、監視不能状態が長期間継続しないようにする。

Monitoring Platformが監視不能となっていること自体を確認可能な構成を推奨する。

---

## 28. MVP決定事項

| 項目 | 決定 |
|---|---|
| Logs | 必須 |
| Metrics | 基本Metrics必須 |
| Distributed Tracing | MVPでは不要 |
| Health Check | 必須 |
| Liveness | 対応 |
| Readiness | 対応 |
| DB接続確認 | 必須 |
| 死活監視 | 必須 |
| HTTP 5xx監視 | 必須 |
| Response Time確認 | 必須 |
| p95確認 | 可能にする |
| CPU監視 | 必須 |
| Memory監視 | 必須 |
| Disk監視 | 必須 |
| Network確認 | 可能にする |
| Container Restart確認 | 必須 |
| PostgreSQL監視 | 必須 |
| DB接続異常 | Alert |
| DB Connection数 | 監視 |
| Slow Query | 確認可能にする |
| Backup監視 | 必須 |
| Backup失敗 | Alert |
| 24時間以上Backup成功なし | Alert |
| Security Event | 確認可能にする |
| Structured Logging | 採用 |
| Request ID | 必須 |
| Alert Severity | Critical / Warning |
| Alert通知経路 | 1つ以上必須 |
| Dashboard | Provider標準機能で可 |
| Prometheus | MVPでは不要 |
| Grafana | MVPでは不要 |
| OpenTelemetry | 将来対応 |
| SIEM | 将来対応 |

---

## 29. 将来検討

システム規模、利用者数、Infrastructure構成、運用体制に応じて以下を検討する。

- OpenTelemetry
- Distributed Tracing
- Trace ID / Span ID
- Prometheus
- Grafana
- Loki
- ELK / Elastic Stack
- SaaS APM
- Centralized Logging
- SIEM
- SLO / SLI
- Error Budget
- Alert Escalation
- On-call体制
- Synthetic Monitoring
- Real User Monitoring
- Database Connection Pooling
- Automated Anomaly Detection
- Security Event自動検知
- Monitoring Infrastructureの冗長化
