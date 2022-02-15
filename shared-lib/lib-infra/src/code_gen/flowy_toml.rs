use std::fs;

#[derive(serde::Deserialize)]
pub struct FlowyConfig {
    pub proto_crates: Vec<String>,
    pub event_files: Vec<String>,
}

impl FlowyConfig {
    pub fn from_toml_file(path: &str) -> Self {
        let content = fs::read_to_string(path).unwrap();
        let config: FlowyConfig = toml::from_str(content.as_ref()).unwrap();
        config
    }
}

pub struct CrateConfig {
    pub crate_path: String,
    pub folder_name: String,
    pub flowy_config: FlowyConfig,
}

impl CrateConfig {
    pub fn proto_paths(&self) -> Vec<String> {
        let proto_paths = self
            .flowy_config
            .proto_crates
            .iter()
            .map(|name| format!("{}/{}", self.crate_path, name))
            .collect::<Vec<String>>();
        proto_paths
    }
}

pub fn parse_crate_config_from(entry: &walkdir::DirEntry) -> Option<CrateConfig> {
    let path = entry.path().parent().unwrap();
    let crate_path = path.to_str().unwrap().to_string();
    let folder_name = path.file_stem().unwrap().to_str().unwrap().to_string();
    let config_path = format!("{}/Flowy.toml", crate_path);

    if !std::path::Path::new(&config_path).exists() {
        return None;
    }

    let flowy_config = FlowyConfig::from_toml_file(config_path.as_ref());

    Some(CrateConfig {
        crate_path,
        folder_name,
        flowy_config,
    })
}
