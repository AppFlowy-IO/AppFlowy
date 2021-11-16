.PHONY: flowy_dev install_cargo_make

flowy_dev: install_cargo_make
	cargo make flowy_dev

install_cargo_make:
	cargo install --force cargo-make
	brew bundle

install_rust:
	sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
	curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
	echo 'export PATH="$$HOME/.cargo/bin:$$PATH"' >> ~/.bash_profile
	source ~/.bash_profile
