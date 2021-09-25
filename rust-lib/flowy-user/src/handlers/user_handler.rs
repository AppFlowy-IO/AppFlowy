use crate::{entities::*, errors::UserError, services::user::UserSession};
use flowy_dispatch::prelude::*;

use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(skip(session))]
pub async fn init_user_handler(session: Unit<Arc<UserSession>>) -> Result<(), UserError> {
    let _ = session.init_user().await?;
    Ok(())
}

#[tracing::instrument(skip(session))]
pub async fn check_user_handler(session: Unit<Arc<UserSession>>) -> DataResult<UserProfile, UserError> {
    let user_profile = session.check_user().await?;
    data_result(user_profile)
}

#[tracing::instrument(skip(session))]
pub async fn get_user_profile_handler(session: Unit<Arc<UserSession>>) -> DataResult<UserProfile, UserError> {
    let user_profile = session.user_profile().await?;
    data_result(user_profile)
}

#[tracing::instrument(name = "sign_out", skip(session))]
pub async fn sign_out(session: Unit<Arc<UserSession>>) -> Result<(), UserError> {
    let _ = session.sign_out().await?;
    Ok(())
}

#[tracing::instrument(name = "update_user", skip(data, session))]
pub async fn update_user_handler(data: Data<UpdateUserRequest>, session: Unit<Arc<UserSession>>) -> Result<(), UserError> {
    let params: UpdateUserParams = data.into_inner().try_into()?;
    session.update_user(params).await?;
    Ok(())
}
