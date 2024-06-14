mod manager;
mod native;

use bytes::Bytes;
pub use native::*;

use flowy_error::FlowyError;
use lib_infra::future::FutureResult;
use mime::Mime;

pub struct ObjectIdentity {
  pub workspace_id: String,
  pub file_id: String,
  pub ext: String,
}

#[derive(Clone)]
pub struct ObjectValue {
  pub raw: Bytes,
  pub mime: Mime,
}
pub trait ObjectStorageCloudService: Send + Sync {
  /// Creates a new storage object.
  ///
  /// # Parameters
  /// - `url`: url of the object to be created.
  ///
  /// # Returns
  /// - `Ok()`
  /// - `Err(Error)`: An error occurred during the operation.
  fn get_object_url(&self, object_id: ObjectIdentity) -> FutureResult<String, FlowyError>;

  /// Creates a new storage object.
  ///
  /// # Parameters
  /// - `url`: url of the object to be created.
  ///
  /// # Returns
  /// - `Ok()`
  /// - `Err(Error)`: An error occurred during the operation.
  fn put_object(&self, url: String, object_value: ObjectValue) -> FutureResult<(), FlowyError>;

  /// Deletes a storage object by its URL.
  ///
  /// # Parameters
  /// - `url`: url of the object to be deleted.
  ///
  /// # Returns
  /// - `Ok()`
  /// - `Err(Error)`: An error occurred during the operation.
  fn delete_object(&self, url: String) -> FutureResult<(), FlowyError>;

  /// Fetches a storage object by its URL.
  ///
  /// # Parameters
  /// - `url`: url of the object
  ///
  /// # Returns
  /// - `Ok(File)`: The returned file object.
  /// - `Err(Error)`: An error occurred during the operation.
  fn get_object(&self, url: String) -> FutureResult<ObjectValue, FlowyError>;
}

pub trait FileStoragePlan: Send + Sync + 'static {
  fn storage_size(&self) -> FutureResult<u64, FlowyError>;
  fn maximum_file_size(&self) -> FutureResult<u64, FlowyError>;

  fn check_upload_object(&self, object: &StorageObject) -> FutureResult<(), FlowyError>;
}

pub struct StorageObject {
  pub workspace_id: String,
  pub file_name: String,
  pub value: ObjectValueSupabase,
}

pub enum ObjectValueSupabase {
  File { file_path: String },
  Bytes { bytes: Bytes, mime: String },
}

impl ObjectValueSupabase {
  pub fn mime_type(&self) -> String {
    match self {
      ObjectValueSupabase::File { file_path } => mime_guess::from_path(file_path)
        .first_or_octet_stream()
        .to_string(),
      ObjectValueSupabase::Bytes { mime, .. } => mime.clone(),
    }
  }
}

impl StorageObject {
  /// Creates a `StorageObject` from a file.
  ///
  /// # Parameters
  ///
  /// * `name`: The name of the storage object.
  /// * `file_path`: The file path to the storage object's data.
  ///
  pub fn from_file<T: ToString>(workspace_id: &str, file_name: &str, file_path: T) -> Self {
    Self {
      workspace_id: workspace_id.to_string(),
      file_name: file_name.to_string(),
      value: ObjectValueSupabase::File {
        file_path: file_path.to_string(),
      },
    }
  }

  /// Creates a `StorageObject` from bytes.
  ///
  /// # Parameters
  ///
  /// * `name`: The name of the storage object.
  /// * `bytes`: The byte data of the storage object.
  /// * `mime`: The MIME type of the storage object.
  ///
  pub fn from_bytes<B: Into<Bytes>>(
    workspace_id: &str,
    file_name: &str,
    bytes: B,
    mime: String,
  ) -> Self {
    let bytes = bytes.into();
    Self {
      workspace_id: workspace_id.to_string(),
      file_name: file_name.to_string(),
      value: ObjectValueSupabase::Bytes { bytes, mime },
    }
  }

  /// Gets the file size of the `StorageObject`.
  ///
  /// # Returns
  ///
  /// The file size in bytes.
  pub fn file_size(&self) -> u64 {
    match &self.value {
      ObjectValueSupabase::File { file_path } => std::fs::metadata(file_path).unwrap().len(),
      ObjectValueSupabase::Bytes { bytes, .. } => bytes.len() as u64,
    }
  }
}
