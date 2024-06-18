use std::path::{Path, PathBuf};
use tokio::fs::{self, File};
use tokio::io::{self, AsyncReadExt, AsyncWriteExt};
use tracing::error;

/// [FileTempStorage] is used to store the temporary files for uploading. After the file is uploaded,
/// the file will be deleted.
pub struct FileTempStorage {
  storage_dir: PathBuf,
}

impl FileTempStorage {
  /// Creates a new `FileTempStorage` with the specified temporary directory.
  pub fn new(storage_dir: PathBuf) -> Self {
    if !storage_dir.exists() {
      if let Err(err) = std::fs::create_dir_all(&storage_dir) {
        error!("Failed to create temporary storage directory: {:?}", err);
      }
    }

    FileTempStorage { storage_dir }
  }

  /// Generates a temporary file path using the given file name.
  fn generate_temp_file_path_with_name(&self, file_name: &str) -> PathBuf {
    self.storage_dir.join(file_name)
  }

  /// Creates a temporary file from an existing local file path.
  pub async fn create_temp_file_from_existing(
    &self,
    existing_file_path: &Path,
  ) -> io::Result<String> {
    let file_name = existing_file_path
      .file_name()
      .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "Invalid file name"))?
      .to_str()
      .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "Invalid file name"))?;

    let temp_file_path = self.generate_temp_file_path_with_name(file_name);
    fs::copy(existing_file_path, &temp_file_path).await?;
    Ok(
      temp_file_path
        .to_str()
        .ok_or(io::Error::new(
          io::ErrorKind::InvalidInput,
          "Invalid file path",
        ))?
        .to_owned(),
    )
  }

  /// Creates a temporary file from bytes and a specified file name.
  pub async fn create_temp_file_from_bytes(
    &self,
    file_name: &str,
    data: &[u8],
  ) -> io::Result<PathBuf> {
    let temp_file_path = self.generate_temp_file_path_with_name(file_name);
    let mut file = File::create(&temp_file_path).await?;
    file.write_all(data).await?;
    Ok(temp_file_path)
  }

  /// Writes data to the specified temporary file.
  pub async fn write_to_temp_file(&self, file_path: &Path, data: &[u8]) -> io::Result<()> {
    let mut file = File::create(file_path).await?;
    file.write_all(data).await?;
    Ok(())
  }

  /// Reads data from the specified temporary file.
  pub async fn read_from_temp_file(&self, file_path: &Path) -> io::Result<Vec<u8>> {
    let mut file = File::open(file_path).await?;
    let mut data = Vec::new();
    file.read_to_end(&mut data).await?;
    Ok(data)
  }

  /// Deletes the specified temporary file.
  pub async fn delete_temp_file<T: AsRef<Path>>(&self, file_path: T) -> io::Result<()> {
    fs::remove_file(file_path).await?;
    Ok(())
  }
}
