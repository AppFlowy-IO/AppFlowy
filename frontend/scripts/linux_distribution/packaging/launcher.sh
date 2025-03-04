#!/usr/bin/env bash
gdbus call --session --dest io.appflowy.appflowy \
    --object-path /io/appflowy/appflowy/Object \
    --method io.appflowy.appflowy.Open "['$1']" {}
