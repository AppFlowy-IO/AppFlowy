use walkdir::WalkDir;

pub struct CrateInfo {
    pub name: String,
    pub path: String,
}

pub struct CrateProtoInfo {
    pub files: Vec<FileProtoInfo>,
    pub name: String,
    pub path: String,
}

impl CrateProtoInfo {
    pub fn new(info: &CrateInfo, files: Vec<FileProtoInfo>) -> Self {
        Self {
            files,
            name: info.name.to_owned(),
            path: info.path.to_owned(),
        }
    }
}

#[derive(Debug)]
pub struct FileProtoInfo {
    pub file_name: String,
    pub structs: Vec<String>,
    pub enums: Vec<String>,
    pub generated_content: String,
}

pub fn get_crate_domain_directory(root: &str) -> Vec<CrateInfo> {
    WalkDir::new(root)
        .into_iter()
        .filter_entry(|e| !is_hidden(e))
        .filter_map(|e| e.ok())
        .filter(|e| is_domain_dir(e))
        .map(|e| CrateInfo {
            //TODO: get the crate name from toml file
            name: e
                .path()
                .parent()
                .unwrap()
                .parent()
                .unwrap()
                .file_stem()
                .unwrap()
                .to_str()
                .unwrap()
                .to_string(),
            path: e.path().to_str().unwrap().to_string(),
        })
        .collect::<Vec<CrateInfo>>()
}

pub fn is_domain_dir(e: &walkdir::DirEntry) -> bool {
    let domain = e.path().file_stem().unwrap().to_str().unwrap().to_string();
    if e.file_type().is_dir() && domain == "domain".to_string() {
        true
    } else {
        false
    }
}

pub fn is_hidden(entry: &walkdir::DirEntry) -> bool {
    entry
        .file_name()
        .to_str()
        .map(|s| s.starts_with("."))
        .unwrap_or(false)
}
