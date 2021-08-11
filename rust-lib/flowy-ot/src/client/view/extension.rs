use crate::{
    client::Document,
    core::{Attributes, Delta, Interval},
};

pub trait InsertExt {
    fn apply(&self, delta: &Delta, s: &str, index: usize) -> Delta;
}

pub trait FormatExt {
    fn apply(&self, document: &Document, interval: Interval, attributes: Attributes);
}

pub trait DeleteExt {
    fn apply(&self, document: &Document, interval: Interval);
}
