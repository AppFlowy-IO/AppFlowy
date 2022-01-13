pub use flowy_core_data_model::entities;

pub mod event;
pub mod module;
mod services;

#[macro_use]
mod macros;

#[macro_use]
extern crate flowy_database;

pub mod context;
mod dart_notification;
pub mod protobuf;
mod util;

pub mod prelude {
    pub use flowy_core_data_model::entities::{app::*, trash::*, view::*, workspace::*};

    pub use crate::{errors::*, module::*};
}

pub mod errors {
    pub use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
}
