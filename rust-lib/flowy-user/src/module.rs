use crate::{domain::event::UserEvent, handlers::*};
use flowy_sys::prelude::*;

pub fn create() -> Module {
    Module::new()
        .name("Flowy-User")
        .event(UserEvent::SignIn, user_sign_in)
        .event(UserEvent::SignUp, user_sign_up)
}
