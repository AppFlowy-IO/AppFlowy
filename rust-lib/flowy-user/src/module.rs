use crate::handlers::*;
use flowy_sys::prelude::*;

use derive_more::Display;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash)]
pub enum UserEvent {
    #[display(fmt = "AuthCheck")]
    AuthCheck = 0,
    #[display(fmt = "SignIn")]
    SignIn    = 1,
    #[display(fmt = "SignUp")]
    SignUp    = 2,
    #[display(fmt = "SignOut")]
    SignOut   = 3,
}

pub fn create() -> Module {
    Module::new()
        .name("Flowy-User")
        .event(UserEvent::SignIn, user_sign_in)
        .event(UserEvent::SignUp, user_sign_up)
}
