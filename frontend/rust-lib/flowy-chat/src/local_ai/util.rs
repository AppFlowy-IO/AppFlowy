use anyhow::Result;
use sha2::Digest;
use std::fs;
use std::fs::{create_dir_all, remove_dir_all, File};
use std::io::{BufReader, Read, Write};
use std::path::Path;
use zip::ZipArchive;

pub fn bytes_to_readable_size(bytes: u64) -> String {
  const GB: u64 = 1_000_000_000;
  const MB: u64 = 1_000_000;

  if bytes >= GB {
    let size_in_gb = bytes as f64 / GB as f64;
    format!("{:.2} GB", size_in_gb)
  } else {
    let size_in_mb = bytes as f64 / MB as f64;
    format!("{:.2} MB", size_in_mb)
  }
}
pub async fn unzip_file(zip_path: impl AsRef<Path>, destination_path: &Path) -> Result<()> {
  // Remove the destination directory if it exists and create a new one
  if destination_path.exists() {
    // remove_dir_all(destination_path)?;
  }
  create_dir_all(destination_path)?;

  // Open the zip file
  let file = File::open(zip_path)?;
  let mut archive = ZipArchive::new(BufReader::new(file))?;

  // Iterate over each file in the archive and extract it
  for i in 0..archive.len() {
    let mut file = archive.by_index(i)?;
    let outpath = destination_path.join(file.name());

    if file.name().ends_with('/') {
      create_dir_all(&outpath)?;
    } else {
      if let Some(p) = outpath.parent() {
        if !p.exists() {
          create_dir_all(&p)?;
        }
      }
      let mut outfile = fs::File::create(&outpath)?;
      let mut buffer = Vec::new();
      file.read_to_end(&mut buffer)?;
      outfile.write_all(&buffer)?;
    }
  }

  Ok(())
}
