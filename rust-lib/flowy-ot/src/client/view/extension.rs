use crate::{
    client::{view::insert_ext::*, Document},
    core::{Attributes, Interval},
};
use lazy_static::lazy_static;

pub trait InsertExt {
    fn apply(document: &Document, s: &str, interval: Interval);
}

pub trait FormatExt {
    fn apply(document: &Document, interval: Interval, attributes: Attributes);
}

pub trait DeleteExt {
    fn apply(document: &Document, interval: Interval);
}

lazy_static! {
    static ref INSERT_EXT: Vec<Box<InsertExt>> = vec![PreserveInlineStyleExt::new(),];
    static ref FORMAT_EXT: Vec<Box<FormatExt>> = vec![];
    static ref DELETE_EXT: Vec<Box<DeleteExt>> = vec![];
}
