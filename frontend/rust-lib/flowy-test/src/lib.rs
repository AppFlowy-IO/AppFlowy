pub mod builder;
mod helper;
pub mod workspace;

use crate::helper::*;
use backend_service::configuration::{get_client_server_configuration, ClientServerConfiguration};
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
        let server_config = get_client_server_configuration().unwrap();
        let test = Self::setup_with(server_config);
        std::mem::forget(test.sdk.dispatcher());
        test
    }

    pub async fn sign_up(&self) -> SignUpContext {
        let context = async_sign_up(self.sdk.dispatcher()).await;
        context
    }

    pub async fn init_user(&self) -> UserProfile {
        let context = async_sign_up(self.sdk.dispatcher()).await;
        context.user_profile
    }

    pub fn setup_with(server_config: ClientServerConfiguration) -> Self {
        let config = FlowySDKConfig::new(&root_dir(), server_config, &uuid()).log_filter("debug");
        let sdk = FlowySDK::new(config);
        Self { sdk }
    }

    pub fn sdk(&self) -> FlowyTestSDK { self.sdk.clone() }
}
