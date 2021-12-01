#!/bin/bash

export DB_USER="${POSTGRES_USER:=postgres}"
export DB_PASSWORD="${POSTGRES_PASSWORD:=password}"
export DB_PORT="${POSTGRES_PORT:=5433}"
export DB_HOST="${POSTGRES_HOST:=localhost}"
export DB_NAME="${POSTGRES_DB:=flowy}"

export DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}