#![feature(try_trait)]

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
