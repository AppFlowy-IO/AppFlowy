use flowy_encrypt::{decrypt_string, encrypt_string};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_deps::entities::{EncryptionType, UpdateUserProfileParams, UserCredentials};

use crate::manager::UserManager;
use crate::services::cloud_config::get_encrypt_secret;

impl UserManager {
  pub async fn set_encrypt_secret(
    &self,
    uid: i64,
    secret: String,
    encryption_type: EncryptionType,
  ) -> FlowyResult<()> {
    self
      .cloud_services
      .get_user_service()?
      .update_user(
        UserCredentials::from_uid(uid),
        UpdateUserProfileParams::new(uid).with_encryption_type(encryption_type),
      )
      .await?;
    let _ = self.get_user_profile(uid, true).await;
    self.cloud_services.set_encrypt_secret(secret);
    Ok(())
  }

  pub fn generate_encryption_sign(&self, uid: i64, encrypt_secret: &str) -> FlowyResult<String> {
    let encrypt_sign = encrypt_string(uid.to_string(), encrypt_secret)?;
    Ok(encrypt_sign)
  }

  pub fn check_encryption_sign(&self, uid: i64, encrypt_sign: &str) -> FlowyResult<()> {
    let store_preference = self
      .get_store_preferences()
      .upgrade()
      .ok_or(FlowyError::new(
        ErrorCode::Internal,
        "Failed to get store preference",
      ))?;

    let encrypt_secret = get_encrypt_secret(&store_preference).ok_or(FlowyError::new(
      ErrorCode::Internal,
      "Encrypt secret is not set",
    ))?;

    self.check_encryption_sign_with_secret(uid, encrypt_sign, &encrypt_secret)
  }

  pub fn check_encryption_sign_with_secret(
    &self,
    uid: i64,
    encrypt_sign: &str,
    encrypt_secret: &str,
  ) -> FlowyResult<()> {
    let decrypt_str = decrypt_string(encrypt_sign, encrypt_secret)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidEncryptSecret, "Invalid decryption secret"))?;
    if uid.to_string() == decrypt_str {
      Ok(())
    } else {
      Err(ErrorCode::InvalidEncryptSecret.into())
    }
  }
}
