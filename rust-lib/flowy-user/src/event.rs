use derive_more::Display;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
pub enum UserEvent {
    #[display(fmt = "GetStatus")]
    #[event(output = "UserDetail")]
    GetStatus = 0,
    #[display(fmt = "SignIn")]
    #[event(input = "SignInRequest", output = "UserDetail")]
    SignIn    = 1,
    #[display(fmt = "SignUp")]
    #[event(input = "SignUpRequest", output = "UserDetail")]
    SignUp    = 2,
    #[display(fmt = "SignOut")]
    #[event()]
    SignOut   = 3,
}
