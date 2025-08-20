# Description

This is a guide on how to build the rust SDK for AppFlowy on android.
Compiling the sdk is easy it just needs a few tweaks.
When compiling for android we need the following pre-requisites:

- Android NDK Tools. (v24 has been tested).
- Cargo NDK. (@latest version).

**Getting the tools**
- Install cargo-ndk ```bash cargo install cargo-ndk```.
- [Download](https://developer.android.com/ndk/downloads/) Android NDK version 24.
- When downloading Android NDK you can get the compressed version as a standalone from the site.
    Or you can download it through [Android Studio](https://developer.android.com/studio).
- After downloading the two you need to set the environment variables. The process differs by operating system.
- The variables needed are '$ANDROID_NDK_HOME', this will point to where the NDK is located.

**Setting Environment Variables**

**Windows:**
```cmd
set ANDROID_NDK_HOME=C:\Users\%USERNAME%\AppData\Local\Android\Sdk\ndk\24.0.8215888
```
Or add to your system environment variables permanently.

**macOS/Linux:**
```bash
export ANDROID_NDK_HOME=~/Android/Sdk/ndk/24.0.8215888
```
---

**Cargo Config File**
This code needs to be written in `~/.cargo/config` (Linux/macOS) or `%USERPROFILE%\.cargo\config` (Windows). This helps cargo know where to locate the android tools (linker and archiver).
**NB** Replace the paths with your actual NDK installation location.

**Linux/macOS:**
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

**Windows:**
```toml
[target.aarch64-linux-android]
ar = "C:\\Users\\%USERNAME%\\AppData\\Local\\Android\\Sdk\\ndk\\24.0.8215888\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\llvm-ar.exe"
linker = "C:\\Users\\%USERNAME%\\AppData\\Local\\Android\\Sdk\\ndk\\24.0.8215888\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\aarch64-linux-android29-clang.exe"

[target.armv7-linux-androideabi]
ar = "C:\\Users\\%USERNAME%\\AppData\\Local\\Android\\Sdk\\ndk\\24.0.8215888\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\llvm-ar.exe"
linker = "C:\\Users\\%USERNAME%\\AppData\\Local\\Android\\Sdk\\ndk\\24.0.8215888\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\armv7a-linux-androideabi29-clang.exe"

[target.i686-linux-android]
ar = "C:\\Users\\%USERNAME%\\AppData\\Local\\Android\\Sdk\\ndk\\24.0.8215888\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\llvm-ar.exe"
linker = "C:\\Users\\%USERNAME%\\AppData\\Local\\Android\\Sdk\\ndk\\24.0.8215888\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\i686-linux-android29-clang.exe"

[target.x86_64-linux-android]
ar = "C:\\Users\\%USERNAME%\\AppData\\Local\\Android\\Sdk\\ndk\\24.0.8215888\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\llvm-ar.exe"
linker = "C:\\Users\\%USERNAME%\\AppData\\Local\\Android\\Sdk\\ndk\\24.0.8215888\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\x86_64-linux-android29-clang.exe"
```

**Clang Fix**
In order to get clang to work properly with version 24 you need to create this file.
Create a file named `libgcc.a` with this one line:
```
INPUT(-lunwind)
```

**Linux/macOS:**
Folder path: `Android/Sdk/ndk/24.0.8215888/toolchains/llvm/prebuilt/linux-x86_64/lib64/clang/14.0.1/lib/linux/`

**Windows:**
Folder path: `Android\Sdk\ndk\24.0.8215888\toolchains\llvm\prebuilt\windows-x86_64\lib64\clang\14.0.1\lib\linux\`

After creating the file, copy it into four different folders: `aarch64`, `arm`, `i386` and `x86_64`.
We have to do this so the Android NDK can find clang on our system. If we used NDK 22 we wouldn't have to do this process, though using NDK v22 will not give us a lot of features to work with.
This GitHub [issue](https://github.com/fzyzcjy/flutter_rust_bridge/issues/419) explains the reason why we are doing this.

 ---

**Android NDK Path Setup**

After installing the NDK tools for Android you should add the NDK path to your system PATH.

**Linux/macOS:**
Add to your shell config file (.bashrc, .zshrc, .profile):
```bash
export PATH=$PATH:~/Android/Sdk/ndk/24.0.8215888
```

**Windows:**
Add to your system PATH environment variable or add to PowerShell profile:
```powershell
$env:PATH += ";C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\ndk\24.0.8215888"
```

**Building AppFlowy Android**

Once you have completed the setup above, you can build AppFlowy for Android using:

**All platforms:**
```bash
cd frontend
cargo make appflowy-android
```

This will use the appropriate build scripts for your platform (Windows, macOS, or Linux).