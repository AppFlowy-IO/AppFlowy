.PHONY: flowy_dev_install

flowy_dev_install:
	brew bundle
	rustup-init -y --default-toolchain=stable
	cargo install --force cargo-make
	cargo install --force duckscript_cli
	cargo make flowy_dev


