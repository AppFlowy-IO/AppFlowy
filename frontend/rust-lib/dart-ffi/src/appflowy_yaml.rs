use std::fs::{File, OpenOptions};
use std::io::{Read, Write};
use std::path::Path;

use serde::{Deserialize, Serialize};

use flowy_server_pub::af_cloud_config::AFCloudConfiguration;

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

pub fn get_cloud_config(
  root: impl AsRef<Path>,
  base_url: &str,
) -> Option<AFCloudConfiguration> {
  let file_path = root.as_ref().join("appflowy.yaml");
  let config = read_yaml_file(&file_path).ok()?;
  config
    .cloud_config
    .into_iter()
    .find(|c| c.base_url == base_url)
}

pub fn validate_cloud_config(config: &AFCloudConfiguration) -> bool {
  !config.base_url.is_empty()
}

fn read_yaml_file(
  file_path: impl AsRef<Path>,
) -> Result<AppFlowyYamlConfiguration, Box<dyn std::error::Error>> {
  let path = file_path.as_ref();
  if !path.exists() {
    return Ok(AppFlowyYamlConfiguration::default());
  }
  
  let mut file = File::open(path)?;
  let mut contents = String::new();
  file.read_to_string(&mut contents)?;
  
  if contents.trim().is_empty() {
    return Ok(AppFlowyYamlConfiguration::default());
  }
  
  let config: AppFlowyYamlConfiguration = serde_yaml::from_str(&contents)
    .unwrap_or_else(|_| AppFlowyYamlConfiguration::default());
  Ok(config)
}

fn write_yaml_file(
  file_path: impl AsRef<Path>,
  config: &AppFlowyYamlConfiguration,
) -> Result<(), Box<dyn std::error::Error>> {
  let path = file_path.as_ref();
  
  // Ensure parent directory exists
  if let Some(parent) = path.parent() {
    if !parent.exists() {
      std::fs::create_dir_all(parent)?;
    }
  }
  
  let yaml_string = serde_yaml::to_string(config)?;
  let mut file = OpenOptions::new()
    .create(true)
    .write(true)
    .truncate(true)
    .open(path)?;
  file.write_all(yaml_string.as_bytes())?;
  file.sync_all()?;
  Ok(())
}