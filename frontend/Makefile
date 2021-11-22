.PHONY: flowy_dev install_cargo_make

flowy_dev: install_cargo_make
	cargo make flowy_dev

install_cargo_make:
	cargo install --force cargo-make
	brew bundle

install_rust:
	brew bundle
	rustup-init -y --default-toolchain=nightly
