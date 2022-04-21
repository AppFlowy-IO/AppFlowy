pub mod event_builder;
pub mod helper;

use crate::helper::*;
use flowy_net::{get_client_server_configuration, ClientServerConfiguration};
use flowy_sdk::{FlowySDK, FlowySDKConfig};
use flowy_user::entities::UserProfile;
use nanoid::nanoid;

pub mod prelude {
    pub use crate::{event_builder::*, helper::*, *};
    pub use lib_dispatch::prelude::*;
}

#[derive(Clone)]
pub struct FlowySDKTest {
    pub inner: FlowySDK,
}

impl std::ops::Deref for FlowySDKTest {
    type Target = FlowySDK;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::default::Default for FlowySDKTest {
    fn default() -> Self {
        let server_config = get_client_server_configuration().unwrap();
        let sdk = Self::new(server_config);
        std::mem::forget(sdk.dispatcher());
        sdk
    }
}

impl FlowySDKTest {
    pub fn new(server_config: ClientServerConfiguration) -> Self {
        let config = FlowySDKConfig::new(&root_dir(), server_config, &nanoid!(6)).log_filter("info");
        let sdk = std::thread::spawn(|| FlowySDK::new(config)).join().unwrap();
        std::mem::forget(sdk.dispatcher());
        Self { inner: sdk }
    }

    pub async fn sign_up(&self) -> SignUpContext {
        let context = async_sign_up(self.inner.dispatcher()).await;
        context
    }

    pub async fn init_user(&self) -> UserProfile {
        let context = async_sign_up(self.inner.dispatcher()).await;
        init_user_setting(self.inner.dispatcher()).await;
        context.user_profile
    }
}
