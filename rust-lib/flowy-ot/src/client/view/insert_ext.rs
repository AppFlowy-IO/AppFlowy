use crate::{
    client::{view::InsertExt, Document},
    core::Interval,
};

pub struct PreserveInlineStyleExt {}

impl PreserveInlineStyleExt {
    pub fn new() -> Self {}
}

impl InsertExt for PreserveInlineStyleExt {
    fn apply(document: &Document, s: &str, interval: Interval) { unimplemented!() }
}
