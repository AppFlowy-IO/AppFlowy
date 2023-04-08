FROM archlinux/archlinux:base-devel as builder

RUN pacman -Syy
RUN pacman -Syu --needed --noconfirm git libkeybinder3 xdg-user-dirs protobuf

# makepkg user and workdir
ARG user=makepkg
RUN useradd --system --create-home $user \
  && echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$user
USER $user
WORKDIR /home/$user

# create user directories
RUN xdg-user-dirs-update

# Install yay
RUN git clone https://aur.archlinux.org/yay.git \
  && cd yay \
  && makepkg -sri --needed --noconfirm

RUN yay -S --noconfirm curl base-devel sqlite openssl clang cmake ninja pkg-config gtk3 unzip

# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/home/makepkg/.cargo/bin:${PATH}"

USER $user
# Build flowy-grpc
COPY . ./appflowy
RUN sudo chown -R $user:root ./appflowy
WORKDIR /home/$user/appflowy/frontend/rust-lib/flowy-grpc
# ENV RUST_LOG=trace
RUN cargo build --bin grpc-server --release

CMD ["/home/makepkg/appflowy/frontend/rust-lib/target/release/grpc-server"]

FROM archlinux/archlinux

RUN pacman -Syy
RUN pacman -Syu --needed --noconfirm xdg-user-dirs
RUN xdg-user-dirs-update

ARG user=appflowy
ARG uid=1000
ARG gid=1000

RUN groupadd --gid $gid appflowy
RUN useradd --create-home --uid $uid --gid $gid $user
USER $user
WORKDIR /home/$user

COPY --from=builder /home/makepkg/appflowy/frontend/rust-lib/target/release/grpc-server .

CMD ["./grpc-server"]