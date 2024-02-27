use anyhow::Context;
use std::cmp::Ordering;
use std::fs::File;
use std::path::{Path, PathBuf};
use std::time::SystemTime;
use std::{fs, io};

use tempfile::tempdir;
use walkdir::WalkDir;
use zip::write::FileOptions;
use zip::ZipArchive;
use zip::ZipWriter;

pub fn copy_dir_recursive(src: &Path, dst: &Path) -> io::Result<()> {
  for entry in WalkDir::new(src).into_iter().filter_map(|e| e.ok()) {
    let path = entry.path();
    let relative_path = path.strip_prefix(src).unwrap();
    let target_path = dst.join(relative_path);

    if path.is_dir() {
      fs::create_dir_all(&target_path)?;
    } else {
      fs::copy(path, target_path)?;
    }
  }
  Ok(())
}

pub fn find_and_sort_folders_at<P>(path: &str, pat: P, order: Ordering) -> Vec<PathBuf>
where
  P: Fn(&str) -> bool,
{
  let mut folders = Vec::new();

  for entry in WalkDir::new(path)
    .min_depth(1)
    .max_depth(1)
    .into_iter()
    .filter_map(|e| e.ok())
  {
    let entry_path = entry.path().to_path_buf();

    if entry_path.is_dir()
      && entry_path
        .file_name()
        .unwrap_or_default()
        .to_str()
        .map(&pat)
        .unwrap_or(false)
    {
      let metadata = fs::metadata(&entry_path).ok();
      let modified_time = metadata
        .and_then(|m| m.modified().ok())
        .unwrap_or(SystemTime::UNIX_EPOCH);

      folders.push((entry_path, modified_time));
    }
  }

  // Sort folders based on the specified order
  folders.sort_by(|a, b| match order {
    Ordering::Less => a.1.cmp(&b.1),
    Ordering::Greater => b.1.cmp(&a.1),
    _ => a.1.cmp(&b.1), // Default case
  });

  // Extract just the PathBufs, discarding the modification times
  folders.into_iter().map(|(path, _)| path).collect()
}

pub fn zip_folder(src_path: impl AsRef<Path>, dest_path: &Path) -> io::Result<()> {
  if !src_path.as_ref().exists() {
    return Err(io::ErrorKind::NotFound.into());
  }

  if src_path.as_ref() == dest_path {
    return Err(io::ErrorKind::InvalidInput.into());
  }

  let file = File::create(dest_path)?;
  let mut zip = ZipWriter::new(file);
  let options = FileOptions::default().compression_method(zip::CompressionMethod::Deflated);

  for entry in WalkDir::new(&src_path) {
    let entry = entry?;
    let path = entry.path();
    let name = match path.strip_prefix(&src_path) {
      Ok(n) => n,
      Err(_) => return Err(io::Error::new(io::ErrorKind::Other, "Invalid path")),
    };

    if path.is_file() {
      zip.start_file(
        name
          .to_str()
          .ok_or_else(|| io::Error::new(io::ErrorKind::Other, "Invalid file name"))?,
        options,
      )?;
      let mut f = File::open(path)?;
      io::copy(&mut f, &mut zip)?;
    } else if !name.as_os_str().is_empty() {
      zip.add_directory(
        name
          .to_str()
          .ok_or_else(|| io::Error::new(io::ErrorKind::Other, "Invalid directory name"))?,
        options,
      )?;
    }
  }
  zip.finish()?;
  Ok(())
}

pub fn unzip_and_replace(
  zip_path: impl AsRef<Path>,
  target_folder: &Path,
) -> Result<(), anyhow::Error> {
  // Create a temporary directory for unzipping
  let temp_dir = tempdir()?;

  // Unzip the file
  let file = File::open(zip_path.as_ref())
    .context(format!("Can't find the zip file: {:?}", zip_path.as_ref()))?;
  let mut archive = ZipArchive::new(file).context("Unzip file fail")?;

  for i in 0..archive.len() {
    let mut file = archive.by_index(i)?;
    let outpath = temp_dir.path().join(file.mangled_name());

    if file.name().ends_with('/') {
      fs::create_dir_all(&outpath)?;
    } else {
      if let Some(p) = outpath.parent() {
        if !p.exists() {
          fs::create_dir_all(p)?;
        }
      }
      let mut outfile = File::create(&outpath)?;
      io::copy(&mut file, &mut outfile)?;
    }
  }

  // Replace the contents of the target folder
  if target_folder.exists() {
    fs::remove_dir_all(target_folder)
      .context(format!("Remove all files in {:?}", target_folder))?;
  }

  fs::create_dir_all(target_folder)?;
  for entry in fs::read_dir(temp_dir.path())? {
    let entry = entry?;
    fs::rename(entry.path(), target_folder.join(entry.file_name()))?;
  }

  Ok(())
}
