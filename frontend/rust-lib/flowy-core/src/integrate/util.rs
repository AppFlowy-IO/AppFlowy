use std::fs::{self};
use std::io;
use std::path::Path;

use walkdir::WalkDir;

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
