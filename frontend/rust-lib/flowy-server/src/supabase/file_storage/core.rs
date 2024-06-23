#![allow(clippy::all)]
#![allow(unknown_lints)]
#![allow(unused_attributes)]
use std::sync::Weak;

use anyhow::{anyhow, Error};
use url::Url;

use crate::AppFlowyEncryption;
use flowy_encrypt::{decrypt_data, encrypt_data};

#[allow(dead_code)]
struct ObjectEncryption {
  encryption: Weak<dyn AppFlowyEncryption>,
}

impl ObjectEncryption {
  #[allow(dead_code)]
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
