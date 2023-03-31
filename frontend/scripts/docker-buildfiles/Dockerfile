#================
# BUILDER
#================

FROM archlinux/archlinux:base-devel as builder

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
RUN sudo pacman -S --needed --noconfirm git
RUN git clone --depth 1 https://aur.archlinux.org/yay.git && \
    cd yay && \
    makepkg -sri --needed --noconfirm

# Install Rust
RUN yay -S --noconfirm curl base-devel openssl clang cmake ninja pkg-config xdg-user-dirs
RUN xdg-user-dirs-update
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN source ~/.cargo/env && \
    rustup toolchain install stable && \
    rustup default stable

# Install Flutter
RUN sudo pacman -S --noconfirm tar gtk3
RUN curl -sSfL \
      --output flutter.tar.xz \
      https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.3.10-stable.tar.xz && \
    tar -xf flutter.tar.xz && \
    rm flutter.tar.xz
RUN flutter config --enable-linux-desktop
RUN flutter doctor
RUN dart pub global activate protoc_plugin

# Build the AppFlowy app
RUN sudo pacman -S --noconfirm libkeybinder3 sqlite
RUN git clone --depth 1 https://github.com/AppFlowy-IO/appflowy.git
RUN cd appflowy/frontend && \
    source ~/.cargo/env && \
    cargo install --force cargo-make duckscript_cli && \
    cargo make appflowy-flutter-deps-tools && \
    cargo make -p production-linux-x86_64 appflowy-linux


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
COPY --from=builder /home/makepkg/appflowy/frontend/appflowy_flutter/build/linux/x64/release/bundle .
RUN xdg-user-dirs-update

CMD ["./AppFlowy"]
