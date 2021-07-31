use crate::{entities::*, errors::UserError, services::user_session::UserSession};
use flowy_dispatch::prelude::*;
use std::{convert::TryInto, sync::Arc};

// tracing instrument 👉🏻 https://docs.rs/tracing/0.1.26/tracing/attr.instrument.html
#[tracing::instrument(name = "sign_in", skip(data, session), fields(email = %data.email))]
pub async fn sign_in(
    data: Data<SignInRequest>,
    session: Unit<Arc<UserSession>>,
) -> DataResult<UserDetail, UserError> {
    let params: SignInParams = data.into_inner().try_into()?;
    let user = session.sign_in(params).await?;
    let user_detail = UserDetail::from(user);
    data_result(user_detail)
}

#[tracing::instrument(
    name = "sign_up",
    skip(data, session),
    fields(
        email = %data.email,
        name = %data.name,
    )
)]
pub async fn sign_up(
    data: Data<SignUpRequest>,
    session: Unit<Arc<UserSession>>,
) -> DataResult<UserDetail, UserError> {
    let params: SignUpParams = data.into_inner().try_into()?;
    let user = session.sign_up(params).await?;
    let user_detail = UserDetail::from(user);
    data_result(user_detail)
}
