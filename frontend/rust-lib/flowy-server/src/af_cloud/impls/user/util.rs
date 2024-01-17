use client_api::entity::AFUserProfile;

use flowy_user_pub::entities::EncryptionType;

pub fn encryption_type_from_profile(profile: &AFUserProfile) -> EncryptionType {
  match &profile.encryption_sign {
    Some(e) => EncryptionType::SelfEncryption(e.to_string()),
    None => EncryptionType::NoEncryption,
  }
}
