use std::fs::{File, OpenOptions};
use std::io::{Read, Write};
use std::path::Path;

use serde::{Deserialize, Serialize};

use flowy_server_config::af_cloud_config::AFCloudConfiguration;

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct AppFlowyYamlConfiguration {
  cloud_config: Vec<AFCloudConfiguration>,
}

pub fn save_appflowy_cloud_config(
  root: impl AsRef<Path>,
  new_config: &AFCloudConfiguration,
) -> Result<(), Box<dyn std::error::Error>> {
  let file_path = root.as_ref().join("appflowy.yaml");
  let mut config = read_yaml_file(&file_path).unwrap_or_default();

  if !config
    .cloud_config
    .iter()
    .any(|c| c.base_url == new_config.base_url)
  {
    config.cloud_config.push(new_config.clone());
    write_yaml_file(&file_path, &config)?;
  }
  Ok(())
}

fn read_yaml_file(
  file_path: impl AsRef<Path>,
) -> Result<AppFlowyYamlConfiguration, Box<dyn std::error::Error>> {
  let mut file = File::open(file_path)?;
  let mut contents = String::new();
  file.read_to_string(&mut contents)?;
  let config: AppFlowyYamlConfiguration = serde_yaml::from_str(&contents)?;
  Ok(config)
}

fn write_yaml_file(
  file_path: impl AsRef<Path>,
  config: &AppFlowyYamlConfiguration,
) -> Result<(), Box<dyn std::error::Error>> {
  let yaml_string = serde_yaml::to_string(config)?;
  let mut file = OpenOptions::new()
    .create(true)
    .write(true)
    .truncate(true)
    .open(file_path)?;
  file.write_all(yaml_string.as_bytes())?;
  Ok(())
}
