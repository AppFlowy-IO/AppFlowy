#!/bin/bash
set -u
set -e

# You can either set the NDK path here or in your .zshrc, .profile, .bashrc

# Check if rust targets are installed
rustup target add \
aarch64-linux-android \
armv7-linux-androideabi \
i686-linux-android \
x86_64-linux-android

NDK=$ANDROID_NDK_HOME

export TOOLCHAIN_PATH=$NDK/bin
export NDK_TOOLCHAIN_BASENAME=${TOOLCHAIN_PATH}
export SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
export DIR=$(realpath ${DIR:-$(pwd)})
export PREFIX=$DIR/prefix
export ANDROID_API=29
export OPENSSL_BRANCH=OpenSSL_1_1_1-stable

# The linker and clang are defined in ~/.cargo/config

ARM7=armv7-linux-androideabi
AARCH64=aarch64-linux-android
X86=i686-linux-android
X86_64=x86_64-linux-android
DEST=$(realpath ${DIR:-../app_flowy/android/app/src/main/jniLibs})
SSL=$(pwd)/prefix

function targetBuild(){
if [ ! -d $DEST  ]; then
    mkdir $DEST/armeabi-v7a $DEST/x86_64 $DEST/x86 $DEST/arm64-v8a
else
    echo "Android Folders exist, building SDK"
fi

OPENSSL_DIR=$SSL/armeabi-v7a/ cargo ndk --target armeabi-v7a build --release

OPENSSL_DIR=$SSL/arm64-v8a/ cargo ndk --target arm64-v8a build --release

OPENSSL_DIR=$SSL/x86/ cargo ndk --target x86 build --release

Build for x86_64 arch
OPENSSL_DIR=$SSL/x86_64/ cargo ndk --target x86_64 build --release

# Move targets to android folder
mv -b target/$ARM7/release/libdart_ffi.so $DEST/armeabi-v7a
mv -b target/$AARCH64/release/libdart_ffi.so $DEST/arm64-v8a
mv -b target/$X86/release/libdart_ffi.so $DEST/x86
mv -b target/$X86_64/release/libdart_ffi.so $DEST/x86_64
}

function buildSSL(){

    ./Configure shared android-arm -D__ANDROID_API__=$ANDROID_API \
        --prefix=$PREFIX/armeabi-v7a \
        --with-zlib-include=$SYSROOT/usr/include \
        --with-zlib-lib=$SYSROOT/usr/lib \
        zlib \
        no-comp \
        no-asm \
        no-shared \
        no-unit-test
    make clean
    make depend
    make -j$(nproc) build_libs
    make -j$(nproc) install_sw

    ./Configure shared android-arm64 -D__ANDROID_API__=$ANDROID_API \
        --prefix=$PREFIX/arm64-v8a \
        --with-zlib-include=$SYSROOT/usr/include \
        --with-zlib-lib=$SYSROOT/usr/lib \
        zlib \
        no-comp \
        no-asm \
        no-shared \
        no-unit-test
    make clean
    make depend
    make -j$(nproc) build_libs
    make -j$(nproc) install_sw

    ./Configure shared android-x86 -D__ANDROID_API__=$ANDROID_API \
        --prefix=$PREFIX/x86 \
        --with-zlib-include=$SYSROOT/usr/include \
        --with-zlib-lib=$SYSROOT/usr/lib \
        zlib \
        no-comp \
        no-asm \
        no-shared \
        no-unit-test
    make clean
    make depend
    make -j$(nproc) build_libs
    make -j$(nproc) install_sw

    ./Configure shared android-x86_64 -D__ANDROID_API__=$ANDROID_API \
        --prefix=$PREFIX/x86_64 \
        --with-zlib-include=$SYSROOT/usr/include \
        --with-zlib-lib=$SYSROOT/usr/lib \
        zlib \
        no-comp \
        no-asm \
        no-shared \
        no-unit-test
    make clean
    make depend
    make -j$(nproc) build_libs
    make -j$(nproc) install_sw
}

function getOpenSLL(){
mkdir -p $PREFIX

cd $DIR
if [ ! -d openssl ]; then
    git clone --depth 1 git://git.openssl.org/openssl.git --branch $OPENSSL_BRANCH
fi
cd openssl
echo "Building OpenSSL in $(realpath $PWD), building in $PREFIX"

export PATH=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH

buildSSL

cd ../
targetBuild
}

if [ -d $PREFIX ]; then
    echo "Folder exists, remove $PREFIX to rebuild"
    echo "Skipping OpenSSL build, building rust library..."
    targetBuild
else
    getOpenSLL
fi

