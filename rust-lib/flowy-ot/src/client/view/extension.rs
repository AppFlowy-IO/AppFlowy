use crate::{
    client::{view::insert_ext::*, Document},
    core::{Attributes, Delta, Interval},
};
use lazy_static::lazy_static;

pub trait InsertExt {
    fn apply(&self, delta: &Delta, s: &str, interval: Interval) -> Delta;
}

pub trait FormatExt {
    fn apply(&self, document: &Document, interval: Interval, attributes: Attributes);
}

pub trait DeleteExt {
    fn apply(&self, document: &Document, interval: Interval);
}
