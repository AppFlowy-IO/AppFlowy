use crate::core::{Attribute, Delta, Interval};

pub trait InsertExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta>;
}

pub trait FormatExt {
    fn apply(&self, delta: &Delta, interval: Interval, attribute: &Attribute) -> Option<Delta>;
}

pub trait DeleteExt {
    fn apply(&self, delta: &Delta, interval: Interval) -> Option<Delta>;
}
