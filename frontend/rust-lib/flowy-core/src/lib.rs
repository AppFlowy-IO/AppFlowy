pub use flowy_core_infra::entities;

pub mod event;
pub mod module;
mod services;

#[macro_use]
mod macros;

#[macro_use]
extern crate flowy_database;

pub mod core;
pub mod errors;
mod notify;
pub mod protobuf;
mod util;

pub mod prelude {
    pub use flowy_core_infra::entities::{app::*, trash::*, view::*, workspace::*};

    pub use crate::{core::*, errors::*, module::*};
}
