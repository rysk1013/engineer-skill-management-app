# OpenAPI 運用方式 決定事項

## ファイル構成

- OpenAPIは複数ファイルで管理する
- `openapi.yaml` をEntry Pointとする
- PathsはResource単位で分割する
- Schemaは再利用可能な単位で分割する

## Next.js

- OpenAPIからTypeScript型を生成する
- API Client自体は自動生成しない
- BFF側に薄いAPI Clientを実装する

## Generated Code

- 自動生成されたTypeScript型は直接編集しない
- API仕様変更時はOpenAPIを変更して再生成する

## API変更フロー

    User Story / Acceptance Criteria
                ↓
           OpenAPI変更
                ↓
           API Review
                ↓
         OpenAPI Validation
                ↓
        TypeScript型生成
           ↙          ↘
    Next.js BFF      Laravel API
           ↘          ↙
              Test

## 基本方針

- OpenAPIをAPI ContractのSource of Truthとする
- Laravel実装を先に変更しない
- Frontend / Backendの型定義を重複させない
- Laravel内部構造をAPI Contractへ露出させない
- OpenAPI仕様自体もCIで検証する
