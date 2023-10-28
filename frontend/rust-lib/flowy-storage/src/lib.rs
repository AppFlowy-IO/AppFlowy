use bytes::Bytes;

use flowy_error::FlowyError;
use lib_infra::future::FutureResult;

pub struct StorageObject {
  pub workspace_id: String,
  pub file_name: String,
  pub value: ObjectValue,
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
      value: ObjectValue::File {
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
      value: ObjectValue::Bytes { bytes, mime },
    }
  }

  /// Gets the file size of the `StorageObject`.
  ///
  /// # Returns
  ///
  /// The file size in bytes.
  pub fn file_size(&self) -> u64 {
    match &self.value {
      ObjectValue::File { file_path } => std::fs::metadata(file_path).unwrap().len(),
      ObjectValue::Bytes { bytes, .. } => bytes.len() as u64,
    }
  }
}

pub enum ObjectValue {
  File { file_path: String },
  Bytes { bytes: Bytes, mime: String },
}

impl ObjectValue {
  pub fn mime_type(&self) -> String {
    match self {
      ObjectValue::File { file_path } => mime_guess::from_path(file_path)
        .first_or_octet_stream()
        .to_string(),
      ObjectValue::Bytes { mime, .. } => mime.clone(),
    }
  }
}

/// Provides a service for storing and managing files.
///
/// The trait includes methods for CRUD operations on storage objects.
pub trait FileStorageService: Send + Sync + 'static {
  /// Creates a new storage object.
  ///
  /// # Parameters
  /// - `object`: The object to be stored.
  ///
  /// # Returns
  /// - `Ok(String)`: A url representing some kind of object identifier.
  /// - `Err(Error)`: An error occurred during the operation.
  fn create_object(&self, object: StorageObject) -> FutureResult<String, FlowyError>;

  /// Deletes a storage object by its URL.
  ///
  /// # Parameters
  /// - `object_url`: The URL of the object to be deleted.
  ///
  fn delete_object_by_url(&self, object_url: String) -> FutureResult<(), FlowyError>;

  /// Fetches a storage object by its URL.
  ///
  /// # Parameters
  /// - `object_url`: The URL of the object to be fetched.
  ///
  fn get_object_by_url(&self, object_url: String) -> FutureResult<Bytes, FlowyError>;
}

pub trait FileStoragePlan: Send + Sync + 'static {
  fn storage_size(&self) -> FutureResult<u64, FlowyError>;
  fn maximum_file_size(&self) -> FutureResult<u64, FlowyError>;

  fn check_upload_object(&self, object: &StorageObject) -> FutureResult<(), FlowyError>;
}
