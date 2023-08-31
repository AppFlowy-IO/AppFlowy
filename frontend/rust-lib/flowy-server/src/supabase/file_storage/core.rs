use anyhow::Error;
use bytes::Bytes;
use reqwest::{
  header::{HeaderMap, HeaderValue},
  Client,
};
use url::Url;

use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_storage::core::{FileStorageService, StorageObject};
use lib_infra::async_trait::async_trait;

use crate::response::ExtendedResponse;
use crate::supabase::file_storage::builder::StorageRequestBuilder;

pub struct SupabaseFileStorage {
  url: Url,
  headers: HeaderMap,
  client: Client,
}

impl SupabaseFileStorage {
  pub fn new(config: &SupabaseConfiguration) -> Result<Self, Error> {
    let mut headers = HeaderMap::new();
    let url = format!("{}/storage/v1", config.url);
    let auth = format!("Bearer {}", config.anon_key);

    headers.insert(
      "Authorization",
      HeaderValue::from_str(&auth).expect("Authorization is invalid"),
    );
    headers.insert(
      "apikey",
      HeaderValue::from_str(&config.anon_key).expect("apikey value is invalid"),
    );

    Ok(Self {
      url: Url::parse(&url)?,
      headers,
      client: Client::new(),
    })
  }

  pub fn storage(&self) -> StorageRequestBuilder {
    StorageRequestBuilder::new(self.url.clone(), self.headers.clone(), self.client.clone())
  }
}

#[async_trait]
impl FileStorageService for SupabaseFileStorage {
  async fn create_object(&self, object: StorageObject) -> Result<String, Error> {
    let mut storage = self.storage().upload_object("data", object);
    let url = storage.url.to_string();
    let _ = storage.build().await?.send().await?.success().await?;
    Ok(url)
  }

  async fn delete_object(&self, object_name: &str) -> Result<(), Error> {
    let resp = self
      .storage()
      .delete_object("data", object_name)
      .build()
      .await?
      .send()
      .await?
      .success()
      .await?;
    println!("{:?}", resp);
    Ok(())
  }

  async fn get_object(&self, object_name: &str) -> Result<Bytes, Error> {
    let bytes = self
      .storage()
      .get_object("data", object_name)
      .build()
      .await?
      .send()
      .await?
      .get_bytes()
      .await?;
    Ok(bytes)
  }
}
