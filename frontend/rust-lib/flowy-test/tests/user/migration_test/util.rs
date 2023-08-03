use flowy_test::Cleaner;
use nanoid::nanoid;
use std::fs::{create_dir_all, File};
use std::io::copy;
use std::path::{Path, PathBuf};
use zip::ZipArchive;

pub fn unzip_history_user_db(folder_name: &str) -> std::io::Result<(Cleaner, PathBuf)> {
  // Open the zip file
  let zip_file_path = format!(
    "./tests/user/migration_test/history_user_db/{}.zip",
    folder_name
  );
  let reader = File::open(zip_file_path)?;
  let output_folder_path = format!(
    "./tests/user/migration_test/history_user_db/unit_test_{}",
    nanoid!(6)
  );

  // Create a ZipArchive from the file
  let mut archive = ZipArchive::new(reader)?;

  // Iterate through each file in the zip
  for i in 0..archive.len() {
    let mut file = archive.by_index(i)?;
    let output_path = Path::new(&output_folder_path).join(file.mangled_name());

    if file.name().ends_with('/') {
      // Create directory
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
  Ok((
    Cleaner::new(PathBuf::from(output_folder_path)),
    PathBuf::from(path),
  ))
}
