use std::fs;
use std::path::{Path, PathBuf};

#[derive(serde::Deserialize, Clone, Debug)]
pub struct FlowyConfig {
    pub event_files: Vec<String>,
    pub proto_rust_file_input_dir: Vec<String>,
    pub proto_file_output_dir: String,
    pub protobuf_crate_output_dir: String,
}

impl FlowyConfig {
    pub fn from_toml_file(path: &Path) -> Self {
        let content = fs::read_to_string(path).unwrap();
        let config: FlowyConfig = toml::from_str(content.as_ref()).unwrap();
        config
    }
}

pub struct CrateConfig {
    pub crate_path: PathBuf,
    pub crate_folder: String,
    pub flowy_config: FlowyConfig,
}

pub fn parse_crate_config_from(entry: &walkdir::DirEntry) -> Option<CrateConfig> {
    let mut config_path = entry.path().parent().unwrap().to_path_buf();
    config_path.push("Flowy.toml");
    if !config_path.as_path().exists() {
        return None;
    }
    let crate_path = entry.path().parent().unwrap().to_path_buf();
    let flowy_config = FlowyConfig::from_toml_file(config_path.as_path());
    let crate_folder = crate_path.file_stem().unwrap().to_str().unwrap().to_string();

    Some(CrateConfig {
        crate_path,
        crate_folder,
        flowy_config,
    })
}
