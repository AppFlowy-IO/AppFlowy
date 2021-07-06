use crate::config::*;
use std::fs::OpenOptions;
use std::io::Write;
use walkdir::WalkDir;

#[derive(Clone)]
pub struct CrateInfo {
    pub crate_folder_name: String,
    pub proto_crate_paths: Vec<String>,
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
        create_dir_if_not_exist(dir.as_ref());
        dir
    }

    pub fn proto_struct_output_dir(&self) -> String {
        let dir = format!("{}/model", self.protobuf_crate_name());
        create_dir_if_not_exist(dir.as_ref());
        dir
    }

    pub fn proto_model_mod_file(&self) -> String {
        format!("{}/mod.rs", self.proto_struct_output_dir())
    }
}

impl CrateProtoInfo {
    pub fn from_crate_info(inner: CrateInfo, files: Vec<FileProtoInfo>) -> Self {
        Self { files, inner }
    }

    pub fn create_crate_mod_file(&self) {
        // mod model;
        // pub use model::*;
        let mod_file_path = format!("{}/mod.rs", self.inner.protobuf_crate_name());
        let content = r#"
mod model;
pub use model::*;
        "#;
        match OpenOptions::new()
            .create(true)
            .write(true)
            .append(false)
            .truncate(true)
            .open(&mod_file_path)
        {
            Ok(ref mut file) => {
                file.write_all(content.as_bytes()).unwrap();
            }
            Err(err) => {
                panic!("Failed to open protobuf mod file: {}", err);
            }
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
        .filter(|e| is_crate_dir(e))
        .flat_map(|e| {
            // Assert e.path().parent() will be the crate dir
            let path = e.path().parent().unwrap();
            let crate_path = path.to_str().unwrap().to_string();
            let crate_folder_name = path.file_stem().unwrap().to_str().unwrap().to_string();
            let flowy_config_file = format!("{}/Flowy.toml", crate_path);

            if std::path::Path::new(&flowy_config_file).exists() {
                let config = FlowyConfig::from_toml_file(flowy_config_file.as_ref());
                let crate_path = path.to_str().unwrap().to_string();
                let proto_crate_paths = config
                    .proto_crates
                    .iter()
                    .map(|name| format!("{}/{}", crate_path, name))
                    .collect::<Vec<String>>();
                Some(CrateInfo {
                    crate_folder_name,
                    proto_crate_paths,
                    crate_path,
                })
            } else {
                None
            }
        })
        .collect::<Vec<CrateInfo>>()
}

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
