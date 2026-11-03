use lib_infra::file_util::{unzip_and_replace, zip_folder};
use std::fs::{self, File};
use std::io::Write;
use std::path::PathBuf;
use tempfile::tempdir;

#[test]
fn zip_and_unzip_folder_with_nested_files() {
  let src_dir = tempdir().unwrap();
  let nested_dir = src_dir.path().join("nested");
  fs::create_dir_all(&nested_dir).unwrap();

  let file_path = nested_dir.join("test.txt");
  let mut file = File::create(&file_path).unwrap();
  writeln!(file, "hello world").unwrap();

  let zip_path = src_dir.path().join("archive.zip");
  zip_folder(src_dir.path(), &zip_path).unwrap();

  let restore_dir = src_dir.path().join("restored");
  unzip_and_replace(&zip_path, &restore_dir).unwrap();

  let restored_file = restore_dir.join("nested").join("test.txt");
  let contents = fs::read_to_string(restored_file).unwrap();
  assert!(contents.contains("hello world"));
}

#[test]
fn zip_folder_rejects_same_source_and_destination() {
  let src_dir = tempdir().unwrap();
  let zip_path = src_dir.path().join("archive.zip");
  let result = zip_folder(src_dir.path(), &src_dir.path().to_path_buf());
  assert!(result.is_err());
}
