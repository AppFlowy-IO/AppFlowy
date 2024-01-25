use crate::event_handler::*;
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
        .event(UserWasmEvent::OauthSignIn, oauth_sign_in_handler)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum UserWasmEvent {
  #[event(input = "SignUpPayloadPB", output = "UserProfilePB")]
  OauthSignIn = 0,
}
