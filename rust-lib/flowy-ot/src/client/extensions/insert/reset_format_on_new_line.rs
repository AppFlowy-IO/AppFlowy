use crate::{
    client::{
        extensions::{InsertExt, NEW_LINE},
        util::is_newline,
    },
    core::{AttributeKey, Attributes, CharMetric, Delta, DeltaBuilder, DeltaIter},
};

pub struct ResetLineFormatOnNewLineExt {}
impl InsertExt for ResetLineFormatOnNewLineExt {
    fn ext_name(&self) -> &str { "ResetLineFormatOnNewLineExt" }

    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        if !is_newline(text) {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        iter.seek::<CharMetric>(index);
        let next_op = iter.next()?;
        if !next_op.get_data().starts_with(NEW_LINE) {
            return None;
        }

        let mut reset_attribute = Attributes::new();
        if next_op.get_attributes().contains_key(&AttributeKey::Header) {
            reset_attribute.add(AttributeKey::Header.value(""));
        }

        let len = index + replace_len;
        Some(
            DeltaBuilder::new()
                .retain(len)
                .insert_with_attributes(NEW_LINE, next_op.get_attributes())
                .retain_with_attributes(1, reset_attribute)
                .trim()
                .build(),
        )
    }
}
