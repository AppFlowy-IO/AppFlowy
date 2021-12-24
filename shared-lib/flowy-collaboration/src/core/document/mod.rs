#![allow(clippy::module_inception)]

pub use document::*;
pub(crate) use extensions::*;
pub use view::*;

mod data;
pub mod default;
mod document;
mod extensions;
pub mod history;
mod view;
