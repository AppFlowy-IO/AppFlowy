mod domain;
mod error;
mod handlers;
pub mod module;
mod protobuf;

pub mod prelude {
    pub use crate::{domain::*, handlers::auth::*};
}
