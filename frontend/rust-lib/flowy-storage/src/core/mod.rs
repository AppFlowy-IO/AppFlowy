use anyhow::Error;
use async_trait::async_trait;
use bytes::Bytes;

pub struct StorageObject {
  pub name: String,
  pub value: ObjectValue,
}

impl StorageObject {
  pub fn from_file<T: ToString>(name: &str, file_path: T) -> Self {
    Self {
      name: name.to_string(),
      value: ObjectValue::File {
        file_path: file_path.to_string(),
      },
    }
  }

  pub fn from_bytes(name: &str, bytes: Bytes, mime: String) -> Self {
    Self {
      name: name.to_string(),
      value: ObjectValue::Bytes { bytes, mime },
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

#[async_trait]
pub trait FileStorageService: Send + Sync + 'static {
  async fn create_object(&self, object: StorageObject) -> Result<String, Error>;
  async fn delete_object(&self, object_name: &str) -> Result<(), Error>;
  async fn get_object(&self, object_name: &str) -> Result<Bytes, Error>;
}
