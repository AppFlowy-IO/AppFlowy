use crate::code_gen::util::path_buf_with_component;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(serde::Deserialize)]
pub struct FlowyConfig {
    pub proto_crates: Vec<String>,
    pub event_files: Vec<String>,
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
    pub folder_name: String,
    pub flowy_config: FlowyConfig,
}

impl CrateConfig {
    pub fn proto_paths(&self) -> Vec<PathBuf> {
        let proto_paths = self
            .flowy_config
            .proto_crates
            .iter()
            .map(|name| path_buf_with_component(&self.crate_path, vec![&name]))
            .collect::<Vec<PathBuf>>();
        proto_paths
    }
}

pub fn parse_crate_config_from(entry: &walkdir::DirEntry) -> Option<CrateConfig> {
    let mut config_path = entry.path().parent().unwrap().to_path_buf();
    config_path.push("Flowy.toml");
    if !config_path.as_path().exists() {
        return None;
    }
    let crate_path = entry.path().parent().unwrap().to_path_buf();
    let flowy_config = FlowyConfig::from_toml_file(config_path.as_path());
    let folder_name = crate_path.file_stem().unwrap().to_str().unwrap().to_string();

    Some(CrateConfig {
        crate_path,
        folder_name,
        flowy_config,
    })
}
