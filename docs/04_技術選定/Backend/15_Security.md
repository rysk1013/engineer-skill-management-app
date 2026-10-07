# Backend 技術・Library選定 - Security

## 1. 目的

本ドキュメントでは、Engineer Skill Management App のBackendにおけるSecurity方針と採用技術を定義する。

対象：

- Security Standard
- Authentication / Authorizationとの接続
- Object Level Authorization
- Property Level Authorization
- Mass Assignment
- Input Validation
- SQL Injection
- Rate Limiting
- Resource Consumption
- CORS
- CSRF Boundary
- HTTPS / Trusted Proxy
- Security Headers
- Output Security
- Error Information Leak
- Secret Management
- Dependency Security
- Container Security
- SSRF
- External API Security
- Security Logging
- Audit
- Security Testing
- OpenAPI Security
- Production Hardening

本Projectでは、

> 単一のSecurity Mechanismへ依存せず、Application / Framework / Database / Infrastructure / CIを跨いだDefense in Depthを採用する

ことを基本方針とする。

---

# 2. Security Model

Backend Securityを以下のLayerで構成する。

```text
Authentication / Authorization
    → Better Auth + Redis + Sanctum + Policy

Request Protection
    → Validation + Rate Limit + Resource Limit

Application Boundary
    → Explicit Input Mapping + Domain Rule

Data Access
    → Query Binding + DB Constraint

Response Boundary
    → Explicit Resource Serialization

Network / Browser Boundary
    → BFF + HTTPS + CORS + Security Headers

Secrets
    → Environment / Secret Manager

Runtime
    → Production Hardening + Container Security

Supply Chain
    → Dependency Audit + Vulnerability Scan

Detection
    → Security Log + Audit + Observability
```

---

# Security Standards

## 3. 基準

Security設計・Reviewの基準として以下を採用する。

```text
OWASP Top 10
OWASP API Security Top 10
OWASP ASVS
Laravel Security Best Practices
```

API Securityについては特にOWASP API Security Top 10を意識する。

---

## 4. 重点Risk

本Projectでは特に以下を重視する。

```text
Broken Object Level Authorization
Broken Authentication
Broken Object Property Level Authorization
Unrestricted Resource Consumption
Broken Function Level Authorization
SSRF
Security Misconfiguration
Improper API Inventory Management
Unsafe Consumption of APIs
```

特に、

```text
Authorization
Input / Output Boundary
Resource Consumption
Configuration
```

を重点領域とする。

---

# Authentication

## 5. 認証方式

`03_認証・認可.md`で決定した構成を維持する。

```text
Browser
    ↓
Better Auth Session
    ↓
Next.js BFF
    ↓
Sanctum Bearer Token
    ↓
Laravel Backend
```

Laravel BackendはBrowser Login / Better Auth Session Managementを担当しない。

---

## 6. Sanctum Token

Sanctum TokenはBFF Server Sideでのみ保持する。

禁止：

```text
localStorage
sessionStorage
Browser JavaScript
Client Component
HTML
Browser-accessible Storage
```

BrowserへSanctum TokenをExposeしない。

---

## 7. Authentication Middleware

Protected APIは、

```text
auth:sanctum
```

を利用する。

認証だけでAuthorizationを完了したと判断しない。

---

## 8. Token Logging

以下をLog / Audit / Trace / Metricへ出力しない。

```text
Authorization Header
Bearer Token
Sanctum Token
Better Auth Session Token
Cookie
Password
API Key
Client Secret
Private Key
```

---

# Authorization

## 9. Authorization Boundary

BackendのSecurity BoundaryとしてLaravel Policy / Gateを利用する。

```text
Frontend
    → UX制御

Laravel Backend
    → Security Enforcement
```

FrontendのButton非表示等をAuthorizationとして扱わない。

---

## 10. Authorization Model

既存方針：

```text
Role
+
Employee Assignment
+
Special Permission
```

によるAuthorizationを維持する。

---

## 11. Role

Role：

```text
Administrator
Manager
SubManager
TeamLeader
```

をNative Enumで表現する。

---

## 12. Object Level Authorization

Employee等のObject単位でAccess Controlを必ず確認する。

例えば、

```text
GET /api/v1/employees/{employee_id}
```

では、

```text
Authenticated?
    ↓
このUserが
このEmployeeへ
このOperationを実行可能か？
```

まで確認する。

---

## 13. ID Knowledge != Permission

対象IDを知っていることはAccess権限を意味しない。

```text
employee_id = 123を知っている
    ≠
Employee 123を閲覧できる
```

Object IDを変更して他EmployeeへAccessできる状態を禁止する。

---

## 14. SubManager

SubManagerはAssigned Employeeのみ操作可能とする。

```text
SubManager
    ↓
Assignment Check
    ↓
Target Employee
```

---

## 15. TeamLeader

TeamLeaderはAssigned Employeeのみ閲覧可能とする。

Write Operationは禁止する。

---

## 16. Manager

Managerは全Employeeに対して仕様上許可されたOperationを実行可能とする。

---

## 17. Administrator

Administrator向けOperationもPolicyで制御する。

AdministratorであるだけでPermission Managementを許可しない。

---

## 18. Permission Management

Permission Managementには、

```text
role = ADMINISTRATOR
AND
can_manage_permissions = true
```

を必須とする。

---

## 19. Minimum Administrator Invariant

Permission Management可能なAdministratorが0人になることを禁止する。

既存方針：

```text
Application / Domain Invariant
+
Transaction
+
SELECT FOR UPDATE
```

を維持する。

---

# Function Level Authorization

## 20. Operation単位Authorization

Object AccessだけでなくOperation単位でも制御する。

例：

```text
TeamLeader
    → read only

SubManager
    → assigned employees only

Manager
    → all employees

Administrator
    → administrative operations
```

---

## 21. Route単位だけに依存しない

Route Group MiddlewareのみでFine-grained Authorizationを完結させない。

```text
Route Middleware
    → coarse authentication / authorization

Policy
    → resource / operation authorization
```

とする。

---

# Property Level Authorization

## 22. Property Exposure

Request / ResponseのField単位でもSecurityを考慮する。

Clientが送信・取得可能なFieldを明示する。

---

## 23. Mass Assignment

以下をDefault Patternにしない。

```php
Model::create($request->all());
```

```php
$model->fill($request->all());
```

---

## 24. Explicit Input Mapping

Input Flowは、

```text
Form Request
    ↓
validated()
    ↓
Primitive / Enum / Value Object
    ↓
Command / Query
```

とする。

HTTP InputをEloquent Attributeへ直接Mappingしない。

---

## 25. `$fillable`

Eloquentの`$fillable` / `$guarded`は補助防御として利用可能とする。

ただし、

> `$fillable`があるためRequest全体をModelへ渡して安全

とは考えない。

Primary Defense：

```text
Explicit Mapping
+
Application Layer
+
Domain Model
+
Mapper
```

とする。

---

## 26. Unexpected Field

API Contractに存在しないFieldによってStateを変更できないことを保証する。

例：

```json
{
  "skill_level": 1,
  "role": "ADMINISTRATOR"
}
```

EmployeeSkill Update APIへ上記を送信してもRoleが変更されてはいけない。

---

# Input Validation

## 27. Validation Layer

`06_Validation.md`で決定した4層Validationを維持する。

```text
① Presentation Validation
② Application Validation
③ Domain Invariant
④ Database Constraint
```

---

## 28. Security-oriented Validation

特に以下を制限する。

```text
Type
Length
Range
Enum
Array Size
String Length
ID Format
Date Format
Pagination Size
Sort Field
```

---

## 29. ValidationとAuthorization

Input ValidationでAuthorizationを代替しない。

```text
Valid employee_id
    ≠
Access可能な employee_id
```

---

# SQL Injection

## 30. Query Binding

Database Queryでは、

```text
Eloquent
Query Builder
Parameterized Query
```

を基本とする。

---

## 31. String Concatenation禁止

User Inputを直接SQL文字列へ結合しない。

避ける：

```php
whereRaw("name = '$input'");
```

---

## 32. Raw SQL

Raw SQLが必要な場合もParameter Bindingを必須とする。

---

## 33. Dynamic Sort

Column Name等のIdentifierは通常のParameter Bindingでは保護できないため、Allowlist方式を利用する。

例：

```text
API sort=name
    ↓
Allowlist
    ↓
employees.name
```

Client InputをそのままSQL Identifierとして利用しない。

---

## 34. Search

Search KeywordもQuery Bindingを利用する。

Raw Search StringをSQLへ直接連結しない。

---

# Resource Consumption

## 35. Rate Limiting

Laravel標準Rate Limitingを採用する。

目的：

```text
Abuse Protection
Resource Exhaustion Protection
Sensitive Operation Protection
```

---

## 36. Rate Limit分類

一律のRate Limitだけに依存しない。

候補：

```text
General API
Sensitive Mutation
Permission Management
Expensive Search
Long-running Operation
Authentication-related Operation
```

Endpoint特性によってPolicyを分ける。

---

## 37. Rate Limit Key

Authenticated APIでは基本的に、

```text
user_id
```

をRate Limit Key候補とする。

必要に応じ、

```text
user_id + route group
```

等を利用する。

---

## 38. IP Limit

Unauthenticated Endpointを将来追加した場合はIP-based Limitingを候補とする。

Proxy EnvironmentではTrusted Proxy設定との整合性を必ず確認する。

---

## 39. Rate Limit値

具体値は初期段階で全API共通値として固定しない。

以下を基準に調整する。

```text
Actual Traffic
Frontend Behavior
Operation Cost
Security Risk
Non-functional Requirement
```

---

## 40. Rate Limit Response

Limit超過時：

```text
429 Too Many Requests
```

を返す。

可能な範囲で、

```text
Retry-After
```

を付与する。

RFC 9457 Problem Detailsへ統合する。

---

# Pagination / Resource Limit

## 41. Unlimited Pagination禁止

Clientが任意に巨大Page Sizeを要求できないようにする。

```text
Default Page Size
Maximum Page Size
```

を設定する。

具体値はEndpoint設計時に決定する。

---

## 42. Bulk Input

Bulk APIを導入する場合、

```text
Maximum Item Count
Maximum Payload Size
```

を明示する。

Unlimited Arrayを受け付けない。

---

## 43. Request Body Size

巨大RequestをApplicationまで到達させない。

可能な範囲で、

```text
Load Balancer / Reverse Proxy
Web Server
Application Validation
```

の複数Layerで制限する。

---

## 44. Expensive Query

Search / Filter / Sortを無制限に組み合わせて高Cost Queryを生成できないようにする。

```text
Allowed Filters
Allowed Sorts
Pagination
Query Design
```

で制御する。

---

# CORS

## 45. Browser Access Model

Application Architecture：

```text
Browser
    ↓
Next.js BFF
    ↓
Laravel Backend
```

を維持する。

BrowserからLaravel APIへ直接AccessすることをFrontend Contractにしない。

---

## 46. CORS

Laravel BackendではStrict CORSを採用する。

必要なOriginのみAllowする。

---

## 47. Wildcard

Productionで、

```text
Access-Control-Allow-Origin: *
```

をDefaultにしない。

---

## 48. CORS最小化

Browser → Laravel Direct Accessを前提としないため、Laravel側CORS Configurationを必要最小限に保つ。

Server-to-server BFF通信ではBrowser CORS MechanismそのものはSecurity Boundaryではない。

---

# CSRF

## 49. Laravel側Authentication

Laravel Backendは、

```text
Sanctum Bearer Token
```

をBFFから受ける。

Sanctum SPA Cookie Authenticationは使用しない。

---

## 50. Laravel API CSRF

Laravel Backendへ不要なSPA Cookie CSRF Flowを導入しない。

Bearer Token AuthenticationとCookie Authenticationを混在させない。

---

## 51. Browser Boundary

CSRF対策の主要Boundaryは、

```text
Browser
    ↔
Next.js BFF
```

とする。

Better Auth Session Cookie / SameSite / Request Origin等のSecurityはFrontend/BFF側設計と連携する。

---

# HTTPS

## 52. HTTPS

Staging / ProductionではHTTPSを必須とする。

```text
HTTP only
    → 不可

HTTPS
    → 必須
```

---

## 53. TLS Termination

Production InfrastructureではLoad Balancer / Reverse Proxy等でTLS Terminationしてよい。

概念：

```text
Client
    ↓ HTTPS
Load Balancer
    ↓
Application Container
```

---

# Trusted Proxy

## 54. Forwarded Header

以下を任意Clientから無条件にTrustしない。

```text
X-Forwarded-For
X-Forwarded-Proto
Forwarded
```

---

## 55. Trusted Proxy設定

Infrastructure構成に合わせてTrusted Proxyを明示する。

これは以下に影響する。

```text
HTTPS Detection
Client IP
Rate Limiting
Logging
Security Monitoring
URL Generation
```

---

# Security Headers

## 56. Security Headers採用

適切なSecurity Headersを採用する。

候補：

```text
Strict-Transport-Security
X-Content-Type-Options
Referrer-Policy
Content-Security-Policy
Permissions-Policy
```

---

## 57. Header責務

Browser-facing Headerは主にNext.js / Edge / Reverse ProxyがPrimary Responsibilityを持つ。

Laravel JSON APIではAPIに適したHeaderのみ設定する。

---

## 58. CSP

Content Security Policyは主にHTMLを返すFrontend/BFF側で管理する。

```text
Next.js
    → CSP primary owner

Laravel JSON API
    → CSP primary ownerではない
```

---

## 59. HSTS

Production HTTPS運用が確立した段階でHSTSを利用する。

Infrastructure / Edge LevelをPrimary候補とする。

Local Developmentへ適用しない。

---

## 60. Content Type

API Response Content-Typeを明示する。

通常Response：

```text
application/json
```

Problem Details：

```text
application/problem+json
```

---

# Output Security

## 61. Eloquent直接Serialization禁止

以下を禁止する。

```php
return $employee;
```

```php
return EmployeeModel::find($id);
```

---

## 62. Response Flow

```text
Application Result
or
Read Model
    ↓
JsonResource
    ↓
Explicit API Response
```

とする。

---

## 63. JsonResource

ResourceでResponse Fieldを明示する。

目的：

```text
Unexpected Field Exposure防止
Internal Column Exposure防止
Relationship Leakage防止
API Contract安定化
```

---

## 64. Secret Field

以下をResponseへ含めない。

```text
password
password_hash
remember_token
Sanctum Token
Better Auth Session Token
Secret
Internal Credential
```

---

## 65. Internal Data

以下も必要性がなければExposeしない。

```text
Internal Database ID以外のInternal Column
Infrastructure Metadata
Framework-specific Field
Internal Permission Implementation Detail
```

---

# Error Security

## 66. Problem Details

`07_Exception・Error-Handling.md`のRFC 9457方針を維持する。

---

## 67. 5xx Response

Unexpected ErrorではGeneric Errorのみ返す。

Userへ以下をExposeしない。

```text
Stack Trace
SQL
Database Table
Filesystem Path
Environment Variable
DB Host
Secret
Raw Exception Message
Internal Class Name
```

---

## 68. APP_DEBUG

Productionでは、

```env
APP_DEBUG=false
```

を必須とする。

---

## 69. Internal Diagnosis

詳細情報はUser Responseではなく、

```text
Structured Log
Error Monitoring
Trace
Request ID
```

へ記録する。

---

# Secret Management

## 70. Repository Secret禁止

以下をGitへCommitしない。

```text
.env
API Key
DB Password
Cloud Credential
Private Key
Encryption Key
Sanctum Token
Session Token
```

---

## 71. `.env.example`

`.env.example`にはSafe Exampleのみ含める。

```env
APP_KEY=
DB_PASSWORD=
```

Actual Secretは記載しない。

---

## 72. Local Secret

Local Development SecretとProduction Secretを明確に分離する。

Local用固定値をProductionへ流用しない。

---

## 73. Production Secret Store

Production InfrastructureではSecret Managerを利用する。

AWS ECSを採用する場合の候補：

```text
AWS Secrets Manager
AWS Systems Manager Parameter Store
```

最終選定はInfrastructure設計で決定する。

---

## 74. Secret Rotation

SecretをRotation可能な構成にする。

Applicationが特定Secretの永久固定を前提にしない。

---

## 75. Secret Logging

Configuration / Exception Dump等によるSecret Leakにも注意する。

SecretはMaskするより、

> 最初からLogへ渡さない

ことを優先する。

---

# Dependency Security

## 76. Composer Audit

Backend Dependency Vulnerability Checkとして、

```bash
composer audit
```

を採用する。

CIでも実行する。

---

## 77. Dependency Lock

```text
composer.lock
```

をVersion Controlする。

Productionで意図しないDependency Upgradeを行わない。

---

## 78. Dependabot

GitHub Dependabotを採用する。

候補対象：

```text
Composer
Frontend Package Manager
GitHub Actions
Docker
```

---

## 79. Vulnerability対応

VulnerabilityはSeverityだけで判断しない。

以下も確認する。

```text
Affected Version
Reachability
Runtime Exposure
Exploitability
Available Fix
Breaking Change Risk
```

---

## 80. High / Critical

High / Critical Vulnerabilityは優先対応する。

対応不能な場合は、

```text
Impact
Mitigation
Reason
Planned Fix
```

を明示する。

---

# Secret Scanning

## 81. Secret Scanning

GitHub Secret Scanning等、利用可能なRepository Security機能を有効化する。

---

## 82. Additional Scanner

追加Secret Scannerが必要になった場合はGitleaks等を候補とする。

MVPでは同一目的のToolを重複導入しない。

---

# Container Security

## 83. Production Image

Production ImageはDevelopment Imageと分離する。

---

## 84. Xdebug

Production ImageへXdebugを含めない。

---

## 85. Development Tool

以下もProduction Runtimeへ不要なら含めない。

```text
Debugger
Compiler
Build Tool
Development Package
Test Tool
```

---

## 86. Multi-stage Build

Production Docker ImageはMulti-stage Buildを採用する。

概念：

```text
Build Stage
    ↓
Dependency / Artifact Build
    ↓
Runtime Stage
```

---

## 87. Minimal Runtime

Runtime ImageにはApplication実行に必要なものだけを残す。

Attack SurfaceとImage Sizeを減らす。

---

## 88. Non-root

Application Processは可能な限りnon-root userで実行する。

---

## 89. Write Permission

Filesystem Write Permissionを必要最小限にする。

Laravelで書込みが必要な代表例：

```text
storage
bootstrap/cache
```

それ以外を理由なくWritableにしない。

---

## 90. Container Credential

Cloud Credential等をDocker ImageへBakeしない。

Runtime Secret Injectionを利用する。

---

# Container Vulnerability Scan

## 91. Image Scan

Production Containerを利用する段階でContainer Vulnerability Scanを採用する。

Tool候補：

```text
Trivy
```

最終的なCI実行方法は`16_CI・Automation.md`で定義する。

---

# File Upload

## 92. MVP

現在のRequirementではFile Upload機能を実装しない。

Attack Surfaceを不要に増やさない。

---

## 93. Future Upload

将来追加する場合は別途以下を設計する。

```text
MIME Validation
Extension Validation
Size Limit
Storage Isolation
Public Access Control
Filename Handling
Malware Scan
Image Processing
Content-Disposition
```

---

# SSRF

## 94. Arbitrary URL Fetch

MVPではUser指定URLをBackendがFetchする機能を設けない。

---

## 95. Future SSRF Protection

Webhook / URL Fetch等を追加する場合は以下を検討する。

```text
Allowed Scheme
Host Allowlist
IP Validation
Private Network Blocking
DNS Rebinding対策
Redirect Validation
Timeout
Maximum Response Size
```

---

## 96. Direct Fetch禁止

以下のようにUser Inputを無検証でFetchしない。

```php
Http::get($request->url);
```

---

# External API Security

## 97. External Data

External Serviceから返されたDataも信頼しない。

```text
External Response
    ↓
Validate
    ↓
Map
    ↓
Internal Type
```

とする。

---

## 98. Timeout

External HTTP RequestにはTimeoutを設定する。

```text
Connect Timeout
Request Timeout
```

Infinite Waitを禁止する。

---

## 99. Redirect

Redirectを無制限にFollowしない。

External Service特性に合わせて制限する。

---

## 100. External Secret

Authorization Header / API KeyをLogへ含めない。

---

# Security Logging

## 101. Security Log

`09_Log・Audit.md`で定義したSecurity Logを利用する。

Application LogとはPurposeを区別する。

---

## 102. Security Event候補

```text
Authentication Failure
Invalid Token
Expired Token
Revoked Token
Repeated Authorization Failure
Permission Management Failure
Administrator Permission Change
User Disable
Forced Logout
Rate Limit Violation
Suspicious Access Pattern
```

---

## 103. Every 403 != Incident

すべての403をSecurity Incident扱いしない。

以下を重点Signalとする。

```text
Repeated Failure
Sensitive Endpoint
High Frequency
Abnormal Pattern
```

---

## 104. Sensitive Data

Security LogにもToken / Cookie / Password等を保存しない。

---

# Audit

## 105. Security-sensitive Audit

以下はAudit対象とする。

```text
Role Change
can_manage_permissions Change
Administrator Change
User Disable
Assignment Change
Employee Retire / Delete
Skill Deactivate
```

---

## 106. Audit Atomicity

既存方針通り、重要Business MutationとAudit Insertは同一Transactionで行う。

---

## 107. Audit != Security Log

```text
Security Log
    → Security Event / Detection

Audit Log
    → Who / When / What mutation
```

を分離する。

---

# Observability

## 108. Security Signal

Rate Limit / Authentication Failure / Authorization Failure等を必要に応じObservabilityへ連携する。

---

## 109. High Cardinality

Security Metricへ、

```text
user_id
employee_id
request_id
IP address
```

を無制限なMetric Labelとして利用しない。

Detailed InvestigationはLog / Traceを利用する。

---

# Security Testing

## 110. Automated Security Test

重要Security RequirementはFeature / Integration Testで保証する。

---

## 111. Authentication

最低限：

```text
No Token
    → 401

Invalid Token
    → 401

Expired / Revoked Token
    → 401
```

を確認する。

---

## 112. Authorization

最低限：

```text
Authenticated but unauthorized
    → 403
```

を確認する。

---

## 113. BOLA Test

Object Level Authorizationを重点的にTestする。

例：

```text
SubManager A
    ↓
Assigned Employee A
    → Allowed

SubManager A
    ↓
Unassigned Employee B
    → Denied
```

---

## 114. TeamLeader Test

```text
Assigned Employee Read
    → Allowed

Assigned Employee Write
    → Denied

Unassigned Employee Read
    → Denied
```

を確認する。

---

## 115. Permission Management Test

```text
Administrator
+
can_manage_permissions=true
    → Allowed

Administrator
+
can_manage_permissions=false
    → Denied
```

を確認する。

---

## 116. Last Administrator Test

最後のPermission Management可能Administratorを削除・降格できないことをConcurrency含め確認する。

---

# Property Security Test

## 117. Mass Assignment Test

Unexpected FieldでSecurity-sensitive Stateを変更できないことを確認する。

---

## 118. Response Exposure Test

API Responseへ以下が含まれないことを確認する。

```text
Password
Token
Session Secret
Internal Credential
Unexpected Internal Column
```

---

# Resource Security Test

## 119. Pagination

Maximum Page Sizeを超えるInputが制限されることを確認する。

---

## 120. Rate Limit

Rate Limit対象EndpointではLimit超過時に、

```text
429
```

が返ることを確認する。

---

## 121. Problem Details

Security Errorも既存RFC 9457 Contractへ従う。

内部情報がLeakしないことを確認する。

---

# OpenAPI Security

## 122. Bearer Security Scheme

OpenAPIではBackend AuthenticationをHTTP Bearer Schemeとして定義する。

概念：

```yaml
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
```

Sanctum内部Implementation DetailはAPI Contractにしない。

---

## 123. Error Contract

以下のResponseを必要に応じOpenAPIへ定義する。

```text
401
403
404
409
422
429
500
```

RFC 9457 Problem Detailsを利用する。

---

# API Inventory

## 124. OpenAPI First

OpenAPIをAPI ContractだけでなくAPI Inventoryとして利用する。

```text
OpenAPI
    → Known API Surface
```

---

## 125. Undocumented Endpoint

Productionへ不要な、

```text
Debug Route
Temporary Route
Forgotten Old Endpoint
Experimental Endpoint
```

を残さない。

---

## 126. API Version

既存方針通り、

```text
/api/v1
```

等の明示的Versioningを維持する。

Deprecated APIはLifecycleを管理する。

---

# Production Hardening

## 127. Production Configuration

Productionでは最低限：

```text
APP_ENV=production
APP_DEBUG=false
HTTPS
Xdebugなし
Debugbarなし
Development Routeなし
```

を保証する。

---

## 128. Telescope

Telescopeを将来導入してもProductionで無条件公開しない。

Authentication / Authorization / Environment Restrictionを必須とする。

MVPでは不採用。

---

## 129. Error Monitoring

Unexpected Errorの詳細はError Monitoring / Internal Telemetryへ送り、Clientへ直接返さない。

---

# Security Package Policy

## 130. Library追加原則

Securityという理由だけで外部Packageを増やさない。

優先順位：

```text
Laravel Standard
    ↓
Infrastructure / Platform Standard
    ↓
Established First-party / Standard Tool
    ↓
External Package
    ↓
Custom Implementation
```

---

## 131. Security Header Package

単純なSecurity Header設定だけのためにPackageを必須採用しない。

Middleware / Reverse Proxy / BFFで十分表現可能なら標準機能を利用する。

---

# Static Analysis / SAST

## 132. PHPStan

PHPStan / Larastanを利用するが、Security Scannerそのものとして扱わない。

---

## 133. Dedicated SAST

MVP開始時点では専用Commercial SASTを必須としない。

既存構成：

```text
PHPStan / Larastan
CleanCode + PHP_CodeSniffer
Architecture Test
Dependency Audit
Code Review
Security Test
```

をまず整える。

CleanCode + PHP_CodeSnifferは専用SASTとして利用するものではなく、Complexity / Maintainability Monitoringを担当する。

Security上の問題検出については、Static Analysis、Dependency Audit、Architecture Test、Security Test、Code Reviewを組み合わせて補完する。

---

## 134. Future SAST

必要性が高まった場合、

```text
GitHub CodeQL
Semgrep
```

等を候補として再検討する。

---

# CI Security

## 135. Security Check候補

CIでは以下を実行する。

```text
composer audit
Dependency Security Check
Secret Scanning
Container Image Scan
Security-relevant Tests
```

---

## 136. CI Responsibility

具体的Workflow / Job / Triggerは`16_CI・Automation.md`で定義する。

---

# Threat Reduction by Architecture

## 137. Clean Architectureとの関係

Clean Architecture自体はSecurity Mechanismではない。

ただし本Projectの、

```text
HTTP Input
    ↓
Form Request
    ↓
Command / Query
    ↓
Application
    ↓
Domain
    ↓
Repository / Mapper
```

というBoundaryはSecurityにも有効に働く。

---

## 138. Input Isolation

HTTP InputをEloquentへ直接渡さないことで、

```text
Mass Assignment
Unexpected Field Mutation
Framework Leakage
```

のRiskを低減する。

---

## 139. Output Isolation

Domain / Eloquentを直接Serializeしないことで、

```text
Sensitive Field Exposure
Internal Column Exposure
Unexpected Relationship Exposure
```

のRiskを低減する。

---

## 140. Authorization Isolation

AuthorizationをFrontendではなくBackend Policyへ置くことで、

```text
Client-side Bypass
Direct API Access
Object ID Manipulation
```

に対してSecurity Boundaryを維持する。

---

# 採用技術一覧

## 141. Adoption Matrix

| 項目 | 決定 |
|---|---|
| OWASP Top 10 | 基準として採用 |
| OWASP API Security Top 10 | 基準として採用 |
| OWASP ASVS | 基準として採用 |
| Better Auth + Redis + Sanctum | 現行方針を維持 |
| Sanctum Bearer Token | 採用 |
| BrowserへのSanctum Token公開 | 禁止 |
| Laravel Policy | Authorization Boundaryとして採用 |
| Object Level Authorization | 必須 |
| Function Level Authorization | 必須 |
| Property Level Security | 必須 |
| Explicit Input Mapping | 採用 |
| `$request->all()` → Model | 禁止 |
| Eloquent Direct Response | 禁止 |
| JsonResource | 採用済み |
| SQL Parameter Binding | 必須 |
| Dynamic Sort Allowlist | 必須 |
| Laravel Rate Limiting | 採用 |
| Rate Limit固定共通値 | 現時点では不採用 |
| Pagination Maximum | 採用 |
| Request Size Limit | 採用 |
| CORS Allowlist | 採用 |
| Production CORS `*` | 原則不採用 |
| Sanctum SPA Cookie Auth | 不採用 |
| Laravel API CSRF Cookie Flow | 不採用 |
| Browser CSRF Boundary | Next.js BFF |
| HTTPS | Staging / Production必須 |
| Trusted Proxy | 明示設定 |
| Security Headers | 採用 |
| CSP | 主にFrontend / BFF |
| HSTS | Production候補 |
| `APP_DEBUG=false` | Production必須 |
| Secret Git Commit | 禁止 |
| Secret Manager | Productionで採用 |
| `composer audit` | 採用 |
| Dependabot | 採用 |
| Secret Scanning | 採用 |
| Container Vulnerability Scan | 採用 |
| Trivy | 候補 |
| Production Xdebug | 禁止 |
| Multi-stage Build | 採用 |
| non-root Container | 推奨 |
| Minimal Runtime Image | 採用 |
| File Upload | MVP不採用 |
| Arbitrary URL Fetch | MVP不採用 |
| Security Logging | 採用済み |
| Security-sensitive Audit | 採用済み |
| BOLA Test | 必須 |
| Mass Assignment Test | 必須 |
| Response Exposure Test | 必須 |
| Dedicated Commercial SAST | MVP不採用 |
| CodeQL / Semgrep | 将来候補 |

---

# Final Security Architecture

## 142. Request Flow

```text
Client
    ↓ HTTPS
Next.js BFF
    ↓ Bearer Token
Laravel
    ↓
Authentication
    ↓
Rate Limit
    ↓
Form Request Validation
    ↓
Policy Authorization
    ↓
Command / Query
    ↓
Application Validation
    ↓
Domain Invariant
    ↓
Repository
    ↓
PostgreSQL Constraint
```

---

## 143. Response Flow

```text
PostgreSQL / Domain / Read Model
    ↓
Application Result
    ↓
JsonResource
    ↓
Explicit JSON
    ↓
BFF
    ↓
Browser
```

Internal Modelを直接External APIへExposeしない。

---

## 144. Detection Flow

```text
Security Event
    ├── Security Log
    ├── Audit Log
    ├── Metrics / Traces
    └── Error Monitoring
```

目的に応じて適切なChannelへ記録する。

---

# 最終方針

## 145. Defense in Depth

Backend Securityは、

```text
Authentication
+
Authorization
+
Validation
+
Explicit Mapping
+
Database Integrity
+
Rate Limiting
+
Output Control
+
Secret Management
+
Runtime Hardening
+
Security Monitoring
+
Security Testing
```

による多層防御とする。

---

## 146. Authorization

特に本ProjectではEmployee単位の担当関係があるため、

```text
Authentication成功
    ≠
Access許可
```

を徹底する。

すべてのSecurity-sensitive Endpointで、

```text
Who
    ↓
What Operation
    ↓
Which Target
```

を確認する。

---

## 147. Input / Output Boundary

Security上の重要原則として、

```text
HTTP Input
    ≠
Eloquent Attribute
```

および、

```text
Eloquent / Domain Object
    ≠
API Response
```

を維持する。

InputはCommand / Queryへ明示Mappingし、OutputはJsonResourceへ明示Mappingする。

---

## 148. Resource Protection

APIを無制限に利用できる設計にしない。

```text
Rate Limit
Pagination Limit
Request Size Limit
Query Allowlist
Timeout
```

を利用してResource Consumptionを制御する。

---

## 149. Supply Chain

Application Codeだけでなく、

```text
Composer Dependency
Container Image
Repository Secret
GitHub Actions
```

もSecurity Scopeに含める。

---

## 150. Production

ProductionはDevelopment Environmentと明確に分離する。

```text
No Debug
No Xdebug
No Development Tool
No Development Route
Minimal Runtime
HTTPS
Managed Secrets
```

を基本とする。

---

## 151. Security Testing

Security RequirementはDocumentationだけで完了させない。

特に、

```text
Object Level Authorization
Role / Assignment Authorization
Permission Management
Mass Assignment
Sensitive Field Exposure
Rate Limiting
Authentication Failure
```

をAutomated Testで継続的に保証する。

---

## 152. 最重要原則

本ProjectのBackend Securityでは、

> 信頼境界を明示し、各Boundaryで必要なValidation・Authorization・Serializationを実施する

ことを最重要原則とする。

最終的に、

```text
Browser
    ↓
BFF Security Boundary
    ↓
Bearer Authentication
    ↓
Laravel Authorization Boundary
    ↓
Application / Domain Boundary
    ↓
Persistence Boundary
    ↓
Database Integrity
```

という複数のDefense Layerによって、単一MechanismのFailureが即Application全体のSecurity Failureにならない構成を採用する。
