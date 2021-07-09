use derive_more::Display;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
pub enum UserEvent {
    #[display(fmt = "AuthCheck")]
    AuthCheck = 0,
    #[display(fmt = "SignIn")]
    #[event(input = "SignInRequest", output = "SignInResponse")]
    SignIn    = 1,
    #[display(fmt = "SignUp")]
    #[event(input = "SignUpRequest", output = "SignUpResponse")]
    SignUp    = 2,
    #[display(fmt = "SignOut")]
    SignOut   = 3,
}
