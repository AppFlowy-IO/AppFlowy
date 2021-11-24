#!/bin/bash

[ -d "shared-libs/" ] && exit 0

rm -rf *

apt-get update -y \
&& apt-get install -y --no-install-recommends git \
&& apt-get autoremove -y \
&& apt-get clean -y \
&& rm -rf /var/lib/apt/lists/*

git clone -q https://github.com/AppFlowy-IO/appflowy.git .

printf "At commit @%s\n" $(git log -n 1 --pretty=format:"%H")
