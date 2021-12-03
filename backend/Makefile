ROOT = "./scripts"
SEMVER_VERSION=$(shell grep version Cargo.toml | awk -F"\"" '{print $$2}' | head -n 1)

.PHONY: init_database run_docker run_test

init_database:
	POSTGRES_PORT=5433 ${ROOT}/init_database.sh

docker_image:
	source $(ROOT)/docker_env.sh && docker-compose up -d db
	source $(ROOT)/docker_env.sh && docker-compose up -d backend

docker_test:
	sh $(ROOT)/docker_test.sh

local_test:
	# 🔥 Must run init_database first
	 SQLX_OFFLINE=true cargo test


