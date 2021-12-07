pub use delete::*;
pub use format::*;
pub use insert::*;

use lib_ot::core::{Interval, RichTextAttribute, RichTextDelta};

mod delete;
mod format;
mod insert;

pub type InsertExtension = Box<dyn InsertExt + Send + Sync>;
pub type FormatExtension = Box<dyn FormatExt + Send + Sync>;
pub type DeleteExtension = Box<dyn DeleteExt + Send + Sync>;

pub trait InsertExt {
    fn ext_name(&self) -> &str;
    fn apply(&self, delta: &RichTextDelta, replace_len: usize, text: &str, index: usize) -> Option<RichTextDelta>;
}

pub trait FormatExt {
    fn ext_name(&self) -> &str;
    fn apply(&self, delta: &RichTextDelta, interval: Interval, attribute: &RichTextAttribute) -> Option<RichTextDelta>;
}

pub trait DeleteExt {
    fn ext_name(&self) -> &str;
    fn apply(&self, delta: &RichTextDelta, interval: Interval) -> Option<RichTextDelta>;
}
