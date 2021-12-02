#!/bin/bash

export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=password
export POSTGRES_PORT=5433
export POSTGRES_HOST=localhost
export POSTGRES_DB=flowy

export DB_USER="${POSTGRES_USER:=postgres}"
export DB_PASSWORD="${POSTGRES_PASSWORD:=password}"
export DB_PORT="${POSTGRES_PORT:=5433}"
export DB_HOST="${POSTGRES_HOST:=localhost}"
export DB_NAME="${POSTGRES_DB:=flowy}"

export BACKEND_VERSION="v0.0.1"
export DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}