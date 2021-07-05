use std::fs;

#[derive(serde::Deserialize)]
pub struct FlowyConfig {
    pub proto_crates: Vec<String>,
}

impl FlowyConfig {
    pub fn from_toml_file(path: &str) -> Self {
        let content = fs::read_to_string(path).unwrap();
        let config: FlowyConfig = toml::from_str(content.as_ref()).unwrap();
        config
    }
}
