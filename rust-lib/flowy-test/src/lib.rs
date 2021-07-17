pub mod builder;
mod helper;
mod tester;

use crate::helper::root_dir;
use flowy_sdk::FlowySDK;
use std::sync::Once;

pub mod prelude {
    pub use crate::{
        builder::{TestBuilder, *},
        helper::*,
        tester::Tester,
    };
    pub use flowy_dispatch::prelude::*;
}

static INIT: Once = Once::new();
pub fn init_sdk() {
    let root_dir = root_dir();

    INIT.call_once(|| {
        FlowySDK::new(&root_dir).construct();
    });
}
