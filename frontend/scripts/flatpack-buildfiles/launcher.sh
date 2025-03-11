#!/usr/bin/env bash
gdbus call --session --dest io.appflowy.AppFlowy \
    --object-path /io/appflowy/AppFlowy/Object \
    --method io.appflowy.AppFlowy.Open "['$1']" {}
