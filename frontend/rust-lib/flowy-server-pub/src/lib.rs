use serde_repr::Deserialize_repr;

macro_rules! if_native {
    ($($item:item)*) => {$(
        #[cfg(not(target_arch = "wasm32"))]
        $item
    )*}
}

macro_rules! if_wasm {
    ($($item:item)*) => {$(
        #[cfg(target_arch = "wasm32")]
        $item
    )*}
}

if_native! {
    mod native;
    pub mod af_cloud_config {
      pub use crate::native::af_cloud_config::*;
    }
}

if_wasm! {
    mod wasm;
    pub mod af_cloud_config {
      pub use crate::wasm::af_cloud_config::*;
    }
}

pub const CLOUT_TYPE_STR: &str = "APPFLOWY_CLOUD_ENV_CLOUD_TYPE";

#[derive(Deserialize_repr, Debug, Clone, PartialEq, Eq)]
#[repr(u8)]
pub enum AuthenticatorType {
  Local = 0,
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
