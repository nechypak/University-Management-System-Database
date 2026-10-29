.DEFAULT_GOAL := help
PSQL = docker compose exec -T db psql -X -v ON_ERROR_STOP=1 -U university -d university_db

.PHONY: help up down setup migrate seed test queries shell
help:
	@echo 'make setup   Start PostgreSQL and load a new demo database (once)'
	@echo 'make migrate Apply pending schema migrations; safe to repeat'
	@echo 'make test    Check constraints, upgrade path and all example queries'
	@echo 'make shell   Open psql'
	@echo 'make down    Stop PostgreSQL; keep data'
up:
	docker compose up -d --wait
down:
	docker compose down
setup: up migrate seed
migrate:
	$(PSQL) -f /workspace/db/migrate.sql
seed:
	$(PSQL) -f /workspace/db/seeds/demo.sql
test:
	$(PSQL) -f /workspace/tests/integrity.sql
	$(PSQL) -f /workspace/tests/upgrade.sql
	$(MAKE) queries
queries:
	@for query in queries/*.sql; do \
		echo "Running $$query"; \
		$(PSQL) -f "/workspace/$$query" || exit 1; \
	done
shell:
	docker compose exec db psql -X -U university -d university_db
