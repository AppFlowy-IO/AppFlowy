pub use delete::*;
pub use format::*;
pub use insert::*;
use lib_ot::core::AttributeEntry;
use lib_ot::{core::Interval, text_delta::TextDelta};

mod delete;
mod format;
mod helper;
mod insert;

pub type InsertExtension = Box<dyn InsertExt + Send + Sync>;
pub type FormatExtension = Box<dyn FormatExt + Send + Sync>;
pub type DeleteExtension = Box<dyn DeleteExt + Send + Sync>;

pub trait InsertExt {
    fn ext_name(&self) -> &str;
    fn apply(&self, delta: &TextDelta, replace_len: usize, text: &str, index: usize) -> Option<TextDelta>;
}

pub trait FormatExt {
    fn ext_name(&self) -> &str;
    fn apply(&self, delta: &TextDelta, interval: Interval, attribute: &AttributeEntry) -> Option<TextDelta>;
}

pub trait DeleteExt {
    fn ext_name(&self) -> &str;
    fn apply(&self, delta: &TextDelta, interval: Interval) -> Option<TextDelta>;
}
