pub use flowy_folder_data_model::entities;
pub mod event_map;
pub mod services;

#[macro_use]
mod macros;

#[macro_use]
extern crate flowy_database;

mod dart_notification;
pub mod manager;
pub mod protobuf;
mod util;

pub mod prelude {
    pub use flowy_folder_data_model::entities::{app::*, trash::*, view::*, workspace::*};

    pub use crate::{errors::*, event_map::*};
}

pub mod errors {
    pub use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
}
