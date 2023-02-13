pub mod event_builder;
pub mod helper;

use crate::helper::*;

use flowy_core::{AppFlowyCore, AppFlowyCoreConfig};
use flowy_document::entities::DocumentVersionPB;
use flowy_net::get_client_server_configuration;
use flowy_user::entities::UserProfilePB;
use nanoid::nanoid;

pub mod prelude {
  pub use crate::{event_builder::*, helper::*, *};
  pub use lib_dispatch::prelude::*;
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
    Self::new(DocumentVersionPB::V0)
  }
}

impl FlowySDKTest {
  pub fn new(document_version: DocumentVersionPB) -> Self {
    let server_config = get_client_server_configuration().unwrap();
    let config = AppFlowyCoreConfig::new(&root_dir(), nanoid!(6), server_config)
      .with_document_version(document_version)
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

  pub fn document_version(&self) -> DocumentVersionPB {
    self.inner.config.document.version.clone()
  }
}
