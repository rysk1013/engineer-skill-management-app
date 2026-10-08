.DEFAULT_GOAL := help

COMPOSE := docker compose --env-file .env -f compose.yaml

.PHONY: \
	help \
	dev-setup dev-up dev-down dev-reset \
	prod-build prod-up prod-down \
	frontend-lint frontend-typecheck frontend-format \
	frontend-format-check frontend-quality frontend-test frontend-build \
	backend-lint backend-analyse backend-format backend-quality \
	backend-test backend-test-unit backend-test-integration backend-test-feature \
	openapi-lint openapi-generate openapi-check \
	test-db-up quality test smoke-test

# ==================================================
# Help
# ==================================================

help:
	@printf '\nUsage: make <target>\n\n'
	@printf 'Development:\n'
	@printf '  dev-setup                Setup development environment\n'
	@printf '  dev-up                   Start development containers\n'
	@printf '  dev-down                 Stop development containers\n'
	@printf '  dev-reset                Reset development environment (DELETES VOLUMES)\n'
	@printf '\nProduction:\n'
	@printf '  prod-build               Build production images\n'
	@printf '  prod-up                  Start production containers\n'
	@printf '  prod-down                Stop production containers\n'
	@printf '\nFrontend:\n'
	@printf '  frontend-lint            Run ESLint\n'
	@printf '  frontend-typecheck       Run TypeScript type check\n'
	@printf '  frontend-format          Format frontend files\n'
	@printf '  frontend-format-check    Check frontend formatting\n'
	@printf '  frontend-quality         Run frontend quality checks\n'
	@printf '  frontend-test            Run frontend tests\n'
	@printf '  frontend-build           Build frontend application\n'
	@printf '\nBackend:\n'
	@printf '  backend-lint             Run Laravel Pint check\n'
	@printf '  backend-analyse          Run PHPStan analysis\n'
	@printf '  backend-format           Format backend files\n'
	@printf '  backend-quality          Run backend quality checks\n'
	@printf '  backend-test             Run backend tests\n'
	@printf '  backend-test-unit        Run backend unit tests\n'
	@printf '  backend-test-integration Run backend integration tests\n'
	@printf '  backend-test-feature     Run backend feature tests\n'
	@printf '\nOpenAPI:\n'
	@printf '  openapi-lint             Run OpenAPI lint\n'
	@printf '  openapi-generate         Generate OpenAPI schema and types\n'
	@printf '  openapi-check            Run OpenAPI validation and generation\n'
	@printf '\nCommon:\n'
	@printf '  quality                  Run all quality checks\n'
	@printf '  test                     Run all tests\n'
	@printf '  smoke-test               Run smoke test\n'
	@printf '\n'

# ==================================================
# Development
# ==================================================

dev-setup:
	./scripts/dev-setup.sh

dev-up:
	./scripts/dev-up.sh

dev-down:
	./scripts/dev-down.sh

dev-reset:
	./scripts/dev-reset.sh

# ==================================================
# Production
# ==================================================

prod-build:
	./scripts/prod-build.sh

prod-up:
	./scripts/prod-up.sh

prod-down:
	./scripts/prod-down.sh

# ==================================================
# Frontend
# ==================================================

frontend-lint:
	$(COMPOSE) exec -T frontend pnpm lint

frontend-typecheck:
	$(COMPOSE) exec -T frontend pnpm typecheck

frontend-format:
	$(COMPOSE) exec -T frontend pnpm format

frontend-format-check:
	$(COMPOSE) exec -T frontend pnpm format:check

frontend-quality:
	$(COMPOSE) exec -T frontend pnpm quality

frontend-test:
	$(COMPOSE) exec -T frontend pnpm test

frontend-build:
	$(COMPOSE) exec -T frontend pnpm build

# ==================================================
# Backend
# ==================================================

backend-lint:
	$(COMPOSE) exec -T backend composer lint

backend-analyse:
	$(COMPOSE) exec -T backend composer analyse

backend-format:
	$(COMPOSE) exec -T backend composer format

backend-quality:
	$(COMPOSE) exec -T backend composer quality

test-db-up:
	$(COMPOSE) up -d --wait test-db

backend-test: test-db-up
	$(COMPOSE) exec -T backend composer test

backend-test-unit: test-db-up
	$(COMPOSE) exec -T backend composer test:unit

backend-test-integration: test-db-up
	$(COMPOSE) exec -T backend composer test:integration

backend-test-feature: test-db-up
	$(COMPOSE) exec -T backend composer test:feature

# ==================================================
# OpenAPI
# ==================================================

openapi-lint:
	$(COMPOSE) run --rm openapi pnpm lint

openapi-generate:
	$(COMPOSE) run --rm openapi pnpm generate

openapi-check:
	$(COMPOSE) run --rm openapi pnpm check

# ==================================================
# Common
# ==================================================

quality:
	$(MAKE) frontend-format-check
	$(MAKE) frontend-quality
	$(MAKE) backend-quality
	$(MAKE) openapi-check

test:
	$(MAKE) frontend-test
	$(MAKE) backend-test

smoke-test:
	./scripts/smoke-test.sh
