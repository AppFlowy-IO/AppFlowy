use crate::domain::user::*;
use flowy_sys::prelude::*;
use std::convert::TryInto;

// tracing instrument 👉🏻 https://docs.rs/tracing/0.1.26/tracing/attr.instrument.html
#[tracing::instrument(
    name = "user_sign_in",
    skip(data),
    fields(
        email = %data.email,
    )
)]
pub async fn user_sign_in(
    data: Data<UserSignInParams>,
) -> ResponseResult<UserSignInResult, String> {
    let _request: UserSignInRequest = data.into_inner().try_into()?;

    let response = UserSignInResult::new(true);
    response_ok(response)
}

#[tracing::instrument(
    name = "user_sign_up",
    skip(data),
    fields(
    email = %data.email,
    )
)]
pub async fn user_sign_up(
    data: Data<UserSignUpParams>,
) -> ResponseResult<UserSignUpResult, String> {
    let _request: UserSignUpRequest = data.into_inner().try_into()?;

    let response = UserSignUpResult::new(true);
    response_ok(response)
}
