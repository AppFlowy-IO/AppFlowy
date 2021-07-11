use crate::{entities::*, services::user_session::UserSession};
use flowy_dispatch::prelude::*;
use std::{convert::TryInto, sync::Arc};

// tracing instrument 👉🏻 https://docs.rs/tracing/0.1.26/tracing/attr.instrument.html
#[tracing::instrument(
    name = "user_sign_in",
    skip(data, session),
    fields(
        email = %data.email,
    )
)]
pub async fn user_sign_in(
    data: Data<SignInRequest>,
    session: ModuleData<Arc<UserSession>>,
) -> ResponseResult<UserDetail, String> {
    let params: SignInParams = data.into_inner().try_into()?;
    let user = session.sign_in(params).await?;
    let user_detail = UserDetail::from(user);
    response_ok(user_detail)
}

#[tracing::instrument(
    name = "user_sign_up",
    skip(data, session),
    fields(
        email = %data.email,
        name = %data.name,
    )
)]
pub async fn user_sign_up(
    data: Data<SignUpRequest>,
    session: ModuleData<Arc<UserSession>>,
) -> ResponseResult<UserDetail, String> {
    let params: SignUpParams = data.into_inner().try_into()?;
    let user = session.sign_up(params).await?;
    let user_detail = UserDetail::from(user);
    response_ok(user_detail)
}

pub async fn user_get_status(
    session: ModuleData<Arc<UserSession>>,
) -> ResponseResult<UserDetail, String> {
    let user_detail = session.current_user_detail().await?;
    response_ok(user_detail)
}

pub async fn user_sign_out(session: ModuleData<Arc<UserSession>>) -> Result<(), String> {
    let _ = session.sign_out().await?;
    Ok(())
}
