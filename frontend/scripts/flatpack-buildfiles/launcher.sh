#!/usr/bin/env bash
gdbus call --session --dest io.appflowy.appflowy \
    --object-path /io/appflowy/AppFlowy/Object \
    --method io.appflowy.appflowy.Open "['$1']" {}
