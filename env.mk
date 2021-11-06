
flowy_dev: install_rust
	cargo make flowy_dev

install_rust:
	#https://rust-lang.github.io/rustup/installation/other.html
	sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
	curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
	echo 'export PATH="$$HOME/.cargo/bin:$$PATH"' >> ~/.bash_profile
	source ~/.bash_profile