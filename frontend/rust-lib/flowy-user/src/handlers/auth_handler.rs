use crate::entities::*;
use crate::services::UserSession;
use flowy_error::FlowyError;
use lib_dispatch::prelude::*;
use std::{convert::TryInto, sync::Arc};
use user_model::{SignInParams, SignUpParams};

// tracing instrument 👉🏻 https://docs.rs/tracing/0.1.26/tracing/attr.instrument.html
#[tracing::instrument(level = "debug", name = "sign_in", skip(data, session), fields(email = %data.email), err)]
pub async fn sign_in(
  data: AFPluginData<SignInPayloadPB>,
  session: AFPluginState<Arc<UserSession>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let params: SignInParams = data.into_inner().try_into()?;
  let user_profile: UserProfilePB = session.sign_in(params).await?.into();
  data_result(user_profile)
}

#[tracing::instrument(
    level = "debug",
    name = "sign_up",
    skip(data, session),
    fields(
        email = %data.email,
        name = %data.name,
    ),
    err
)]
pub async fn sign_up(
  data: AFPluginData<SignUpPayloadPB>,
  session: AFPluginState<Arc<UserSession>>,
) -> DataResult<UserProfilePB, FlowyError> {
  let params: SignUpParams = data.into_inner().try_into()?;
  let user_profile: UserProfilePB = session.sign_up(params).await?.into();

  data_result(user_profile)
}
