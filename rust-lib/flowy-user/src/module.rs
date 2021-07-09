use flowy_dispatch::prelude::*;

use crate::{event::UserEvent, handlers::*};

pub fn create() -> Module {
    Module::new()
        .name("Flowy-User")
        .event(UserEvent::SignIn, user_sign_in)
        .event(UserEvent::SignUp, user_sign_up)
}
