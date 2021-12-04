use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use strum_macros::Display;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "UserError"]
pub enum UserEvent {
    #[event()]
    InitUser          = 0,

    #[event(input = "SignInRequest", output = "UserProfile")]
    SignIn            = 1,

    #[event(input = "SignUpRequest", output = "UserProfile")]
    SignUp            = 2,

    #[event(passthrough)]
    SignOut           = 3,

    #[event(input = "UpdateUserRequest")]
    UpdateUser        = 4,

    #[event(output = "UserProfile")]
    GetUserProfile    = 5,

    #[event(output = "UserProfile")]
    CheckUser         = 6,

    #[event(input = "NetworkState")]
    UpdateNetworkType = 10,
}
