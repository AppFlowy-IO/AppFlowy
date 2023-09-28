use std::collections::HashMap;

use serde::{Deserialize, Serialize};

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_deps::cloud::UserCloudConfig;

use crate::entities::EncryptionTypePB;

use super::date_time::{UserDateFormatPB, UserTimeFormatPB};

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct UserPreferencesPB {
  #[pb(index = 1)]
  user_id: String,

  #[pb(index = 2)]
  appearance_setting: AppearanceSettingsPB,

  #[pb(index = 3)]
  date_time_settings: DateTimeSettingsPB,
}

#[derive(ProtoBuf, Serialize, Deserialize, Debug, Clone)]
pub struct AppearanceSettingsPB {
  #[pb(index = 1)]
  pub theme: String,

  #[pb(index = 2)]
  #[serde(default)]
  pub theme_mode: ThemeModePB,

  #[pb(index = 3)]
  pub font: String,

  #[pb(index = 4)]
  pub monospace_font: String,

  #[pb(index = 5)]
  #[serde(default)]
  pub locale: LocaleSettingsPB,

  #[pb(index = 6)]
  #[serde(default = "DEFAULT_RESET_VALUE")]
  pub reset_to_default: bool,

  #[pb(index = 7)]
  #[serde(default)]
  pub setting_key_value: HashMap<String, String>,

  #[pb(index = 8)]
  #[serde(default)]
  pub is_menu_collapsed: bool,

  #[pb(index = 9)]
  #[serde(default)]
  pub menu_offset: f64,

  #[pb(index = 10)]
  #[serde(default)]
  pub layout_direction: LayoutDirectionPB,

  // If the value is FALLBACK which is the default value then it will fall back
  // to layout direction and it will use that as default text direction.
  #[pb(index = 11)]
  #[serde(default)]
  pub text_direction: TextDirectionPB,
}

const DEFAULT_RESET_VALUE: fn() -> bool = || APPEARANCE_RESET_AS_DEFAULT;

#[derive(ProtoBuf_Enum, Serialize, Deserialize, Clone, Debug, Default)]
pub enum ThemeModePB {
  Light = 0,
  Dark = 1,
  #[default]
  System = 2,
}

#[derive(ProtoBuf_Enum, Serialize, Deserialize, Clone, Debug, Default)]
pub enum LayoutDirectionPB {
  #[default]
  LTRLayout = 0,
  RTLLayout = 1,
}

#[derive(ProtoBuf_Enum, Serialize, Deserialize, Clone, Debug, Default)]
pub enum TextDirectionPB {
  LTR = 0,
  RTL = 1,
  AUTO = 2,
  #[default]
  FALLBACK = 3,
}

#[derive(ProtoBuf, Serialize, Deserialize, Debug, Clone)]
pub struct LocaleSettingsPB {
  #[pb(index = 1)]
  pub language_code: String,

  #[pb(index = 2)]
  pub country_code: String,
}

impl std::default::Default for LocaleSettingsPB {
  fn default() -> Self {
    Self {
      language_code: "en".to_owned(),
      country_code: "".to_owned(),
    }
  }
}

pub const APPEARANCE_DEFAULT_THEME: &str = "Default";
pub const APPEARANCE_DEFAULT_FONT: &str = "Poppins";
pub const APPEARANCE_DEFAULT_MONOSPACE_FONT: &str = "SF Mono";
const APPEARANCE_RESET_AS_DEFAULT: bool = true;
const APPEARANCE_DEFAULT_IS_MENU_COLLAPSED: bool = false;
const APPEARANCE_DEFAULT_MENU_OFFSET: f64 = 0.0;

impl std::default::Default for AppearanceSettingsPB {
  fn default() -> Self {
    AppearanceSettingsPB {
      theme: APPEARANCE_DEFAULT_THEME.to_owned(),
      theme_mode: ThemeModePB::default(),
      font: APPEARANCE_DEFAULT_FONT.to_owned(),
      monospace_font: APPEARANCE_DEFAULT_MONOSPACE_FONT.to_owned(),
      locale: LocaleSettingsPB::default(),
      reset_to_default: APPEARANCE_RESET_AS_DEFAULT,
      setting_key_value: HashMap::default(),
      is_menu_collapsed: APPEARANCE_DEFAULT_IS_MENU_COLLAPSED,
      menu_offset: APPEARANCE_DEFAULT_MENU_OFFSET,
      layout_direction: LayoutDirectionPB::default(),
      text_direction: TextDirectionPB::default(),
    }
  }
}

#[derive(Default, ProtoBuf)]
pub struct UserCloudConfigPB {
  #[pb(index = 1)]
  enable_sync: bool,

  #[pb(index = 2)]
  enable_encrypt: bool,

  #[pb(index = 3)]
  pub encrypt_secret: String,
}

#[derive(Default, ProtoBuf)]
pub struct UpdateCloudConfigPB {
  #[pb(index = 1, one_of)]
  pub enable_sync: Option<bool>,

  #[pb(index = 2, one_of)]
  pub enable_encrypt: Option<bool>,
}

#[derive(Default, ProtoBuf)]
pub struct UserSecretPB {
  #[pb(index = 1)]
  pub user_id: i64,

  #[pb(index = 2)]
  pub encryption_secret: String,

  #[pb(index = 3)]
  pub encryption_type: EncryptionTypePB,

  #[pb(index = 4)]
  pub encryption_sign: String,
}

#[derive(Default, ProtoBuf)]
pub struct UserEncryptionSecretCheckPB {
  #[pb(index = 1)]
  pub is_need_secret: bool,
}

impl From<UserCloudConfig> for UserCloudConfigPB {
  fn from(value: UserCloudConfig) -> Self {
    Self {
      enable_sync: value.enable_sync,
      enable_encrypt: value.enable_encrypt(),
      encrypt_secret: value.encrypt_secret,
    }
  }
}

#[derive(ProtoBuf_Enum, Debug, Clone, Eq, PartialEq, Default)]
pub enum NetworkTypePB {
  #[default]
  NetworkUnknown = 0,
  Wifi = 1,
  Cell = 2,
  Ethernet = 3,
  Bluetooth = 4,
  VPN = 5,
}

impl NetworkTypePB {
  pub fn is_reachable(&self) -> bool {
    match self {
      NetworkTypePB::NetworkUnknown | NetworkTypePB::Bluetooth => false,
      NetworkTypePB::Wifi | NetworkTypePB::Cell | NetworkTypePB::Ethernet | NetworkTypePB::VPN => {
        true
      },
    }
  }
}

#[derive(ProtoBuf, Debug, Default, Clone)]
pub struct NetworkStatePB {
  #[pb(index = 1)]
  pub ty: NetworkTypePB,
}

#[derive(ProtoBuf, Serialize, Deserialize, Debug, Clone)]
pub struct DateTimeSettingsPB {
  #[pb(index = 1)]
  pub date_format: UserDateFormatPB,

  #[pb(index = 2)]
  pub time_format: UserTimeFormatPB,

  #[pb(index = 3)]
  pub timezone_id: String,
}

impl std::default::Default for DateTimeSettingsPB {
  fn default() -> Self {
    DateTimeSettingsPB {
      date_format: UserDateFormatPB::Friendly,
      time_format: UserTimeFormatPB::TwentyFourHour,
      timezone_id: "".to_owned(),
    }
  }
}
