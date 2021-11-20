pub use delete::*;
pub use format::*;
pub use insert::*;

use lib_ot::core::{Attribute, Delta, Interval};

mod delete;
mod format;
mod insert;

pub type InsertExtension = Box<dyn InsertExt + Send + Sync>;
pub type FormatExtension = Box<dyn FormatExt + Send + Sync>;
pub type DeleteExtension = Box<dyn DeleteExt + Send + Sync>;

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
