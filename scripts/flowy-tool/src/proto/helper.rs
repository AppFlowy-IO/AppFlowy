use walkdir::WalkDir;

#[derive(Clone)]
pub struct CrateInfo {
    pub crate_folder_name: String,
    pub domain_path: String,
    pub crate_path: String,
}

pub struct CrateProtoInfo {
    pub files: Vec<FileProtoInfo>,
    pub inner: CrateInfo,
}

impl CrateInfo {
    fn protobuf_crate_name(&self) -> String {
        format!("{}/src/protobuf", self.crate_path)
    }

    pub fn proto_file_output_dir(&self) -> String {
        let dir = format!("{}/proto", self.protobuf_crate_name());
        self.create_file_if_not_exist(dir.as_ref());
        dir
    }

    pub fn proto_struct_output_dir(&self) -> String {
        let dir = format!("{}/model", self.protobuf_crate_name());
        self.create_file_if_not_exist(dir.as_ref());
        dir
    }

    pub fn crate_mod_file(&self) -> String {
        format!("{}/mod.rs", self.proto_struct_output_dir())
    }

    fn create_file_if_not_exist(&self, dir: &str) {
        if !std::path::Path::new(&dir).exists() {
            std::fs::create_dir_all(&dir).unwrap();
        }
    }
}

impl CrateProtoInfo {
    pub fn from_crate_info(inner: CrateInfo, files: Vec<FileProtoInfo>) -> Self {
        Self { files, inner }
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
        .filter(|e| is_crate_dir(e))
        .flat_map(|e| {
            // Assert e.path().parent() will be the crate dir
            let path = e.path().parent().unwrap();
            let crate_folder_name = path.file_stem().unwrap().to_str().unwrap().to_string();
            if crate_folder_name == "flowy-user".to_owned() {
                let crate_path = path.to_str().unwrap().to_string();
                let domain_path = format!("{}/src/domain", crate_path);
                Some(CrateInfo {
                    crate_folder_name,
                    domain_path,
                    crate_path,
                })
            } else {
                None
            }
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

pub fn is_crate_dir(e: &walkdir::DirEntry) -> bool {
    let cargo = e.path().file_stem().unwrap().to_str().unwrap().to_string();
    cargo == "Cargo".to_string()
}

pub fn domain_dir_from(e: &walkdir::DirEntry) -> Option<String> {
    let domain = e.path().file_stem().unwrap().to_str().unwrap().to_string();
    if e.file_type().is_dir() && domain == "domain".to_string() {
        Some(e.path().to_str().unwrap().to_string())
    } else {
        None
    }
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
