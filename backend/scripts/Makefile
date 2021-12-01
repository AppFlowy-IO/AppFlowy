#.EXPORT_ALL_VARIABLES:
#export DB_USER=postgres
#export DB_PASSWORD=password
#export DB_NAME=flowy
#export DB_PORT=5433
#export DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}
#export DB_HOST = "localhost"

init_database:
	${ROOT}/init_database.sh

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

echo_db_url:
	echo ${DATABASE_URL}

