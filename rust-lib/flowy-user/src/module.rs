use flowy_dispatch::prelude::*;

use crate::{
    domain::{user_db::*, user_session::UserSession},
    event::UserEvent,
    handlers::*,
};
use std::sync::Arc;

pub fn create(user_session: Arc<UserSession>) -> Module {
    Module::new()
        .name("Flowy-User")
        .data(user_session)
        .event(UserEvent::SignIn, user_sign_in)
        .event(UserEvent::SignUp, user_sign_up)
}
