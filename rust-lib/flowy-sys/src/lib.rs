#![feature(try_trait)]

mod error;
mod module;
mod request;
mod response;
mod rt;
mod service;
mod util;

mod data;
mod dispatch;
mod system;

pub mod prelude {
    pub use crate::{data::*, dispatch::*, error::*, module::*, request::*, response::*, rt::*};
}
