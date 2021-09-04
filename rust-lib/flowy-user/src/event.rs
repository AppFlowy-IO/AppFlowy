use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use strum_macros::Display;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "UserError"]
pub enum UserEvent {
    #[event(output = "UserProfile")]
    GetUserProfile = 0,

    #[event(input = "SignInRequest", output = "UserProfile")]
    SignIn         = 1,

    #[event(input = "SignUpRequest", output = "UserProfile")]
    SignUp         = 2,

    #[event(passthrough)]
    SignOut        = 3,

    #[event(input = "UpdateUserRequest")]
    UpdateUser     = 4,
}
