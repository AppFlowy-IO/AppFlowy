#!/bin/bash
set -u
set -e

# You can either set the NDK path here or in your .zshrc, .profile, .bashrc

NDK=$ANDROID_NDK_HOME

export TOOLCHAIN_PATH=$NDK/bin
export NDK_TOOLCHAIN_BASENAME=${TOOLCHAIN_PATH}
export SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
#export CC=clang
#export AR=llvm-ar
export BUILD_ARCHS=${BUILD_ARCHS:-arm_32 arm_64}
export DIR=$(realpath ${DIR:-$(pwd)})
export PREFIX=$DIR/prefix
export ANDROID_API=29
export OPENSSL_BRANCH=OpenSSL_1_1_1-stable

# The linker and clang are defined in ~/.cargo/config

ARM7=armv7-linux-androideabi
AARCH64=aarch64-linux-android
X86=i686-linux-android
X86_64=x86_64-linux-android
DEST=../app_flowy/android/app/src/main/jniLibs
SSL=$(pwd)/prefix

function targetBuild(){
if [ ! -d $DEST/armeabi-v7a && $DEST/x86_64 && $DEST/x86 && $DEST/arm64-v8a ]; then
    mkdir $DEST/armeabi-v7a $DEST/x86_64 $DEST/x86 $DEST/arm64-v8a
fi

# Script to modify faccess-0.2.3/src/lib.rs 95:36

# Needs const to be i8 in lib.rs for faccessat
# Build for arm7 arch
OPENSSL_DIR=$SSL/armeabi-v7a/ cargo ndk --target armeabi-v7a build --release

# Needs const to be u8 in lib.rs for faccessat
# Build for arm64-v8a arch
OPENSSL_DIR=$SSL/arm64-v8a/ cargo ndk --target arm64-v8a build --release

# Needs const to be i8 in lib.rs for faccessat
# Build for x86 arch
OPENSSL_DIR=$SSL/x86/ cargo ndk --target x86 build --release

# Needs const to be i8 in lib.rs for faccessat
# Build for x86_64 arch
OPENSSL_DIR=$SSL/x86_64/ cargo ndk --target x86_64 build --release

# Copy targets to android folder
cp -b target/$ARM7/release/libdart_ffi.so $DEST/armeabi-v7a
cp -b target/$AARCH64/release/libdart_ffi.so $DEST/arm64-v8a
cp -b target/$X86/release/libdart_ffi.so $DEST/x86
cp -b target/$X86_64/release/libdart_ffi.so $DEST/x86_64
}


if [ -d $PREFIX ]; then
    echo "Folder exists, remove $PREFIX to rebuild"
    targetBuild
    #exit 1
fi

mkdir -p $PREFIX

cd $DIR
if [ ! -d openssl ]; then
    git clone --depth 1 git://git.openssl.org/openssl.git --branch $OPENSSL_BRANCH
fi


cd openssl
echo "Building OpenSSL in $(realpath $PWD), building in $PREFIX"

export PATH=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH

function buildSSL(){
#if [[ "$BUILD_ARCHS" = *"arm_32"* ]]; then
    ./Configure shared android-arm -D__ANDROID_API__=$ANDROID_API \
        --prefix=$PREFIX/armeabi-v7a \
        --with-zlib-include=$SYSROOT/usr/include \
        --with-zlib-lib=$SYSROOT/usr/lib \
        zlib \
        no-asm \
        no-shared \
        no-unit-test
    make clean
    make depend
    make -j$(nproc) build_libs
    make -j$(nproc) install_sw
#fi


#if [[ "$BUILD_ARCHS" = *"arm_64"* ]]; then
    ./Configure shared android-arm64 -D__ANDROID_API__=$ANDROID_API \
        --prefix=$PREFIX/arm64-v8a \
        --with-zlib-include=$SYSROOT/usr/include \
        --with-zlib-lib=$SYSROOT/usr/lib \
        zlib \
        no-asm \
        no-shared \
        no-unit-test
    make clean
    make depend
    make -j$(nproc) build_libs
    make -j$(nproc) install_sw
#fi

#if [[ "$BUILD_ARCHS" = *"x86_32"* ]]; then
    ./Configure shared android-x86 -D__ANDROID_API__=$ANDROID_API \
        --prefix=$PREFIX/x86 \
        --with-zlib-include=$SYSROOT/usr/include \
        --with-zlib-lib=$SYSROOT/usr/lib \
        zlib \
        no-asm \
        no-shared \
        no-unit-test
    make clean
    make depend
    make -j$(nproc) build_libs
    make -j$(nproc) install_sw
#fi

#if [[ "$BUILD_ARCHS" = *"x64_64"* ]]; then
    ./Configure shared android-x86_64 -D__ANDROID_API__=$ANDROID_API \
        --prefix=$PREFIX/x86_64 \
        --with-zlib-include=$SYSROOT/usr/include \
        --with-zlib-lib=$SYSROOT/usr/lib \
        zlib \
        no-asm \
        no-shared \
        no-unit-test
    make clean
    make depend
    make -j$(nproc) build_libs
    make -j$(nproc) install_sw
#fi
}
buildSSL
# Exit folder and begin build?
cd ../

# TODO: Run openssl build in same folder








