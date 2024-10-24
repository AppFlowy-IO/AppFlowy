use nanoid::nanoid;
use std::env::temp_dir;
use std::fs::{create_dir_all, File, OpenOptions};
use std::io::copy;
use std::ops::Deref;
use std::path::{Path, PathBuf};
use std::time::Duration;
use std::{fs, io};
use tokio::sync::mpsc::Receiver;
use tokio::time::timeout;
use uuid::Uuid;
use walkdir::WalkDir;
use zip::write::FileOptions;
use zip::{CompressionMethod, ZipArchive, ZipWriter};

use event_integration_test::event_builder::EventBuilder;

use event_integration_test::EventIntegrationTest;
use flowy_folder::entities::{ImportPayloadPB, ImportTypePB, ImportValuePayloadPB, ViewLayoutPB};
use flowy_user::entities::UpdateUserProfilePayloadPB;
use flowy_user::errors::FlowyError;
use flowy_user::event_map::UserEvent::*;

pub struct FlowySupabaseTest {
  event_test: EventIntegrationTest,
}

impl FlowySupabaseTest {
  pub async fn new() -> Option<Self> {
    let event_test = EventIntegrationTest::new().await;
    Some(Self { event_test })
  }

  pub async fn update_user_profile(
    &self,
    payload: UpdateUserProfilePayloadPB,
  ) -> Option<FlowyError> {
    EventBuilder::new(self.event_test.clone())
      .event(UpdateUserProfile)
      .payload(payload)
      .async_send()
      .await
      .error()
  }
}

impl Deref for FlowySupabaseTest {
  type Target = EventIntegrationTest;

  fn deref(&self) -> &Self::Target {
    &self.event_test
  }
}

pub async fn receive_with_timeout<T>(mut receiver: Receiver<T>, duration: Duration) -> Option<T> {
  timeout(duration, receiver.recv()).await.ok()?
}

/// zip the asset to the destination
/// Zips the specified directory into a zip file.
///
/// # Arguments
/// - `src_dir`: Path to the directory to zip.
/// - `output_file`: Path to the output zip file.
///
/// # Errors
/// Returns `io::Result<()>` indicating the operation's success or failure.
pub fn zip(src_dir: PathBuf, output_file_path: PathBuf) -> io::Result<()> {
  // Ensure the output directory exists
  if let Some(parent) = output_file_path.parent() {
    if !parent.exists() {
      fs::create_dir_all(parent)?;
    }
  }

  // Open or create the output file, truncating it if it exists
  let file = OpenOptions::new()
    .create(true)
    .write(true)
    .truncate(true)
    .open(&output_file_path)?;

  let options = FileOptions::<()>::default().compression_method(CompressionMethod::Deflated);

  let mut zip = ZipWriter::new(file);

  // Calculate the name of the new folder within the ZIP file based on the last component of the output path
  let new_folder_name = output_file_path
    .file_stem()
    .and_then(|name| name.to_str())
    .ok_or_else(|| io::Error::new(io::ErrorKind::Other, "Invalid output file name"))?;

  let src_dir_str = src_dir.to_str().expect("Invalid source directory path");

  for entry in WalkDir::new(&src_dir).into_iter().filter_map(|e| e.ok()) {
    let path = entry.path();
    let relative_path = path
      .strip_prefix(src_dir_str)
      .map_err(|_| io::Error::new(io::ErrorKind::Other, "Error calculating relative path"))?;

    // Construct the path within the ZIP, prefixing with the new folder's name
    let zip_path = Path::new(new_folder_name).join(relative_path);

    if path.is_file() {
      zip.start_file(
        zip_path
          .to_str()
          .ok_or_else(|| io::Error::new(io::ErrorKind::Other, "Invalid file name"))?,
        options,
      )?;

      let mut f = File::open(path)?;
      io::copy(&mut f, &mut zip)?;
    } else if entry.file_type().is_dir() && !relative_path.as_os_str().is_empty() {
      zip.add_directory(
        zip_path
          .to_str()
          .ok_or_else(|| io::Error::new(io::ErrorKind::Other, "Invalid directory name"))?,
        options,
      )?;
    }
  }
  zip.finish()?;
  Ok(())
}
pub fn unzip_test_asset(folder_name: &str) -> io::Result<PathBuf> {
  unzip("./tests/asset", folder_name)
}

pub fn unzip(test_asset_dir: &str, folder_name: &str) -> io::Result<PathBuf> {
  // Open the zip file
  let zip_file_path = format!("{}/{}.zip", test_asset_dir, folder_name);
  let reader = File::open(zip_file_path)?;
  // let output_folder_path = format!("{}/unit_test_{}", test_asset_dir, nanoid!(6));
  let output_folder_path = temp_dir().join(nanoid!(6)).to_str().unwrap().to_string();

  // Create a ZipArchive from the file
  let mut archive = ZipArchive::new(reader)?;
  for i in 0..archive.len() {
    let mut file = archive.by_index(i)?;
    let output_path = Path::new(&output_folder_path).join(file.mangled_name());
    if file.name().ends_with('/') {
      create_dir_all(&output_path)?;
    } else {
      // Write file
      if let Some(p) = output_path.parent() {
        if !p.exists() {
          create_dir_all(p)?;
        }
      }
      let mut outfile = File::create(&output_path)?;
      copy(&mut file, &mut outfile)?;
    }
  }
  let path = format!("{}/{}", output_folder_path, folder_name);
  Ok(PathBuf::from(path))
}

pub fn generate_test_email() -> String {
  format!("{}@test.com", Uuid::new_v4())
}

pub fn gen_csv_import_data(file_name: &str, workspace_id: &str) -> ImportPayloadPB {
  let file_path = unzip("./tests/asset", file_name).unwrap();
  ImportPayloadPB {
    parent_view_id: workspace_id.to_string(),
    values: vec![ImportValuePayloadPB {
      name: file_name.to_string(),
      data: None,
      file_path: Some(file_path.to_str().unwrap().to_string()),
      view_layout: ViewLayoutPB::Grid,
      import_type: ImportTypePB::CSV,
    }],
  }
}
