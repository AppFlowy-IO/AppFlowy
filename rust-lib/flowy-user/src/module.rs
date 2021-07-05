use crate::{event::UserEvent::*, handlers::*};
use flowy_sys::prelude::*;

pub fn create() -> Module {
    Module::new()
        .name("Flowy-User")
        .event(SignIn, user_sign_in)
        .event(SignUp, user_sign_up)
}
