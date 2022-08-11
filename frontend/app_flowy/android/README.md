# Description

This is a guide on how to build the rust SDK for AppFlowy on android.
Compiling the sdk is easy it just needs a few tweaks.
When compiling for android we need the following pre-requisites:

- Android NDK Tools. (v24 has been tested).
- Cargo NDK. (@latest version).
- The rust targets.
- Openssl Library.

The most important crate or library is the OpenSSL one.
Failing to compile that will break the rest of the build.
Just a reminder the openssl for desktop wont apply to the one on mobile trust me.

## How to build the SDK

To start with you will need openssl from the source in order to compile it.
There are many pre-compiled openssl libraries, but it's best to build it from source.

There's a script in the folder 'appflowy/frontend/rust-lib/build_android_sdk.sh'
The script will make it easier to build the whole SDK. It can clone openssl
but it won't download the Android NDK.

**Getting the tools**
- Install cargo-ndk ```bash cargo install cargo-ndk```.
- [Download](https://developer.android.com/ndk/downloads/) Android NDK version 24.
- Then clone openssl using git.

## Building Openssl

To compile openssl you need a few things to get started.
- The source code from openssl **The genuine one**. You can clone it via git
```bash
git clone https://github.com/openssl/openssl.git
```

- When downloading Android NDK you can get the compressed version as a standalone from the site.
    Or you can download it through [Android Studio](https://developer.android.com/studio).
- After downloading the two you need to set the environment variables. For Windows that's a seperate process.
    On MacOs and Linux the process is similar.
- The variables needed are '$ANDROID_NDK_HOME', this will point to where the NDK is located.
- You can try run the script which should take care of most of the things and build them accordingly.
- **NB:** Building the Openssl library has been tested in Linux & Mac, it is has not been tested on Windows since a shell hasnt been determined for it.

---

**Install rustup targets**

 To build the SDK for rust we need to install the targets to work with cargo-ndk.
 ```bash
 rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
 ```
\
**Cargo Config File**
This code needs to be written in ~/.cargo/config, this helps cargo know where to locate the android tools(linker and archiver).
**NB** Keep in mind just replace 'user' with your own user name. Or just point it to the location of where you put the NDK.

```toml
[target.aarch64-linux-android]
ar = "/home/user/Android/Sdk/ndk/24.0.8215888/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "/home/user/Android/Sdk/ndk/24.0.8215888/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android29-clang"

[target.armv7-linux-androideabi]
ar = "/home/user/Android/Sdk/ndk/24.0.8215888/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "/home/user/Android/Sdk/ndk/24.0.8215888/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi29-clang"

[target.i686-linux-android]
ar = "/home/user/Android/Sdk/ndk/24.0.8215888/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "/home/user/Android/Sdk/ndk/24.0.8215888/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android29-clang"

[target.x86_64-linux-android]
ar = "/home/user/Android/Sdk/ndk/24.0.8215888/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
linker = "/home/user/Android/Sdk/ndk/24.0.8215888/toolchains/llvm/prebuilt/linux-x86_64/bin/x86_64-linux-android29-clang"
```

**Clang Fix**
 In order to get clang to work properly with version 24 you need to create this file.
 libgcc.a, then add this one line.
 ```
 INPUT(-lunwind)
 ```

**Folder path: 'Android/Sdk/ndk/24.0.8215888/toolchains/llvm/prebuilt/linux-x86_64/lib64/clang/14.0.1/lib/linux'.**
After that you have to copy this file into three different folders namely aarch64, arm, i386 and x86_64.
We have to do this so we Android NDK can find clang on our system, if we used NDK 22 we wouldnt have to do this process.
Though using NDK v22 will not give us alot of features to work with.
This github [issue](https://github.com/fzyzcjy/flutter_rust_bridge/issues/419) explains the reason why we are doing this.

 ---


 **Android NDK**

 After installing the NDK tools for android you should export the PATH to your config file
 (.vimrc, .zshrc, .profile, .bashrc file), That way it can be found.

 ```vim
 export PATH=/home/sean/Android/Sdk/ndk/24.0.8215888
 ```

 ---

 ## Building the library

 **NB:** To properly build the libdart_ffi.so file for android the crate-type must be "cdylib".
 You would need to change it in 'rust-lib/dart-ffi/Cargo.toml'
If we don't change it this will build the rust SDK but not with the extension '.so'.

## Running AppFlowy on android

When running AppFlowy on android, we need the rust SDK. Without it the app wont display anything but a white screen.
The above script is meant to copy the libraries to the respective folders.
It might happen or might not happen since the script is not perfect, there are some lines that could fail or get jumped.

So to be safe you would need to copy the files manually.
For example:
**Source Files:** 'target//armv7-linux-androideabi/release/libdart_ffi.so'

**Target:** 'app_flowy/android/app/src/main/jniLibs/armeabi-v7a'

To make it easier the list below shows which rust folder matches the one on android.

|Rust Folder | Android Folder|
|-------|:------|
|armv7-linux-androideabi | armeabi-v7a.
|i686-linux-android | x86.
|x86_64-linux-android | x86_64.
|aarch64-linux-android | arm64-v8a.

\
There are multiple individual files, that needed to be updated and corrected in order to even get the app to run on android.
They are incomplete and need sorting, when done I will update the documentation to specify what I changed and why.

After building the SDK you can try and run it using ```bash flutter run -d Android_Device```.
Please note that you need to replace 'Android_Device' with the actual name of the device.
You need

Currently am trying to update most of the android scripts for it to work as smooth as possible.
The branch is [here](https://github.com/rileyhawk1417/appflowy/tree/android_build).

### Known issues

There are some hiccups that could occur on the way, for example the crate fcaccess can be a pain when compiling to a specific platform.
One time it will need you to change the char from u8 -> i8.
So it depends on which android platform. Sometimes you will need to manually change it.

