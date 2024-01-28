use crate::event_handler::*;
use crate::manager::UserManagerWASM;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::AFPlugin;
use std::rc::Weak;
use strum_macros::Display;

#[rustfmt::skip]
pub fn init(user_manager: Weak<UserManagerWASM>) -> AFPlugin {
    AFPlugin::new()
        .name("Flowy-User")
        .state(user_manager)
        .event(UserWasmEvent::OauthSignIn, oauth_sign_in_handler)
        .event(UserWasmEvent::GenerateSignInURL, gen_sign_in_url_handler)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum UserWasmEvent {
  #[event(input = "OauthSignInPB", output = "UserProfilePB")]
  OauthSignIn = 0,

  #[event(input = "SignInUrlPayloadPB", output = "SignInUrlPB")]
  GenerateSignInURL = 1,
}
