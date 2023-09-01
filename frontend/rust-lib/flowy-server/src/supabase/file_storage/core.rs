use std::sync::{Arc, Weak};

use anyhow::{anyhow, Error};
use bytes::Bytes;
use reqwest::{
  header::{HeaderMap, HeaderValue},
  Client,
};
use url::Url;

use flowy_server_config::supabase_config::SupabaseConfiguration;
use flowy_storage::error::FileStorageError;
use flowy_storage::{FileStoragePlan, FileStorageService, StorageObject};
use lib_infra::future::FutureResult;

use crate::response::ExtendedResponse;
use crate::supabase::file_storage::builder::StorageRequestBuilder;
use crate::AppFlowyEncryption;

pub struct SupabaseFileStorage {
  url: Url,
  headers: HeaderMap,
  client: Client,
  encryption: Weak<dyn AppFlowyEncryption>,
  storage_plan: Arc<dyn FileStoragePlan>,
}

impl SupabaseFileStorage {
  pub fn new(
    config: &SupabaseConfiguration,
    encryption: Weak<dyn AppFlowyEncryption>,
    storage_plan: Arc<dyn FileStoragePlan>,
  ) -> Result<Self, Error> {
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
      encryption,
      storage_plan,
    })
  }

  pub fn storage(&self) -> StorageRequestBuilder {
    StorageRequestBuilder::new(self.url.clone(), self.headers.clone(), self.client.clone())
  }
}

impl FileStorageService for SupabaseFileStorage {
  fn create_object(&self, object: StorageObject) -> FutureResult<String, FileStorageError> {
    let mut storage = self.storage();
    let storage_plan = Arc::downgrade(&self.storage_plan);

    FutureResult::new(async move {
      let plan = storage_plan
        .upgrade()
        .ok_or(anyhow!("Storage plan is not available"))?;
      plan.check_upload_object(&object).await?;

      storage = storage.upload_object("data", object);
      let url = storage.url.to_string();
      let _ = storage.build().await?.send().await?.success().await?;
      Ok(url)
    })
  }

  fn delete_object_by_url(&self, object_url: &str) -> FutureResult<(), FileStorageError> {
    let object_url = object_url.to_string();
    let storage = self.storage();

    FutureResult::new(async move {
      let url = Url::parse(&object_url)?;
      let location = get_object_location_from(&url)?;
      storage
        .delete_object(location.bucket_id, location.file_name)
        .build()
        .await?
        .send()
        .await?
        .success()
        .await?;
      Ok(())
    })
  }

  fn get_object_by_url(&self, object_url: &str) -> FutureResult<Bytes, FileStorageError> {
    let object_url = object_url.to_string();
    let storage = self.storage();
    FutureResult::new(async move {
      let url = Url::parse(&object_url)?;
      let location = get_object_location_from(&url)?;
      let bytes = storage
        .get_object(location.bucket_id, location.file_name)
        .build()
        .await?
        .send()
        .await?
        .get_bytes()
        .await?;
      Ok(bytes)
    })
  }
}

struct ObjectLocation<'a> {
  bucket_id: &'a str,
  file_name: &'a str,
}

fn get_object_location_from(url: &Url) -> Result<ObjectLocation, Error> {
  let mut segments = url
    .path_segments()
    .ok_or(anyhow!("Invalid object url: {}", url))?
    .collect::<Vec<_>>();

  let file_name = segments
    .pop()
    .ok_or(anyhow!("Can't get file name from url: {}", url))?;
  let bucket_id = segments
    .pop()
    .ok_or(anyhow!("Can't get bucket id from url: {}", url))?;

  Ok(ObjectLocation {
    bucket_id,
    file_name,
  })
}
