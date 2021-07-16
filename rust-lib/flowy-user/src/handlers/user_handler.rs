use crate::{entities::*, errors::UserError, services::user_session::UserSession};
use flowy_dispatch::prelude::*;
use std::{convert::TryInto, sync::Arc};

pub async fn user_get_status_handler(
    session: ModuleData<Arc<UserSession>>,
) -> ResponseResult<UserDetail, UserError> {
    let user_detail = session.user_detail()?;
    response_ok(user_detail)
}

pub async fn sign_out_handler(session: ModuleData<Arc<UserSession>>) -> Result<(), UserError> {
    let _ = session.sign_out()?;
    Ok(())
}

pub async fn update_user_handler(
    data: Data<UpdateUserRequest>,
    session: ModuleData<Arc<UserSession>>,
) -> ResponseResult<UserDetail, UserError> {
    let params: UpdateUserParams = data.into_inner().try_into()?;
    let user_detail = session.update_user(params)?;
    response_ok(user_detail)
}
