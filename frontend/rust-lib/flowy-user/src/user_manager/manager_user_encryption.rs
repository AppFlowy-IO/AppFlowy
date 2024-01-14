use crate::entities::{AuthStateChangedPB, AuthStatePB};
use crate::user_manager::UserManager;
use flowy_encrypt::{decrypt_text, encrypt_text};
use flowy_error::{ErrorCode, FlowyError, FlowyResult};
use flowy_user_pub::entities::{
  EncryptionType, UpdateUserProfileParams, UserCredentials, UserProfile,
};

use crate::notification::send_auth_state_notification;
use crate::services::cloud_config::get_encrypt_secret;

impl UserManager {
  pub async fn set_encrypt_secret(
    &self,
    uid: i64,
    secret: String,
    encryption_type: EncryptionType,
  ) -> FlowyResult<()> {
    let params = UpdateUserProfileParams::new(uid).with_encryption_type(encryption_type);
    self
      .cloud_services
      .get_user_service()?
      .update_user(UserCredentials::from_uid(uid), params.clone())
      .await?;
    self.cloud_services.set_encrypt_secret(secret);

    Ok(())
  }

  pub fn generate_encryption_sign(&self, uid: i64, encrypt_secret: &str) -> FlowyResult<String> {
    let encrypt_sign = encrypt_text(uid.to_string(), encrypt_secret)?;
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

    let encrypt_secret = get_encrypt_secret(uid, &store_preference).ok_or(FlowyError::new(
      ErrorCode::Internal,
      "Encrypt secret is not set",
    ))?;

    self.check_encryption_sign_with_secret(uid, encrypt_sign, &encrypt_secret)
  }

  pub fn check_encryption_sign_with_secret(
    &self,
    uid: i64,
    encrypt_sign: &str,
    encryption_secret: &str,
  ) -> FlowyResult<()> {
    let decrypt_str = decrypt_text(encrypt_sign, encryption_secret)
      .map_err(|_| FlowyError::new(ErrorCode::InvalidEncryptSecret, "Invalid decryption secret"))?;
    if uid.to_string() == decrypt_str {
      Ok(())
    } else {
      Err(ErrorCode::InvalidEncryptSecret.into())
    }
  }
}

pub(crate) fn validate_encryption_sign(user_profile: &UserProfile, encryption_sign: &str) -> bool {
  // If the local user profile's encryption sign is not equal to the user update's encryption sign,
  // which means the user enable encryption in another device, we should logout the current user.
  let is_valid = user_profile.encryption_type.sign() == encryption_sign;
  if !is_valid {
    send_auth_state_notification(AuthStateChangedPB {
      state: AuthStatePB::InvalidAuth,
      message: "Encryption configuration was changed".to_string(),
    });
  }
  is_valid
}
