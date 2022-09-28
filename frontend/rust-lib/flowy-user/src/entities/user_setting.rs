use flowy_derive::ProtoBuf;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct UserPreferencesPB {
    #[pb(index = 1)]
    user_id: String,

    #[pb(index = 2)]
    appearance_setting: AppearanceSettingsPB,
}

#[derive(ProtoBuf, Serialize, Deserialize, Debug, Clone)]
pub struct AppearanceSettingsPB {
    #[pb(index = 1)]
    pub theme: String,

    #[pb(index = 2)]
    #[serde(default)]
    pub locale: LocaleSettingsPB,

    #[pb(index = 3)]
    #[serde(default = "DEFAULT_RESET_VALUE")]
    pub reset_to_default: bool,

    #[pb(index = 4)]
    #[serde(default)]
    pub setting_key_value: HashMap<String, String>,
}

const DEFAULT_RESET_VALUE: fn() -> bool = || APPEARANCE_RESET_AS_DEFAULT;

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

pub const APPEARANCE_DEFAULT_THEME: &str = "light";
const APPEARANCE_RESET_AS_DEFAULT: bool = true;

impl std::default::Default for AppearanceSettingsPB {
    fn default() -> Self {
        AppearanceSettingsPB {
            theme: APPEARANCE_DEFAULT_THEME.to_owned(),
            locale: LocaleSettingsPB::default(),
            reset_to_default: APPEARANCE_RESET_AS_DEFAULT,
            setting_key_value: HashMap::default(),
        }
    }
}
