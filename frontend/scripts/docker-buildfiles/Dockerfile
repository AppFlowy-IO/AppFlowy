FROM archlinux/archlinux:base-devel as builder

RUN pacman -Syy

RUN pacman -Syu --needed --noconfirm git xdg-user-dirs

# makepkg user and workdir
ARG user=makepkg
ENV PATH="/home/$user/.pub-cache/bin:/home/$user/.local/flutter/bin:/home/$user/.local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN useradd --system --create-home $user \
  && echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
USER $user
WORKDIR /home/$user

# Install yay
RUN git clone https://aur.archlinux.org/yay.git \
  && cd yay \
  && makepkg -sri --needed --noconfirm

RUN yay -S --noconfirm curl base-devel sqlite openssl clang cmake ninja pkg-config gtk3 unzip
RUN xdg-user-dirs-update
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN source $HOME/.cargo/env && rustup toolchain install stable && rustup default stable
RUN git clone https://github.com/flutter/flutter.git $HOME/.local/flutter
RUN flutter channel stable
RUN flutter config --enable-linux-desktop
RUN flutter doctor
RUN dart pub global activate protoc_plugin
RUN pacman -Syu --needed --noconfirm git xdg-user-dirs libkeybinder3

RUN git clone https://github.com/AppFlowy-IO/appflowy.git && \
cd appflowy/frontend && \
source $HOME/.cargo/env && \
cargo install --force cargo-make && \
cargo install --force duckscript_cli && \
cargo make flowy_dev && \
cargo make -p production-linux-x86_64 appflowy-linux

CMD ["/home/makepkg/appflowy/frontend/app_flowy/build/linux/x64/release/bundle/app_flowy"]

#################
FROM archlinux/archlinux

RUN pacman -Syy && \
    pacman -Syu --needed --noconfirm xdg-user-dirs && \
    pacman -Scc --noconfirm
RUN xdg-user-dirs-update

COPY --from=builder /usr/sbin/yay /usr/sbin/yay
RUN yay -S --noconfirm gtk3

ARG user=appflowy
ARG uid=1000
ARG gid=1000

RUN groupadd --gid $gid appflowy
RUN useradd --create-home --uid $uid --gid $gid $user
USER $user
WORKDIR /home/$user

COPY --from=builder /home/makepkg/appflowy/frontend/app_flowy/build/linux/x64/release/bundle/ .

CMD ["./app_flowy"]
