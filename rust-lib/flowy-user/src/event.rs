use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use strum_macros::Display;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "UserError"]
pub enum UserEvent {
    #[event(output = "UserDetail")]
    GetStatus  = 0,

    #[event(input = "SignInRequest", output = "UserDetail")]
    SignIn     = 1,

    #[event(input = "SignUpRequest", output = "UserDetail")]
    SignUp     = 2,

    #[event(passthrough)]
    SignOut    = 3,

    #[event(input = "UpdateUserRequest", output = "UserDetail")]
    UpdateUser = 4,
}
