use crate::{
    client::view::InsertExt,
    core::{attributes_at_index, Attributes, AttributesIter, Builder, Delta, Interval},
};

pub struct PreserveInlineStyleExt {}

impl PreserveInlineStyleExt {
    pub fn new() -> Self { Self {} }
}

impl InsertExt for PreserveInlineStyleExt {
    fn apply(&self, delta: &Delta, text: &str, index: usize) -> Delta {
        let attributes = attributes_at_index(delta, index);
        let mut delta = Delta::new();
        let insert = Builder::insert(text).attributes(attributes).build();
        delta.add(insert);

        delta
    }
}
