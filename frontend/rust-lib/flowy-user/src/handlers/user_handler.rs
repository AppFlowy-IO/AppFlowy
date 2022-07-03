use crate::{errors::FlowyError, services::UserSession};
use flowy_database::kv::KV;
use flowy_user_data_model::entities::{
    AppearanceSettings, UpdateUserProfileParams, UpdateUserProfilePayload, UserProfile, APPEARANCE_DEFAULT_THEME,
};
use lib_dispatch::prelude::*;
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(level = "debug", skip(session))]
pub async fn init_user_handler(session: AppData<Arc<UserSession>>) -> Result<(), FlowyError> {
    let _ = session.init_user().await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(session))]
pub async fn check_user_handler(session: AppData<Arc<UserSession>>) -> DataResult<UserProfile, FlowyError> {
    let user_profile = session.check_user().await?;
    data_result(user_profile)
}

#[tracing::instrument(level = "debug", skip(session))]
pub async fn get_user_profile_handler(session: AppData<Arc<UserSession>>) -> DataResult<UserProfile, FlowyError> {
    let user_profile = session.user_profile().await?;
    data_result(user_profile)
}

#[tracing::instrument(level = "debug", name = "sign_out", skip(session))]
pub async fn sign_out(session: AppData<Arc<UserSession>>) -> Result<(), FlowyError> {
    let _ = session.sign_out().await?;
    Ok(())
}

#[tracing::instrument(level = "debug", skip(data, session))]
pub async fn update_user_profile_handler(
    data: Data<UpdateUserProfilePayload>,
    session: AppData<Arc<UserSession>>,
) -> Result<(), FlowyError> {
    let params: UpdateUserProfileParams = data.into_inner().try_into()?;
    session.update_user_profile(params).await?;
    Ok(())
}

const APPEARANCE_SETTING_CACHE_KEY: &str = "appearance_settings";

#[tracing::instrument(level = "debug", skip(data), err)]
pub async fn set_appearance_setting(data: Data<AppearanceSettings>) -> Result<(), FlowyError> {
    let mut setting = data.into_inner();
    if setting.theme.is_empty() {
        setting.theme = APPEARANCE_DEFAULT_THEME.to_string();
    }

    let s = serde_json::to_string(&setting)?;
    KV::set_str(APPEARANCE_SETTING_CACHE_KEY, s);
    Ok(())
}

#[tracing::instrument(err)]
pub async fn get_appearance_setting() -> DataResult<AppearanceSettings, FlowyError> {
    match KV::get_str(APPEARANCE_SETTING_CACHE_KEY) {
        None => data_result(AppearanceSettings::default()),
        Some(s) => {
            let setting = match serde_json::from_str(&s) {
                Ok(setting) => setting,
                Err(e) => {
                    tracing::error!("Deserialize AppearanceSettings failed: {:?}, fallback to default", e);
                    AppearanceSettings::default()
                }
            };
            data_result(setting)
        }
    }
}
