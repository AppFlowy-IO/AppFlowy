use flowy_dispatch::prelude::*;

use crate::{event::UserEvent, handlers::*, services::user_session::UserSession};
use std::sync::Arc;

pub fn create(user_session: Arc<UserSession>) -> Module {
    Module::new()
        .name("Flowy-User")
        .data(user_session)
        .event(UserEvent::SignIn, user_sign_in_handler)
        .event(UserEvent::SignUp, user_sign_up_handler)
        .event(UserEvent::GetStatus, user_get_status_handler)
        .event(UserEvent::SignOut, sign_out_handler)
        .event(UserEvent::UpdateUser, update_user_handler)
}
