#!/usr/bin/env bash
set -x
set -eo pipefail

#if [[ -z "${RESET}" ]]
#then
#  docker stop flowy
#  docker rm flowy
#fi

if [[ -z "${SKIP_DOCKER}" ]]
then
  docker run \
      --name="flowy" \
      -e POSTGRES_USER=${DB_USER} \
      -e POSTGRES_PASSWORD=${DB_PASSWORD} \
      -e POSTGRES_DB=${DB_NAME} \
      -p "${DB_PORT}":5432 \
      -d postgres \
      postgres -N 1000
fi
  # ^ Increased maximum number of connections for testing purposes