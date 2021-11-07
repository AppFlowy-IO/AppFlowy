pub mod entities;

#[cfg(feature = "flowy_client_sdk")]
pub mod event;
#[cfg(feature = "flowy_client_sdk")]
pub mod module;
#[cfg(feature = "flowy_client_sdk")]
mod services;

#[macro_use]
mod macros;

#[macro_use]
extern crate flowy_database;

pub mod errors;
pub mod protobuf;

#[cfg(feature = "flowy_client_sdk")]
pub mod prelude {
    pub use crate::{
        entities::{app::*, trash::*, view::*, workspace::*},
        errors::*,
        module::*,
        services::*,
    };
}

#[cfg(feature = "backend_service")]
pub mod backend_service {
    pub use crate::protobuf::*;
}
