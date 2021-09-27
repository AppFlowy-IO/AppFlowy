pub mod builder;
mod helper;

use crate::helper::*;
use flowy_sdk::{FlowySDK, FlowySDKConfig};
use flowy_user::entities::UserProfile;

pub mod prelude {
    pub use crate::{builder::*, helper::*, *};
    pub use flowy_dispatch::prelude::*;
}

pub type FlowyTestSDK = FlowySDK;

#[derive(Clone)]
pub struct FlowyEnv {
    pub sdk: FlowyTestSDK,
    pub user: UserProfile,
    pub password: String,
}

impl FlowyEnv {
    pub fn setup() -> Self {
        let host = "localhost";
        let http_schema = "http";
        let ws_schema = "ws";

        let config = FlowySDKConfig::new(&root_dir(), host, http_schema, ws_schema).log_filter("debug");
        let sdk = FlowySDK::new(config);
        let result = sign_up(sdk.dispatch());
        let env = Self {
            sdk,
            user: result.user_profile,
            password: result.password,
        };
        env
    }

    pub fn sdk(&self) -> FlowyTestSDK { self.sdk.clone() }
}

pub fn init_test_sdk() -> FlowyTestSDK {
    let host = "localhost";
    let http_schema = "http";
    let ws_schema = "ws";

    let config = FlowySDKConfig::new(&root_dir(), host, http_schema, ws_schema).log_filter("debug");
    FlowySDK::new(config)
}
