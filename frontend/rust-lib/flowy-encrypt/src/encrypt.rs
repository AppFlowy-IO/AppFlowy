use aes_gcm::aead::generic_array::GenericArray;
use aes_gcm::aead::Aead;
use aes_gcm::{Aes256Gcm, KeyInit};
use anyhow::Result;
use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use pbkdf2::hmac::Hmac;
use pbkdf2::pbkdf2;
use rand::distributions::Alphanumeric;
use rand::Rng;
use sha2::Sha256;

const SALT_LENGTH: usize = 16;
const KEY_LENGTH: usize = 32;
const ITERATIONS: u32 = 100_000;
const NONCE_LENGTH: usize = 12;
const CONCATENATED_DELIMITER: &str = "$";

pub fn generate_encrypt_secret() -> String {
  let passphrase = generate_passphrase();
  let salt = generate_salt();
  concatenate_passphrase_and_salt(&passphrase, &salt)
}

pub fn encrypt(data: &[u8], combined_passphrase_salt: &str) -> Result<Vec<u8>> {
  let (passphrase, salt) = split_passphrase_and_salt(combined_passphrase_salt)?;
  let key = derive_key(passphrase, &salt)?;
  let cipher = Aes256Gcm::new(GenericArray::from_slice(&key));
  let nonce: [u8; NONCE_LENGTH] = rand::thread_rng().gen();
  let ciphertext = cipher
    .encrypt(GenericArray::from_slice(&nonce), data)
    .unwrap();

  Ok(nonce.into_iter().chain(ciphertext).collect())
}

pub fn decrypt(data: &[u8], combined_passphrase_salt: &str) -> Result<Vec<u8>> {
  if data.len() <= NONCE_LENGTH {
    return Err(anyhow::anyhow!("Ciphertext too short to include nonce."));
  }
  let (passphrase, salt) = split_passphrase_and_salt(combined_passphrase_salt)?;
  let key = derive_key(passphrase, &salt)?;
  let cipher = Aes256Gcm::new(GenericArray::from_slice(&key));
  let (nonce, ciphertext) = data.split_at(NONCE_LENGTH);
  cipher
    .decrypt(GenericArray::from_slice(nonce), ciphertext)
    .map_err(|e| anyhow::anyhow!("Decryption error: {:?}", e))
}

fn generate_passphrase() -> String {
  rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(30) // e.g., 30 characters
        .map(char::from)
        .collect()
}

fn generate_salt() -> [u8; SALT_LENGTH] {
  let mut rng = rand::thread_rng();
  let salt: [u8; SALT_LENGTH] = rng.gen();
  salt
}

fn concatenate_passphrase_and_salt(passphrase: &str, salt: &[u8; SALT_LENGTH]) -> String {
  let salt_base64 = STANDARD.encode(salt);
  format!("{}{}{}", passphrase, CONCATENATED_DELIMITER, salt_base64)
}

fn split_passphrase_and_salt(combined: &str) -> Result<(&str, [u8; SALT_LENGTH]), anyhow::Error> {
  let parts: Vec<&str> = combined.split(CONCATENATED_DELIMITER).collect();
  if parts.len() != 2 {
    return Err(anyhow::anyhow!("Invalid combined format"));
  }
  let passphrase = parts[0];
  let salt = STANDARD.decode(parts[1])?;
  if salt.len() != SALT_LENGTH {
    return Err(anyhow::anyhow!("Incorrect salt length"));
  }
  let mut salt_array = [0u8; SALT_LENGTH];
  salt_array.copy_from_slice(&salt);
  Ok((passphrase, salt_array))
}

fn derive_key(passphrase: &str, salt: &[u8; SALT_LENGTH]) -> Result<[u8; KEY_LENGTH]> {
  let mut key = [0u8; KEY_LENGTH];
  pbkdf2::<Hmac<Sha256>>(passphrase.as_bytes(), salt, ITERATIONS, &mut key)?;
  Ok(key)
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn test_encrypt_decrypt() {
    let secret = generate_encrypt_secret();
    let data = b"hello world";
    let encrypted = encrypt(data, &secret).unwrap();
    let decrypted = decrypt(&encrypted, &secret).unwrap();
    assert_eq!(data, decrypted.as_slice());
  }
}
