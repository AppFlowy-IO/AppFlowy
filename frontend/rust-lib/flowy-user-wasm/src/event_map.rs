use crate::manager::UserManagerWASM;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::AFPlugin;
use std::sync::Weak;
use strum_macros::Display;

#[rustfmt::skip]
pub fn init(user_manager: Weak<UserManagerWASM>) -> AFPlugin {
  
    AFPlugin::new()
        .name("Flowy-User")
        .state(user_manager)
        .event(UserEvent::SignUp, sign_up)
        .event(UserEvent::SignOut, sign_out_handler)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum UserEvent {
  /// Only use when the [Authenticator] is Local or SelfHosted
  /// Creating a new account
  #[event(input = "SignUpPayloadPB", output = "UserProfilePB")]
  SignUp = 0,

  /// Logging out fo an account
  #[event()]
  SignOut = 1,
}
