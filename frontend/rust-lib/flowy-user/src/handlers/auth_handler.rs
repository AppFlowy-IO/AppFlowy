use crate::{entities::*, errors::UserError, services::user::UserSession};
use lib_dispatch::prelude::*;
use std::{convert::TryInto, sync::Arc};

// tracing instrument 👉🏻 https://docs.rs/tracing/0.1.26/tracing/attr.instrument.html
#[tracing::instrument(name = "sign_in", skip(data, session), fields(email = %data.email), err)]
pub async fn sign_in(data: Data<SignInRequest>, session: Unit<Arc<UserSession>>) -> DataResult<UserProfile, UserError> {
    let params: SignInParams = data.into_inner().try_into()?;
    let user_profile = session.sign_in(params).await?;
    data_result(user_profile)
}

#[tracing::instrument(
    name = "sign_up",
    skip(data, session),
    fields(
        email = %data.email,
        name = %data.name,
    ),
    err
)]
pub async fn sign_up(data: Data<SignUpRequest>, session: Unit<Arc<UserSession>>) -> DataResult<UserProfile, UserError> {
    let params: SignUpParams = data.into_inner().try_into()?;
    let user_profile = session.sign_up(params).await?;

    data_result(user_profile)
}
