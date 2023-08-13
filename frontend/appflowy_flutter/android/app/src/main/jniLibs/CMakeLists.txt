cmake_minimum_required(VERSION 3.10)
project(appflowy_flutter)

if (${CMAKE_HOST_SYSTEM_NAME}  STREQUAL "Linux")
        file(COPY
            $ENV{ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/arm64-v8a
            )

        file(COPY
            $ENV{ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/armeabi-v7a
            )

        file(COPY
            $ENV{ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/i686-linux-android/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/x86
            )

        file(COPY
            $ENV{ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/x86_64-linux-android/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/x86_64
            )

elseif (${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
        file(COPY
            ${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/arm64-v8a
            )

        file(COPY
            ${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/armeabi-v7a
            )

        file(COPY
            ${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/i686-linux-android/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/x86
            )

        file(COPY
            ${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/x86_64-linux-android/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/x86_64
            )

elseif(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
        file(COPY
            ${ANDROID_NDK}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/arm64-v8a
            )

        file(COPY
            ${ANDROID_NDK}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/armeabi-v7a
            )

        file(COPY
            ${ANDROID_NDK}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/i686-linux-android/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/x86
            )

        file(COPY
            ${ANDROID_NDK}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/x86_64-linux-android/libc++_shared.so
            DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/x86_64
            )

else()
    message("Unable to detect the platform to copy NDK Files")
endif()

# Remove cmake files after build
file(REMOVE ${CMAKE_CURRENT_SOURCE_DIR}/CMakeCache.txt)
file(REMOVE_RECURSE ${CMAKE_CURRENT_SOURCE_DIR}/CMakeFiles)