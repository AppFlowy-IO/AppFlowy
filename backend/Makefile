ROOT = "./scripts"

.PHONY:  init_database  add_migrations run_migrations reset_db

init_database:
	${ROOT}/init_database.sh

run_docker:
	source $(ROOT)/env.sh && docker-compose up -d db
	source $(ROOT)/env.sh && docker-compose up -d backend
	source $(ROOT)/env.sh && docker-compose logs backend

reset_db:
	#diesel database reset
	sqlx database reset

add_migrations:
	#make table="the name of your table" add_migrations
	# diesel migration generation $(table)
	sqlx migrate add $(table)

run_migrations:
	# diesel migration run
	sqlx migrate run


