use crate::core::{Attribute, Delta, Interval};

pub type InsertExtension = Box<dyn InsertExt>;
pub type FormatExtension = Box<dyn FormatExt>;
pub type DeleteExtension = Box<dyn DeleteExt>;

pub trait InsertExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta>;
}

pub trait FormatExt {
    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta>;
}

pub trait DeleteExt {
    fn apply(&self, delta: &Delta, interval: Interval) -> Option<Delta>;
}
