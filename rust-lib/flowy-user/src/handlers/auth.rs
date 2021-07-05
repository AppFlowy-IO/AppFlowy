use crate::domain::{User, UserCheck, UserEmail, UserName};
use flowy_sys::prelude::*;
use std::convert::TryInto;

// tracing instrument 👉🏻 https://docs.rs/tracing/0.1.26/tracing/attr.instrument.html
#[tracing::instrument(
    name = "User check",
    skip(data),
    fields(
        email = %data.email,
        name = %data.name
    )
)]
pub async fn user_check(data: Data<UserCheck>) -> ResponseResult<User, String> {
    let user: User = data.into_inner().try_into().unwrap();

    response_ok(user)
}
