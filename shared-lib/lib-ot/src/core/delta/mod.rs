#![allow(clippy::module_inception)]
mod builder;
mod cursor;
mod iterator;
pub mod operation;
mod ops;
mod ops_serde;

pub use builder::*;
pub use cursor::*;
pub use iterator::*;
pub use ops::*;

pub const NEW_LINE: &str = "\n";
pub const WHITESPACE: &str = " ";
