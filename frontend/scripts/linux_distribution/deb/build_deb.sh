#!/bin/bash

LINUX_RELEASE_PRODUCTION=$1
VERSION=$2
PACKAGE_NAME=$3

rm -rf package

# create package folder
mkdir -p package/usr/lib
mkdir -p package/usr/share/applications
mkdir -p package/usr/share/dbus-1/services
mkdir -p package/usr/share/icons/hicolor/scalable/apps
mkdir -p package/usr/share/metainfo
mkdir -p package/DEBIAN

# Configure the package
cp -R ./scripts/linux_distribution/deb/DEBIAN package
chmod 0755 package/DEBIAN/postinst
chmod 0755 package/DEBIAN/postrm
grep -rl "\[CHANGE_THIS\]" package/DEBIAN/control | xargs sed -i "s/\[CHANGE_THIS\]/$VERSION/"

cp -fR $LINUX_RELEASE_PRODUCTION/AppFlowy package/usr/lib
cp ./scripts/linux_distribution/packaging/launcher.sh package/usr/lib/AppFlowy

cp ./scripts/linux_distribution/deb/AppFlowy.desktop package/usr/share/applications
cp ./scripts/linux_distribution/packaging/io.appflowy.AppFlowy.launcher.desktop package/usr/share/applications

cp ./scripts/linux_distribution/packaging/io.appflowy.AppFlowy.metainfo.xml package/usr/share/metainfo
cp ./scripts/linux_distribution/packaging/io.appflowy.AppFlowy.service package/usr/share/dbus-1/services
cp ./scripts/linux_distribution/packaging/appflowy.svg package/usr/share/icons/hicolor/scalable/apps

# Build the package
dpkg-deb --build --root-owner-group -Z xz package $PACKAGE_NAME
