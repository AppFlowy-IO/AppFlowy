use crate::{
    client::view::InsertExt,
    core::{
        attributes_at_index,
        AttributeKey,
        Attributes,
        Delta,
        DeltaBuilder,
        DeltaIter,
        Operation,
    },
};

pub const NEW_LINE: &'static str = "\n";

pub struct PreserveInlineStyleExt {}
impl PreserveInlineStyleExt {
    pub fn new() -> Self { Self {} }
}

impl InsertExt for PreserveInlineStyleExt {
    fn apply(&self, delta: &Delta, _replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if text.ends_with(NEW_LINE) {
            return None;
        }

        let attributes = attributes_at_index(delta, index);
        let delta = DeltaBuilder::new().insert(text, attributes).build();

        Some(delta)
    }
}

pub struct ResetLineFormatOnNewLineExt {}

impl ResetLineFormatOnNewLineExt {
    pub fn new() -> Self { Self {} }
}

impl InsertExt for ResetLineFormatOnNewLineExt {
    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if text != NEW_LINE {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        iter.seek_to(index);
        let maybe_next_op = iter.next();
        if maybe_next_op.is_none() {
            return None;
        }

        let op = maybe_next_op.unwrap();
        if !op.get_data().starts_with(NEW_LINE) {
            return None;
        }

        let mut reset_attribute = Attributes::new();
        if op.get_attributes().contains_key(&AttributeKey::Header) {
            reset_attribute.add(AttributeKey::Header.with_value(""));
        }

        let len = index + replace_len;
        Some(
            DeltaBuilder::new()
                .retain(len, Attributes::default())
                .insert(NEW_LINE, op.get_attributes())
                .retain(1, reset_attribute)
                .trim()
                .build(),
        )
    }
}
