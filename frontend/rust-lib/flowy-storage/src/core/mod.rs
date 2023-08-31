use anyhow::Error;
use async_trait::async_trait;
use bytes::Bytes;

#[async_trait]
pub trait FileStorageService: Send + Sync + 'static {
  async fn create_object(&self, object_name: &str, object_path: &str) -> Result<String, Error>;
  async fn delete_object(&self, object_name: &str) -> Result<(), Error>;
  async fn get_object(&self, object_name: &str) -> Result<Bytes, Error>;
}
