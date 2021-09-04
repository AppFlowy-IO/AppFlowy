pub mod builder;
mod helper;
// pub mod workspace_builder;

use crate::{builder::UserTestBuilder, helper::root_dir};
use flowy_sdk::FlowySDK;

pub mod prelude {
    pub use crate::{builder::*, helper::*, *};
    pub use flowy_dispatch::prelude::*;
}

pub type FlowyTestSDK = FlowySDK;

#[derive(Clone)]
pub struct TestSDKBuilder {
    inner: FlowyTestSDK,
}

impl TestSDKBuilder {
    pub fn new() -> Self { Self { inner: init_test_sdk() } }

    pub fn sign_up(self) -> Self {
        let _ = UserTestBuilder::new(self.inner.clone()).sign_up();
        self
    }

    pub fn build(self) -> FlowyTestSDK { self.inner }
}

pub fn init_test_sdk() -> FlowyTestSDK {
    let root_dir = root_dir();
    FlowySDK::new(&root_dir)
}
