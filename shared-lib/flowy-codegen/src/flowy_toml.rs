use std::fs;
use std::path::{Path, PathBuf};

#[derive(serde::Deserialize, Clone, Debug)]
pub struct FlowyConfig {
  #[serde(default)]
  pub event_files: Vec<String>,

  // Collect AST from the file or directory specified by proto_input to generate the proto files.
  #[serde(default)]
  pub proto_input: Vec<String>,

  // Output path for the generated proto files. The default value is default_proto_output()
  #[serde(default = "default_proto_output")]
  pub proto_output: String,

  // Create a crate that stores the generated protobuf Rust structures. The default value is default_protobuf_crate()
  #[serde(default = "default_protobuf_crate")]
  pub protobuf_crate_path: String,
}

fn default_proto_output() -> String {
  let mut path = PathBuf::from("resources");
  path.push("proto");
  path.to_str().unwrap().to_owned()
}

fn default_protobuf_crate() -> String {
  let mut path = PathBuf::from("src");
  path.push("protobuf");
  path.to_str().unwrap().to_owned()
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
  let crate_folder = crate_path
    .file_stem()
    .unwrap()
    .to_str()
    .unwrap()
    .to_string();

  Some(CrateConfig {
    crate_path,
    crate_folder,
    flowy_config,
  })
}
