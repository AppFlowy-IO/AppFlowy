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

/// The length of the salt in bytes.
const SALT_LENGTH: usize = 16;

/// The length of the derived encryption key in bytes.
const KEY_LENGTH: usize = 32;

/// The number of iterations for the PBKDF2 key derivation.
const ITERATIONS: u32 = 1000;

/// The length of the nonce for AES-GCM encryption.
const NONCE_LENGTH: usize = 12;

/// Delimiter used to concatenate the passphrase and salt.
const CONCATENATED_DELIMITER: &str = "$";

/// Generate a new encryption secret consisting of a passphrase and a salt.
pub fn generate_encryption_secret() -> String {
  let passphrase = generate_random_passphrase();
  let salt = generate_random_salt();
  combine_passphrase_and_salt(&passphrase, &salt)
}

/// Encrypt a byte slice using AES-GCM.
///
/// # Arguments
/// * `data`: The data to encrypt.
/// * `combined_passphrase_salt`: The concatenated passphrase and salt.
pub fn encrypt_data<T: AsRef<[u8]>>(data: T, combined_passphrase_salt: &str) -> Result<Vec<u8>> {
  let (passphrase, salt) = split_passphrase_and_salt(combined_passphrase_salt)?;
  let key = derive_key(passphrase, &salt)?;
  let cipher = Aes256Gcm::new(GenericArray::from_slice(&key));
  let nonce: [u8; NONCE_LENGTH] = rand::thread_rng().gen();
  let ciphertext = cipher
    .encrypt(GenericArray::from_slice(&nonce), data.as_ref())
    .unwrap();

  Ok(nonce.into_iter().chain(ciphertext).collect())
}

/// Decrypt a byte slice using AES-GCM.
///
/// # Arguments
/// * `data`: The data to decrypt.
/// * `combined_passphrase_salt`: The concatenated passphrase and salt.
pub fn decrypt_data<T: AsRef<[u8]>>(data: T, combined_passphrase_salt: &str) -> Result<Vec<u8>> {
  if data.as_ref().len() <= NONCE_LENGTH {
    return Err(anyhow::anyhow!("Ciphertext too short to include nonce."));
  }
  let (passphrase, salt) = split_passphrase_and_salt(combined_passphrase_salt)?;
  let key = derive_key(passphrase, &salt)?;
  let cipher = Aes256Gcm::new(GenericArray::from_slice(&key));
  let (nonce, cipher_data) = data.as_ref().split_at(NONCE_LENGTH);
  cipher
    .decrypt(GenericArray::from_slice(nonce), cipher_data)
    .map_err(|e| anyhow::anyhow!("Decryption error: {:?}", e))
}

/// Encrypt a string using AES-GCM and return the result as a base64 encoded string.
///
/// # Arguments
/// * `data`: The string data to encrypt.
/// * `combined_passphrase_salt`: The concatenated passphrase and salt.
pub fn encrypt_text<T: AsRef<[u8]>>(data: T, combined_passphrase_salt: &str) -> Result<String> {
  let encrypted = encrypt_data(data.as_ref(), combined_passphrase_salt)?;
  Ok(STANDARD.encode(encrypted))
}

/// Decrypt a base64 encoded string using AES-GCM.
///
/// # Arguments
/// * `data`: The base64 encoded string to decrypt.
/// * `combined_passphrase_salt`: The concatenated passphrase and salt.
pub fn decrypt_text<T: AsRef<[u8]>>(data: T, combined_passphrase_salt: &str) -> Result<String> {
  let encrypted = STANDARD.decode(data)?;
  let decrypted = decrypt_data(encrypted, combined_passphrase_salt)?;
  Ok(String::from_utf8(decrypted)?)
}

/// Generates a random passphrase consisting of alphanumeric characters.
///
/// This function creates a passphrase with both uppercase and lowercase letters
/// as well as numbers. The passphrase is 30 characters in length.
///
/// # Returns
///
/// A `String` representing the generated passphrase.
///
/// # Security Considerations
///
///   The passphrase is derived from the `Alphanumeric` character set which includes 62 possible
///   characters (26 lowercase letters, 26 uppercase letters, 10 numbers). This results in a total
///   of `62^30` possible combinations, making it strong against brute force attacks.
///
fn generate_random_passphrase() -> String {
  rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(30) // e.g., 30 characters
        .map(char::from)
        .collect()
}

fn generate_random_salt() -> [u8; SALT_LENGTH] {
  let mut rng = rand::thread_rng();
  let salt: [u8; SALT_LENGTH] = rng.gen();
  salt
}

fn combine_passphrase_and_salt(passphrase: &str, salt: &[u8; SALT_LENGTH]) -> String {
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
  fn encrypt_decrypt_test() {
    let secret = generate_encryption_secret();
    let data = b"hello world";
    let encrypted = encrypt_data(data, &secret).unwrap();
    let decrypted = decrypt_data(encrypted, &secret).unwrap();
    assert_eq!(data, decrypted.as_slice());

    let s = "123".to_string();
    let encrypted = encrypt_text(&s, &secret).unwrap();
    let decrypted_str = decrypt_text(encrypted, &secret).unwrap();
    assert_eq!(s, decrypted_str);
  }

  #[test]
  fn decrypt_with_invalid_secret_test() {
    let secret = generate_encryption_secret();
    let data = b"hello world";
    let encrypted = encrypt_data(data, &secret).unwrap();
    let decrypted = decrypt_data(encrypted, "invalid secret");
    assert!(decrypted.is_err())
  }
}
