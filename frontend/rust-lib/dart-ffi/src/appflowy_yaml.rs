use std::fs::{File, OpenOptions};
use std::io::{Read, Write};
use std::path::Path;

use serde::{Deserialize, Serialize};
use tracing::{error, info, warn};

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
  
  // Ensure the parent directory exists
  if let Some(parent) = file_path.parent() {
    if !parent.exists() {
      std::fs::create_dir_all(parent)?;
    }
  }
  
  let mut config = match read_yaml_file(&file_path) {
    Ok(c) => c,
    Err(e) => {
      warn!("Could not read appflowy.yaml (using default): {}", e);
      AppFlowyYamlConfiguration::default()
    }
  };

  if !config
    .cloud_config
    .iter()
    .any(|c| c.base_url == new_config.base_url)
  {
    config.cloud_config.push(new_config.clone());
    if let Err(e) = write_yaml_file(&file_path, &config) {
      error!("Failed to write appflowy.yaml: {}", e);
      return Err(e);
    }
    info!("Successfully saved cloud config to appflowy.yaml");
  }
  Ok(())
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
  
  // Handle empty file case
  if contents.trim().is_empty() {
    return Ok(AppFlowyYamlConfiguration::default());
  }
  
  let config: AppFlowyYamlConfiguration = serde_yaml::from_str(&contents).map_err(|e| {
    error!("Failed to parse appflowy.yaml: {}", e);
    e
  })?;
  
  Ok(config)
}

fn write_yaml_file(
  file_path: impl AsRef<Path>,
  config: &AppFlowyYamlConfiguration,
) -> Result<(), Box<dyn std::error::Error>> {
  let yaml_string = serde_yaml::to_string(config)?;
  
  let path = file_path.as_ref();
  
  // Use a temporary file for atomic write to prevent corruption
  let temp_path = path.with_extension("yaml.tmp");
  
  {
    let mut file = OpenOptions::new()
      .create(true)
      .write(true)
      .truncate(true)
      .open(&temp_path)?;
    file.write_all(yaml_string.as_bytes())?;
    file.sync_all()?;
  }
  
  // Rename temp file to actual file (atomic on most filesystems)
  std::fs::rename(&temp_path, path).or_else(|_| {
    // Fallback: direct write if rename fails (e.g., cross-device)
    let mut file = OpenOptions::new()
      .create(true)
      .write(true)
      .truncate(true)
      .open(path)?;
    file.write_all(yaml_string.as_bytes())?;
    file.sync_all()?;
    // Clean up temp file if it exists
    let _ = std::fs::remove_file(&temp_path);
    Ok(())
  })?;
  
  Ok(())
}