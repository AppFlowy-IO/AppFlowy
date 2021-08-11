use crate::{
    client::{view::InsertExt, Document},
    core::{Builder, Delta, Interval},
};

pub struct PreserveInlineStyleExt {}

impl PreserveInlineStyleExt {
    pub fn new() -> Self { Self {} }
}

impl InsertExt for PreserveInlineStyleExt {
    fn apply(&self, delta: &Delta, s: &str, interval: Interval) -> Delta {
        // let mut delta = Delta::default();
        // let insert = Builder::insert(text).attributes(attributes).build();
        // let interval = Interval::new(index, index);
        // delta.add(insert);
        //
        // delta
        unimplemented!()
    }
}
