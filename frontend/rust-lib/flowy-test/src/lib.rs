pub mod builder;
mod helper;
pub mod workspace;

use crate::helper::*;
use backend_service::config::ServerConfig;
use flowy_sdk::{FlowySDK, FlowySDKConfig};
use flowy_user::entities::UserProfile;
use lib_infra::uuid;

pub mod prelude {
    pub use crate::{builder::*, helper::*, *};
    pub use lib_dispatch::prelude::*;
}

pub type FlowyTestSDK = FlowySDK;

#[derive(Clone)]
pub struct FlowyTest {
    pub sdk: FlowyTestSDK,
}

impl FlowyTest {
    pub fn setup() -> Self {
        let server_config = ServerConfig::default();
        let test = Self::setup_with(server_config);
        std::mem::forget(test.sdk.dispatch());
        test
    }

    pub async fn sign_up(&self) -> SignUpContext {
        let context = async_sign_up(self.sdk.dispatch()).await;
        context
    }

    pub async fn init_user(&self) -> UserProfile {
        let context = async_sign_up(self.sdk.dispatch()).await;
        context.user_profile
    }

    pub fn setup_with(server_config: ServerConfig) -> Self {
        let config = FlowySDKConfig::new(&root_dir(), server_config, &uuid()).log_filter("debug");
        let sdk = FlowySDK::new(config);
        Self { sdk }
    }

    pub fn sdk(&self) -> FlowyTestSDK { self.sdk.clone() }
}
