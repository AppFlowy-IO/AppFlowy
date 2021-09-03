use flowy_dispatch::prelude::*;

use crate::{event::UserEvent, handlers::*, services::user::UserSession};
use std::sync::Arc;

pub fn create(user_session: Arc<UserSession>) -> Module {
    Module::new()
        .name("Flowy-User")
        .data(user_session)
        .event(UserEvent::SignIn, sign_in)
        .event(UserEvent::SignUp, sign_up)
        .event(UserEvent::GetUserProfile, user_profile_handler)
        .event(UserEvent::SignOut, sign_out)
        .event(UserEvent::UpdateUser, update_user_handler)
}
