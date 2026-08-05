.PHONY: setup dev stop clean test lint typecheck build security-scan logs db-migrate db-reset-local

setup:
	@echo "[GUFFSUFF] Installing monorepo dependencies..."
	pnpm install --frozen-lockfile

dev:
	@echo "[GUFFSUFF] Starting local development services..."
	docker compose up -d postgres redis minio
	pnpm dev

stop:
	@echo "[GUFFSUFF] Stopping local Docker containers..."
	docker compose down

clean:
	@echo "[GUFFSUFF] Cleaning build artifacts and cache..."
	pnpm exec turbo clean || true
	rm -rf node_modules apps/*/node_modules services/*/node_modules packages/*/node_modules

test:
	pnpm test

lint:
	pnpm lint

typecheck:
	pnpm typecheck

build:
	pnpm build

security-scan:
	pnpm security:scan

logs:
	docker compose logs -f

db-migrate:
	pnpm --filter @guffsuff/database migrate

db-reset-local:
	@if [ "$$(git config --get user.name)" = "" ]; then echo "Invalid environment"; exit 1; fi
	@echo "WARNING: Resetting local development database!"
	pnpm --filter @guffsuff/database db:reset:local
