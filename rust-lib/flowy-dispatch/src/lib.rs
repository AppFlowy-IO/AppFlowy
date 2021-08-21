mod errors;
mod module;
mod request;
mod response;
mod service;
mod util;

mod byte_trait;
mod data;
mod dispatch;
mod system;

#[macro_use]
pub mod macros;

pub use errors::Error;

pub mod prelude {
    pub use crate::{
        byte_trait::*,
        data::*,
        dispatch::*,
        errors::*,
        module::*,
        request::*,
        response::*,
    };
}
