#!/usr/bin/env bash
set -x
set -eo pipefail

if ! [ -x "$(command -v psql)" ]; then
  echo >&2 "Error: `psql` is not installed."
  echo >&2 "install using brew: brew install libpq."
  echo >&2 "link to /usr/local/bin: brew link --force libpq ail"

  exit 1
fi

if ! [ -x "$(command -v sqlx)" ]; then
  echo >&2 "Error: `sqlx` is not installed."
  echo >&2 "Use:"
  echo >&2 "    cargo install --version=^0.5.6 sqlx-cli --no-default-features --features postgres"
  echo >&2 "to install it."
  exit 1
fi

until psql -h "localhost" -U "${DB_USER}" -p "${DB_PORT}" -d "postgres" -c '\q';
do
  >&2 echo "Postgres is still unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up and running on port ${DB_PORT}!"
sqlx database create
