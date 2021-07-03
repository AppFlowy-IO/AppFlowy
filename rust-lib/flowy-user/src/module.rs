use crate::{event::UserEvent::*, handlers::*};
use flowy_sys::prelude::*;

pub fn create() -> Module {
    Module::new()
        .name("Flowy-User")
        .event(AuthCheck, user_check)
        .event(SignIn, user_check)
        .event(SignUp, user_check)
        .event(SignOut, user_check)
}
