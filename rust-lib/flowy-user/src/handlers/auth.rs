use crate::domain::user::*;
use flowy_dispatch::prelude::*;
use std::convert::TryInto;

// tracing instrument 👉🏻 https://docs.rs/tracing/0.1.26/tracing/attr.instrument.html
#[tracing::instrument(
    name = "user_sign_in",
    skip(data),
    fields(
        email = %data.email,
    )
)]
pub async fn user_sign_in(data: Data<SignInRequest>) -> ResponseResult<SignInResponse, String> {
    let _params: SignInParams = data.into_inner().try_into()?;
    // TODO: user sign in
    let response = SignInResponse::new(true);
    response_ok(response)
}

#[tracing::instrument(
    name = "user_sign_up",
    skip(data),
    fields(
    email = %data.email,
    )
)]
pub async fn user_sign_up(data: Data<SignUpRequest>) -> ResponseResult<SignUpResponse, String> {
    let _params: SignUpParams = data.into_inner().try_into()?;
    // TODO: user sign up

    let fake_resp = SignUpResponse::new(true);
    response_ok(fake_resp)
}
