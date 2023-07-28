#!/bin/env bash

trim() {
    local var="$*"
    # Remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PSQL="psql \
    --host=$PGHOST \
    --username=$PGUSER \
    --dbname=$PGDB \
    --port=$PGPORT \
"
