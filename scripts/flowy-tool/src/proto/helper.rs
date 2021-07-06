pub fn is_crate_dir(e: &walkdir::DirEntry) -> bool {
    let cargo = e.path().file_stem().unwrap().to_str().unwrap().to_string();
    cargo == "Cargo".to_string()
}

pub fn is_proto_file(e: &walkdir::DirEntry) -> bool {
    if e.path().extension().is_none() {
        return false;
    }
    let ext = e.path().extension().unwrap().to_str().unwrap().to_string();
    ext == "proto".to_string()
}

pub fn is_hidden(entry: &walkdir::DirEntry) -> bool {
    entry
        .file_name()
        .to_str()
        .map(|s| s.starts_with("."))
        .unwrap_or(false)
}

pub fn create_dir_if_not_exist(dir: &str) {
    if !std::path::Path::new(&dir).exists() {
        std::fs::create_dir_all(&dir).unwrap();
    }
}
