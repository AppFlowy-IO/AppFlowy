.PHONY: flowy_dev_install flowy_clean

flowy_dev_install:
	brew bundle
	rustup-init -y --default-toolchain=stable
	cargo install --force cargo-make
	cargo install --force duckscript_cli
	cargo make flowy_dev


flowy_clean:
	sh ./scripts/clean.sh


