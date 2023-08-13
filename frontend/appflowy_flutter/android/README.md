# Description

This is a rough guide on how to build the rust SDK for AppFlowy on android.
Compiling the sdk is easy it just needs a few tweaks.
When compiling for android we need the following pre-requisites:

- Android NDK Tools. (v24 has been tested for this) even the latest version works.
- Cargo NDK. (@latest version).

**Warning** currently the rust backend for android does not compile on windows.

**Getting the tools**
- Install cargo-ndk ```bash cargo install cargo-ndk```.
- [Android NDK](https://developer.android.com/ndk/downloads/) .
- When downloading Android NDK you can get the compressed version as a standalone from the site.
    Or you can download it through [Android Studio](https://developer.android.com/studio).
- After downloading the two you need to set the environment variables. For Windows that's a separate process.
    On macOS and Linux the process is similar.
- The variables needed are '$ANDROID_NDK_HOME', this will point to where the NDK is located.
---

**Cargo Config File**
This code needs to be written in ~/.cargo/config, this helps cargo know where to locate the android tools(linker and archiver).
**NB** Keep in mind just replace `user` with your own `username`. Or just point it to the location of where you put the NDK.

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

 ---

 **Android NDK**

 After installing the NDK tools for android you should export the PATH to your config file
 (.vimrc, .zshrc, .profile, .bashrc file), That way it can be found.

 ```vim
 export PATH=/home/user/Android/Sdk/ndk/24.0.8215888
 ```
 
You also need to copy a specific file `libc++_shared.so` into the android `jniLib` folder
During the building of the backend process it somehow got skipped. The best fix for now
is to manually copy it into the folder.
The block below shows an example of where it is on a linux machine
`$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/x86_64-android/libc++_shared.so`

Then from there you can just run this in the frontend folder to build the rust backend
`cargo make --profile production-android appflowy-core-dev-android` 

Or you can head into vscode and run the android task