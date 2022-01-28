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
    pub language: String,
}

pub const APPEARANCE_DEFAULT_THEME: &str = "light";
pub const APPEARANCE_DEFAULT_LANGUAGE: &str = "en";

impl std::default::Default for AppearanceSettings {
    fn default() -> Self {
        AppearanceSettings {
            theme: APPEARANCE_DEFAULT_THEME.to_owned(),
            language: APPEARANCE_DEFAULT_LANGUAGE.to_owned(),
        }
    }
}
