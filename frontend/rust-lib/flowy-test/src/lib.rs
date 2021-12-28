pub mod doc_script;
pub mod event_builder;
pub mod helper;

use crate::helper::*;
use backend_service::configuration::{get_client_server_configuration, ClientServerConfiguration};
use flowy_sdk::{FlowySDK, FlowySDKConfig};
use flowy_user::entities::UserProfile;
use lib_infra::uuid_string;

pub mod prelude {
    pub use crate::{event_builder::*, helper::*, *};
    pub use lib_dispatch::prelude::*;
}

#[derive(Clone)]
pub struct FlowySDKTest(pub FlowySDK);

impl std::ops::Deref for FlowySDKTest {
    type Target = FlowySDK;

    fn deref(&self) -> &Self::Target { &self.0 }
}

impl FlowySDKTest {
    pub fn setup() -> Self {
        let server_config = get_client_server_configuration().unwrap();
        let sdk = Self::setup_with(server_config);
        std::mem::forget(sdk.dispatcher());
        sdk
    }

    pub fn setup_with(server_config: ClientServerConfiguration) -> Self {
        let config = FlowySDKConfig::new(&root_dir(), server_config, &uuid_string()).log_filter("debug");
        let sdk = FlowySDK::new(config);
        Self(sdk)
    }

    pub async fn sign_up(&self) -> SignUpContext {
        let context = async_sign_up(self.0.dispatcher()).await;
        context
    }

    pub async fn init_user(&self) -> UserProfile {
        let context = async_sign_up(self.0.dispatcher()).await;
        init_user_setting(self.0.dispatcher()).await;
        context.user_profile
    }
}
