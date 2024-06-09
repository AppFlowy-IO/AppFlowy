use std::sync::{Arc, Weak};

use anyhow::{anyhow, Error};
use reqwest::{
  header::{HeaderMap, HeaderValue},
  Client,
};
use url::Url;

use flowy_encrypt::{decrypt_data, encrypt_data};
use flowy_error::FlowyError;
use flowy_server_pub::supabase_config::SupabaseConfiguration;
use flowy_storage::{FileStoragePlan, ObjectStorageService};
use lib_infra::future::FutureResult;

use crate::supabase::file_storage::builder::StorageRequestBuilder;
use crate::AppFlowyEncryption;

pub struct SupabaseFileStorage {
  url: Url,
  headers: HeaderMap,
  client: Client,
  #[allow(dead_code)]
  encryption: ObjectEncryption,
  #[allow(dead_code)]
  storage_plan: Arc<dyn FileStoragePlan>,
}

impl ObjectStorageService for SupabaseFileStorage {
  fn get_object_url(
    &self,
    _object_id: flowy_storage::ObjectIdentity,
  ) -> FutureResult<String, FlowyError> {
    todo!()
  }

  fn put_object(
    &self,
    _url: String,
    _object_value: flowy_storage::ObjectValue,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn delete_object(&self, _url: String) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn get_object(&self, _url: String) -> FutureResult<flowy_storage::ObjectValue, FlowyError> {
    todo!()
  }

  // fn create_object(&self, object: StorageObject) -> FutureResult<String, FlowyError> {
  //   let mut storage = self.storage();
  //   let storage_plan = Arc::downgrade(&self.storage_plan);

  //   FutureResult::new(async move {
  //     let plan = storage_plan
  //       .upgrade()
  //       .ok_or(anyhow!("Storage plan is not available"))?;
  //     plan.check_upload_object(&object).await?;

  //     storage = storage.upload_object("data", object);
  //     let url = storage.url.to_string();
  //     storage.build().await?.send().await?.success().await?;
  //     Ok(url)
  //   })
  // }

  // fn delete_object_by_url(&self, object_url: String) -> FutureResult<(), FlowyError> {
  //   let storage = self.storage();

  //   FutureResult::new(async move {
  //     let url = Url::parse(&object_url)?;
  //     let location = get_object_location_from(&url)?;
  //     storage
  //       .delete_object(location.bucket_id, location.file_name)
  //       .build()
  //       .await?
  //       .send()
  //       .await?
  //       .success()
  //       .await?;
  //     Ok(())
  //   })
  // }

  // fn get_object_by_url(&self, object_url: String) -> FutureResult<Bytes, FlowyError> {
  //   let storage = self.storage();
  //   FutureResult::new(async move {
  //     let url = Url::parse(&object_url)?;
  //     let location = get_object_location_from(&url)?;
  //     let bytes = storage
  //       .get_object(location.bucket_id, location.file_name)
  //       .build()
  //       .await?
  //       .send()
  //       .await?
  //       .get_bytes()
  //       .await?;
  //     Ok(bytes)
  //   })
  // }
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

    let encryption = ObjectEncryption::new(encryption);
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

#[allow(dead_code)]
struct ObjectEncryption {
  encryption: Weak<dyn AppFlowyEncryption>,
}

impl ObjectEncryption {
  fn new(encryption: Weak<dyn AppFlowyEncryption>) -> Self {
    Self { encryption }
  }

  #[allow(dead_code)]
  fn encrypt(&self, object_data: Vec<u8>) -> Result<Vec<u8>, Error> {
    if let Some(secret) = self
      .encryption
      .upgrade()
      .and_then(|encryption| encryption.get_secret())
    {
      let encryption_data = encrypt_data(object_data, &secret)?;
      Ok(encryption_data)
    } else {
      Ok(object_data)
    }
  }

  #[allow(dead_code)]
  fn decrypt(&self, object_data: Vec<u8>) -> Result<Vec<u8>, Error> {
    if let Some(secret) = self
      .encryption
      .upgrade()
      .and_then(|encryption| encryption.get_secret())
    {
      let decryption_data = decrypt_data(object_data, &secret)?;
      Ok(decryption_data)
    } else {
      Ok(object_data)
    }
  }
}

#[allow(dead_code)]
struct ObjectLocation<'a> {
  bucket_id: &'a str,
  file_name: &'a str,
}

#[allow(dead_code)]
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
