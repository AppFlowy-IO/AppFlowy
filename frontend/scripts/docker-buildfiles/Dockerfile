#================
# BUILDER
#================

FROM archlinux/archlinux:base-devel as builder
RUN chown root:root /usr/bin/sudo && chmod 4755 /usr/bin/sudo

# Upgrade the system
RUN pacman -Syyu --noconfirm

# Set up makepkg user and workdir
ARG user=makepkg
RUN pacman -S --needed --noconfirm sudo
RUN useradd --system --create-home $user && \
    echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
ENV PATH="/home/$user/.pub-cache/bin:/home/$user/flutter/bin:/home/$user/flutter/bin/cache/dart-sdk/bin:${PATH}"
USER $user
WORKDIR /home/$user

# Install yay
RUN sudo pacman -S --needed --noconfirm curl tar
RUN curl -sSfL \
    --output yay.tar.gz \
    https://github.com/Jguer/yay/releases/download/v12.3.3/yay_12.3.3_x86_64.tar.gz && \
  tar -xf yay.tar.gz && \
  sudo mv yay_12.3.3_x86_64/yay /bin && \
  rm -rf yay_12.3.3_x86_64 && \
  yay --version

# Install Rust
RUN yay -S --noconfirm curl base-devel openssl clang cmake ninja pkg-config xdg-user-dirs
RUN xdg-user-dirs-update
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN source ~/.cargo/env && \
    rustup toolchain install 1.77.2 && \
    rustup default 1.77.2

# Install Flutter
RUN sudo pacman -S --noconfirm git tar gtk3
RUN curl -sSfL \
      --output flutter.tar.xz \
      https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.0-stable.tar.xz && \
    tar -xf flutter.tar.xz && \
    rm flutter.tar.xz
RUN flutter config --enable-linux-desktop
RUN flutter doctor
RUN dart pub global activate protoc_plugin 21.1.2

# Install build dependencies for AppFlowy
RUN yay -S --noconfirm jemalloc4 cargo-make cargo-binstall
RUN sudo pacman -S --noconfirm git libkeybinder3 sqlite clang rsync libnotify rocksdb zstd mpv
RUN sudo ln -s /usr/bin/sha1sum /usr/bin/shasum
RUN source ~/.cargo/env && cargo binstall duckscript_cli -y

# Build AppFlowy
COPY . /appflowy
RUN sudo chown -R $user: /appflowy
WORKDIR /appflowy
RUN cd frontend && \
    source ~/.cargo/env && \
    cargo make appflowy-flutter-deps-tools && \
    cargo make flutter_clean && \
    OPENSSL_STATIC=1 ZSTD_SYS_USE_PKG_CONFIG=1 ROCKSDB_LIB_DIR="/usr/lib/" cargo make -p production-linux-x86_64 appflowy-linux


#================
# APP
#================

FROM archlinux/archlinux

# Upgrade the system
RUN pacman -Syyu --noconfirm

# Install runtime dependencies
RUN pacman -S --noconfirm xdg-user-dirs gtk3 libkeybinder3 && \
    pacman -Scc --noconfirm

# Set up appflowy user
ARG user=appflowy
ARG uid=1000
ARG gid=1000
RUN groupadd --gid $gid $user
RUN useradd --create-home --uid $uid --gid $gid $user
USER $user

# Set up the AppFlowy app
WORKDIR /home/$user
COPY --from=builder /appflowy/frontend/appflowy_flutter/build/linux/x64/release/bundle .
RUN xdg-user-dirs-update && \
    test -e ./AppFlowy && \
    file ./AppFlowy

CMD ["./AppFlowy"]
