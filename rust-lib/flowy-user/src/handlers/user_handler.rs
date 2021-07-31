use crate::{entities::*, errors::UserError, services::user_session::UserSession};
use flowy_dispatch::prelude::*;
use std::{convert::TryInto, sync::Arc};

#[tracing::instrument(name = "get_user_status", skip(session))]
pub async fn get_user_status(session: Unit<Arc<UserSession>>) -> DataResult<UserDetail, UserError> {
    let user_detail = session.user_detail()?;
    data_result(user_detail)
}

#[tracing::instrument(name = "sign_out", skip(session))]
pub async fn sign_out(session: Unit<Arc<UserSession>>) -> Result<(), UserError> {
    let _ = session.sign_out()?;
    Ok(())
}

#[tracing::instrument(name = "update_user", skip(data, session))]
pub async fn update_user(
    data: Data<UpdateUserRequest>,
    session: Unit<Arc<UserSession>>,
) -> DataResult<UserDetail, UserError> {
    let params: UpdateUserParams = data.into_inner().try_into()?;
    let user_detail = session.update_user(params)?;
    data_result(user_detail)
}
