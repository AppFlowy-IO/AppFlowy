# Provides a test suite for functions and triggers of sql schema

## Requirements
- The following environmental variables needs to be set
```
POSTGRES_DB=somedb
POSTGRES_PORT=5432
POSTGRES_HOST=localhost
POSTGRES_PASSWORD=supersecretpassword
POSTGRES_USER=someuser
```
- psql needs to be installed
- Migrations scripts have to run before this

## Commands Scripts
```
# check env and installed binaries in path
./check

# check creation of workspace upon user creation
./af_user
```
