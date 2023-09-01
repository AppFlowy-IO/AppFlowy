use anyhow::Error;
use anyhow::Result;
use serde_json::Value;

use flowy_encrypt::{decrypt_data, encrypt_data};

#[derive(Default)]
pub struct InsertParamsBuilder {
  map: serde_json::Map<String, Value>,
}

impl InsertParamsBuilder {
  pub fn new() -> Self {
    Self::default()
  }

  pub fn insert<T: serde::Serialize>(mut self, key: &str, value: T) -> Self {
    self
      .map
      .insert(key.to_string(), serde_json::to_value(value).unwrap());
    self
  }

  pub fn build(self) -> String {
    serde_json::to_string(&self.map).unwrap()
  }
}

/// An encoder for binary columns in Supabase.
///
/// Provides utilities to encode binary data into a format suitable for Supabase columns.
pub struct SupabaseBinaryColumnEncoder;

impl SupabaseBinaryColumnEncoder {
  /// Encodes the given binary data into a Supabase-friendly string representation.
  ///
  /// # Parameters
  /// - `value`: The binary data to encode.
  ///
  /// # Returns
  /// Returns the encoded string in the format: `\\xHEX_ENCODED_STRING`
  pub fn encode<T: AsRef<[u8]>>(
    value: T,
    encryption_secret: &Option<String>,
  ) -> Result<(String, i32)> {
    let encrypt = if encryption_secret.is_some() { 1 } else { 0 };
    let value = match encryption_secret {
      None => hex::encode(value),
      Some(encryption_secret) => {
        let encrypt_data = encrypt_data(value, encryption_secret)?;
        hex::encode(encrypt_data)
      },
    };

    Ok((format!("\\x{}", value), encrypt))
  }
}

/// A decoder for binary columns in Supabase.
///
/// Provides utilities to decode a string from Supabase columns back into binary data.
pub struct SupabaseBinaryColumnDecoder;

impl SupabaseBinaryColumnDecoder {
  /// Decodes a Supabase binary column string into binary data.
  ///
  /// # Parameters
  /// - `value`: The string representation from a Supabase binary column.
  ///
  /// # Returns
  /// Returns an `Option` containing the decoded binary data if decoding is successful.
  /// Otherwise, returns `None`.
  pub fn decode<T: AsRef<str>, D: HexDecoder>(
    value: T,
    encrypt: i32,
    encryption_secret: &Option<String>,
  ) -> Result<Vec<u8>> {
    let s = value
      .as_ref()
      .strip_prefix("\\x")
      .ok_or(anyhow::anyhow!("Value is not start with: \\x",))?;

    if encrypt == 0 {
      let bytes = D::decode(s)?;
      Ok(bytes)
    } else {
      match encryption_secret {
        None => Err(anyhow::anyhow!(
          "encryption_secret is None, but encrypt is 1"
        )),
        Some(encryption_secret) => {
          let encrypt_data = D::decode(s)?;
          decrypt_data(encrypt_data, encryption_secret)
        },
      }
    }
  }
}

pub trait HexDecoder {
  fn decode<T: AsRef<[u8]>>(data: T) -> Result<Vec<u8>, Error>;
}

pub struct RealtimeBinaryColumnDecoder;
impl HexDecoder for RealtimeBinaryColumnDecoder {
  fn decode<T: AsRef<[u8]>>(data: T) -> Result<Vec<u8>, Error> {
    // The realtime event binary column string is encoded twice. So it needs to be decoded twice.
    let bytes = hex::decode(data)?;
    let bytes = hex::decode(bytes)?;
    Ok(bytes)
  }
}

pub struct BinaryColumnDecoder;
impl HexDecoder for BinaryColumnDecoder {
  fn decode<T: AsRef<[u8]>>(data: T) -> Result<Vec<u8>, Error> {
    let bytes = hex::decode(data)?;
    Ok(bytes)
  }
}
