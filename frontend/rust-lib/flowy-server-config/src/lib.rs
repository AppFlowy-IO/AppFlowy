use serde_repr::Deserialize_repr;

pub mod af_cloud_config;
pub mod supabase_config;

pub const CLOUT_TYPE_STR: &str = "APPFLOWY_CLOUD_ENV_CLOUD_TYPE";

#[derive(Deserialize_repr, Debug, Clone, PartialEq, Eq)]
#[repr(u8)]
pub enum AuthenticatorType {
  Local = 0,
  Supabase = 1,
  AppFlowyCloud = 2,
}

impl AuthenticatorType {
  pub fn write_env(&self) {
    let s = self.clone() as u8;
    std::env::set_var(CLOUT_TYPE_STR, s.to_string());
  }

  #[allow(dead_code)]
  fn from_str(s: &str) -> Self {
    match s {
      "0" => AuthenticatorType::Local,
      "1" => AuthenticatorType::Supabase,
      "2" => AuthenticatorType::AppFlowyCloud,
      _ => AuthenticatorType::Local,
    }
  }

  #[allow(dead_code)]
  pub fn from_env() -> Self {
    let cloud_type_str = std::env::var(CLOUT_TYPE_STR).unwrap_or_default();
    AuthenticatorType::from_str(&cloud_type_str)
  }
}
