use crate::{entities::*, errors::UserError, services::user_session::UserSession};
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
pub async fn user_sign_in_handler(
    data: Data<SignInRequest>,
    session: Unit<Arc<UserSession>>,
) -> ResponseResult<UserDetail, UserError> {
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
pub async fn user_sign_up_handler(
    data: Data<SignUpRequest>,
    session: Unit<Arc<UserSession>>,
) -> ResponseResult<UserDetail, UserError> {
    let params: SignUpParams = data.into_inner().try_into()?;
    let user = session.sign_up(params).await?;
    let user_detail = UserDetail::from(user);
    response_ok(user_detail)
}
