#!/bin/bash

VERSION=$1

# update version
grep -rl "\[CHANGE_THIS\]" scripts/linux_distribution/appimage/AppImageBuilder.yml | xargs sed -i "s/\[CHANGE_THIS\]/$VERSION/"

appimage-builder --recipe scripts/linux_distribution/appimage/AppImageBuilder.yml
