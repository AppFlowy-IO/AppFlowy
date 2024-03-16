use crate::event_handler::*;
use crate::manager::UserManager;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::AFPlugin;
use std::rc::Weak;
use strum_macros::Display;

#[rustfmt::skip]
pub fn init(user_manager: Weak<UserManager>) -> AFPlugin {
    AFPlugin::new()
        .name("Flowy-User")
        .state(user_manager)
        .event(UserWasmEvent::OauthSignIn, oauth_sign_in_handler)
        .event(UserWasmEvent::AddUser, add_user_handler)
        .event(UserWasmEvent::SignInPassword, sign_in_with_password_handler)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum UserWasmEvent {
  #[event(input = "OauthSignInPB", output = "UserProfilePB")]
  OauthSignIn = 0,

  #[event(input = "AddUserPB")]
  AddUser = 1,

  #[event(input = "UserSignInPB", output = "UserProfilePB")]
  SignInPassword = 2,
}
