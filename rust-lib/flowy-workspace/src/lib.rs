#[cfg(feature = "flowy_client_sdk")]
pub mod event;
#[cfg(feature = "flowy_client_sdk")]
pub mod module;
#[cfg(feature = "flowy_client_sdk")]
mod services;

pub use flowy_workspace_infra::entities;

#[macro_use]
mod macros;

#[macro_use]
extern crate flowy_database;

pub mod errors;
pub mod protobuf;

#[cfg(feature = "flowy_client_sdk")]
pub mod prelude {
    pub use crate::{errors::*, module::*, services::*};
    pub use flowy_workspace_infra::entities::{app::*, trash::*, view::*, workspace::*};
}
