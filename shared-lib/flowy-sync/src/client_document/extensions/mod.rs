pub use delete::*;
pub use format::*;
pub use insert::*;
use lib_ot::{
    core::Interval,
    rich_text::{RichTextDelta, TextAttribute},
};

mod delete;
mod format;
mod helper;
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
    fn apply(&self, delta: &RichTextDelta, interval: Interval, attribute: &TextAttribute) -> Option<RichTextDelta>;
}

pub trait DeleteExt {
    fn ext_name(&self) -> &str;
    fn apply(&self, delta: &RichTextDelta, interval: Interval) -> Option<RichTextDelta>;
}
