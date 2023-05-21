use nanoid::nanoid;
use std::env::temp_dir;

use flowy_core::{AppFlowyCore, AppFlowyCoreConfig};
use flowy_net::http_server::self_host::configuration::get_client_server_configuration;
use flowy_user::entities::UserProfilePB;

use crate::helper::*;

pub mod event_builder;
pub mod helper;

pub mod prelude {
  pub use lib_dispatch::prelude::*;

  pub use crate::{event_builder::*, helper::*, *};
}

#[derive(Clone)]
pub struct FlowySDKTest {
  pub inner: AppFlowyCore,
}

impl std::ops::Deref for FlowySDKTest {
  type Target = AppFlowyCore;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

impl std::default::Default for FlowySDKTest {
  fn default() -> Self {
    Self::new()
  }
}

impl FlowySDKTest {
  pub fn new() -> Self {
    let server_config = get_client_server_configuration().unwrap();
    let config = AppFlowyCoreConfig::new(temp_dir().to_str().unwrap(), nanoid!(6), server_config)
      .log_filter("info", vec![]);
    let sdk = std::thread::spawn(|| AppFlowyCore::new(config))
      .join()
      .unwrap();
    std::mem::forget(sdk.dispatcher());
    Self { inner: sdk }
  }

  pub async fn sign_up(&self) -> SignUpContext {
    async_sign_up(self.inner.dispatcher()).await
  }

  pub async fn init_user(&self) -> UserProfilePB {
    let context = async_sign_up(self.inner.dispatcher()).await;
    init_user_setting(self.inner.dispatcher()).await;
    context.user_profile
  }
}
