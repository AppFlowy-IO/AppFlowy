use crate::{
    client::{
        extensions::InsertExt,
        util::{contain_newline, OpNewline},
    },
    core::{AttributeKey, Attributes, CharMetric, Delta, DeltaBuilder, DeltaIter},
};

pub struct PreserveInlineStylesExt {}
impl InsertExt for PreserveInlineStylesExt {
    fn ext_name(&self) -> &str { "PreserveInlineStylesExt" }

    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if contain_newline(text) {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        let prev = iter.next_op_before(index)?;
        if OpNewline::parse(&prev).is_contain() {
            return None;
        }

        let mut attributes = prev.get_attributes();
        if attributes.is_empty() || !attributes.contains_key(&AttributeKey::Link) {
            return Some(
                DeltaBuilder::new()
                    .retain(index + replace_len)
                    .insert_with_attributes(text, attributes)
                    .build(),
            );
        }

        let next = iter.next_op();
        match &next {
            None => attributes = Attributes::empty(),
            Some(next) => {
                if OpNewline::parse(&next).is_equal() {
                    attributes = Attributes::empty();
                }
            },
        }

        let new_delta = DeltaBuilder::new()
            .retain(index + replace_len)
            .insert_with_attributes(text, attributes)
            .build();

        return Some(new_delta);
    }
}
