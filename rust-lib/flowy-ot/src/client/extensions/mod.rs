pub use delete::*;
pub use format::*;
pub use insert::*;

use crate::core::{Attribute, Delta, Interval};

mod delete;
mod format;
mod insert;

pub const NEW_LINE: &'static str = "\n";

pub type InsertExtension = Box<dyn InsertExt>;
pub type FormatExtension = Box<dyn FormatExt>;
pub type DeleteExtension = Box<dyn DeleteExt>;

pub trait InsertExt {
    fn ext_name(&self) -> &str;
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta>;
}

pub trait FormatExt {
    fn ext_name(&self) -> &str;
    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta>;
}

pub trait DeleteExt {
    fn ext_name(&self) -> &str;
    fn apply(&self, delta: &Delta, interval: Interval) -> Option<Delta>;
}
