FROM archlinux/archlinux:base-devel as builder

RUN pacman -Syy

RUN pacman -Syu --needed --noconfirm git xdg-user-dirs

# makepkg user and workdir
ARG user=makepkg
ENV PATH="/home/makepkg/.pub-cache/bin:/home/makepkg/.local/flutter/bin:/home/makepkg/.local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN useradd --system --create-home $user \
  && echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
USER $user
WORKDIR /home/$user

# Install yay
RUN git clone https://aur.archlinux.org/yay.git \
  && cd yay \
  && makepkg -sri --needed --noconfirm \
  && cd \
  && rm -rf .cache yay

RUN yay -S --noconfirm curl base-devel sqlite openssl clang cmake ninja pkg-config gtk3 unzip
RUN xdg-user-dirs-update
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN source $HOME/.cargo/env && rustup toolchain install stable && rustup default stable
RUN git clone https://github.com/flutter/flutter.git $HOME/.local/flutter
RUN flutter channel stable
RUN flutter config --enable-linux-desktop
RUN flutter doctor
RUN dart pub global activate protoc_plugin

RUN git clone https://github.com/AppFlowy-IO/appflowy.git && \
cd appflowy/frontend && \
source $HOME/.cargo/env && \
cargo install --force cargo-make && \
cargo install --force duckscript_cli && \
cargo make flowy_dev && \
cargo make -p production-linux-x86 appflowy-linux

CMD ["/home/makepkg/appflowy/frontend/app_flowy/build/linux/x64/release/bundle/app_flowy"]

#################
FROM archlinux/archlinux:base-devel

RUN pacman -Syy
RUN pacman -Syu --needed --noconfirm xdg-user-dirs
RUN xdg-user-dirs-update

ARG user=makepkg
RUN useradd --system --create-home $user \
  && echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
USER $user
WORKDIR /home/$user

COPY --from=builder /usr/sbin/yay /usr/sbin/yay
RUN yay -S --noconfirm gtk3

COPY --from=builder /home/makepkg/appflowy/frontend/app_flowy/build/linux/x64/release/bundle ./AppFlowy

CMD ["/home/makepkg/AppFlowy/app_flowy"]
