mod domain;
mod error;
pub mod event;
mod handlers;
pub mod module;
mod protobuf;

pub mod prelude {
    pub use crate::{
        domain::*,
        event::{UserEvent::*, *},
        handlers::auth::*,
    };
}
