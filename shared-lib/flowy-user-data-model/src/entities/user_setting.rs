use flowy_derive::ProtoBuf;
use serde::{Deserialize, Serialize};

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct UserPreferences {
    #[pb(index = 1)]
    user_id: String,

    #[pb(index = 2)]
    appearance_setting: AppearanceSettings,
}

#[derive(ProtoBuf, Serialize, Deserialize, Debug, Clone)]
pub struct AppearanceSettings {
    #[pb(index = 1)]
    pub theme: String,

    #[pb(index = 2)]
    pub locale: LocaleSettings,

    #[pb(index = 3)]
    #[serde(default = "reset_default_value")]
    pub reset_as_default: bool,
}

#[derive(ProtoBuf, Serialize, Deserialize, Debug, Clone)]
pub struct LocaleSettings {
    #[pb(index = 1)]
    pub language_code: String,

    #[pb(index = 2)]
    pub country_code: String,
}

impl std::default::Default for LocaleSettings {
    fn default() -> Self {
        Self {
            language_code: "en".to_owned(),
            country_code: "".to_owned(),
        }
    }
}

fn reset_default_value() -> bool {
    APPEARANCE_RESET_AS_DEFAULT
}

pub const APPEARANCE_DEFAULT_THEME: &str = "light";
pub const APPEARANCE_RESET_AS_DEFAULT: bool = true;

impl std::default::Default for AppearanceSettings {
    fn default() -> Self {
        AppearanceSettings {
            theme: APPEARANCE_DEFAULT_THEME.to_owned(),
            locale: LocaleSettings::default(),
            reset_as_default: APPEARANCE_RESET_AS_DEFAULT,
        }
    }
}
