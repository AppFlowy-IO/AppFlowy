use flowy_infra::uuid;
use std::{fs, path::PathBuf};

pub fn root_dir() -> String {
    // https://doc.rust-lang.org/cargo/reference/environment-variables.html
    let manifest_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap_or("./".to_owned());
    let mut path_buf = fs::canonicalize(&PathBuf::from(&manifest_dir)).unwrap();
    path_buf.pop(); // rust-lib
    path_buf.push("flowy-test");
    path_buf.push("temp");
    path_buf.push("flowy");

    let root_dir = path_buf.to_str().unwrap().to_string();
    if !std::path::Path::new(&root_dir).exists() {
        std::fs::create_dir_all(&root_dir).unwrap();
    }
    root_dir
}

pub fn random_valid_email() -> String { format!("{}@appflowy.io", uuid()) }

pub fn valid_email() -> String { "annie@appflowy.io".to_string() }

pub fn valid_password() -> String { "HelloWorld!123".to_string() }
