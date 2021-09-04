pub mod builder;
mod helper;

use crate::helper::*;
use flowy_sdk::FlowySDK;
use flowy_user::entities::UserDetail;

pub mod prelude {
    pub use crate::{builder::*, helper::*, *};
    pub use flowy_dispatch::prelude::*;
}

pub type FlowyTestSDK = FlowySDK;

#[derive(Clone)]
pub struct FlowyEnv {
    pub sdk: FlowyTestSDK,
    pub user: UserDetail,
    pub password: String,
}

impl FlowyEnv {
    pub fn setup() -> Self {
        let sdk = init_test_sdk();
        let result = sign_up(sdk.dispatch());
        let env = Self {
            sdk,
            user: result.user_detail,
            password: result.password,
        };
        env
    }

    pub fn sdk(&self) -> FlowyTestSDK { self.sdk.clone() }
}

pub fn init_test_sdk() -> FlowyTestSDK {
    let root_dir = root_dir();
    FlowySDK::new(&root_dir)
}
