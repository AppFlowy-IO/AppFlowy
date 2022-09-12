#![allow(clippy::module_inception)]
mod builder;
mod cursor;
mod delta;
mod delta_serde;
mod iterator;
pub mod operation;

pub use builder::*;
pub use cursor::*;
pub use delta::*;
pub use iterator::*;

pub const NEW_LINE: &str = "\n";
pub const WHITESPACE: &str = " ";
