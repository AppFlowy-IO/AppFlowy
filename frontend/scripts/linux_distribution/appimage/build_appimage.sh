#!/bin/bash

VERSION=$1

# if the appimage-builder not exist, download it
if [ ! -e /usr/local/bin/appimage-builder ]; then
    wget -O appimage-builder-x86_64.AppImage https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.1.0/appimage-builder-1.1.0-x86_64.AppImage
    chmod +x appimage-builder-x86_64.AppImage

    # install (optional)
    sudo mv appimage-builder-x86_64.AppImage /usr/local/bin/appimage-builder
fi


# update version
grep -rl "\[CHANGE_THIS\]" scripts/linux_distribution/appimage/AppImageBuilder.yml | xargs sed -i "s/\[CHANGE_THIS\]/$VERSION/"

appimage-builder --recipe scripts/linux_distribution/appimage/AppImageBuilder.yml --skip-tests
