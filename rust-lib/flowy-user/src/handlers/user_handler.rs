use crate::{entities::*, errors::UserError, services::user::UserSession};
use flowy_dispatch::prelude::*;

use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(name = "get_user_status", skip(session))]
pub async fn user_status_handler(
    session: Unit<Arc<UserSession>>,
) -> DataResult<UserDetail, UserError> {
    let user_detail = session.user_detail().await?;
    data_result(user_detail)
}

#[tracing::instrument(name = "sign_out", skip(session))]
pub async fn sign_out(session: Unit<Arc<UserSession>>) -> Result<(), UserError> {
    let _ = session.sign_out().await?;
    Ok(())
}

#[tracing::instrument(name = "update_user", skip(data, session))]
pub async fn update_user_handler(
    data: Data<UpdateUserRequest>,
    session: Unit<Arc<UserSession>>,
) -> Result<(), UserError> {
    let params: UpdateUserParams = data.into_inner().try_into()?;
    session.update_user(params).await?;
    Ok(())
}
