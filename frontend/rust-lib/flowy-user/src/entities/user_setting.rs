use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
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
}

const DEFAULT_RESET_VALUE: fn() -> bool = || APPEARANCE_RESET_AS_DEFAULT;

#[derive(ProtoBuf_Enum, Serialize, Deserialize, Clone, Debug)]
pub enum ThemeModePB {
    Light = 0,
    Dark = 1,
    System = 2,
}

impl std::default::Default for ThemeModePB {
    fn default() -> Self {
        ThemeModePB::System
    }
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

pub const APPEARANCE_DEFAULT_THEME: &str = "light";
pub const APPEARANCE_DEFAULT_FONT: &str = "Poppins";
pub const APPEARANCE_DEFAULT_MONOSPACE_FONT: &str = "SF Mono";
const APPEARANCE_RESET_AS_DEFAULT: bool = true;

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
        }
    }
}
