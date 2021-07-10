#![feature(try_trait)]

mod errors;
mod module;
mod request;
mod response;
mod service;
mod util;

mod data;
mod dispatch;
mod system;

pub use errors::Error;

pub mod prelude {
    pub use crate::{data::*, dispatch::*, errors::*, module::*, request::*, response::*};
}
