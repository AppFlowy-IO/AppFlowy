use derive_more::Display;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
pub enum UserEvent {
    #[display(fmt = "AuthCheck")]
    #[event(input = "UserSignInParams", output = "UserSignInResult")]
    AuthCheck = 0,
    #[event(input = "UserSignInParams", output = "UserSignInResult")]
    #[display(fmt = "SignIn")]
    SignIn    = 1,
    #[display(fmt = "SignUp")]
    SignUp    = 2,
    #[display(fmt = "SignOut")]
    SignOut   = 3,
}
