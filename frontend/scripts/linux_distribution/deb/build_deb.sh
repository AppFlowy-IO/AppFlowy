#!/bin/bash

LINUX_RELEASE_PRODUCTION=$1
VERSION=$2
PACKAGE_NAME=$3

# Define package folders
PACKAGE=$LINUX_RELEASE_PRODUCTION/package
LIB=$PACKAGE/usr/lib
APPLICATIONS=$PACKAGE/usr/share/applications
DBUS_SERVICES=$PACKAGE/usr/share/dbus-1/services
ICONS=$PACKAGE/usr/share/icons/hicolor/scalable/apps
METAINFO=$PACKAGE/usr/share/metainfo
DEBIAN=$PACKAGE/DEBIAN

# Create package folder
mkdir -p $LIB
mkdir -p $APPLICATIONS
mkdir -p $DBUS_SERVICES
mkdir -p $ICONS
mkdir -p $METAINFO
mkdir -p $DEBIAN

# Configure the package
cp -R ./scripts/linux_distribution/deb/DEBIAN $PACKAGE
chmod 0755 $DEBIAN/postinst
chmod 0755 $DEBIAN/postrm
grep -rl "\[CHANGE_THIS\]" $DEBIAN/control | xargs sed -i "s/\[CHANGE_THIS\]/$VERSION/"

cp -fR $LINUX_RELEASE_PRODUCTION/AppFlowy $LIB
cp ./scripts/linux_distribution/packaging/launcher.sh $LIB/AppFlowy
chmod +x $LIB/AppFlowy/launcher.sh

cp ./scripts/linux_distribution/deb/AppFlowy.desktop $APPLICATIONS
cp ./scripts/linux_distribution/packaging/io.appflowy.AppFlowy.launcher.desktop $APPLICATIONS

cp ./scripts/linux_distribution/packaging/io.appflowy.AppFlowy.metainfo.xml $METAINFO
cp ./scripts/linux_distribution/packaging/io.appflowy.AppFlowy.service $DBUS_SERVICES
cp ./scripts/linux_distribution/packaging/appflowy.svg $ICONS

# Build the package
dpkg-deb --build --root-owner-group -Z xz $PACKAGE $LINUX_RELEASE_PRODUCTION/$PACKAGE_NAME
