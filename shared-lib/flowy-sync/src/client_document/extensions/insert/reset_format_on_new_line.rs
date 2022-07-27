use crate::{client_document::InsertExt, util::is_newline};
use lib_ot::{
    core::{DeltaBuilder, DeltaIterator, Utf16CodeUnitMetric, NEW_LINE},
    rich_text::{RichTextAttributeKey, RichTextAttributes, RichTextDelta},
};

pub struct ResetLineFormatOnNewLine {}
impl InsertExt for ResetLineFormatOnNewLine {
    fn ext_name(&self) -> &str {
        "ResetLineFormatOnNewLine"
    }

    fn apply(&self, delta: &RichTextDelta, replace_len: usize, text: &str, index: usize) -> Option<RichTextDelta> {
        if !is_newline(text) {
            return None;
        }

        let mut iter = DeltaIterator::new(delta);
        iter.seek::<Utf16CodeUnitMetric>(index);
        let next_op = iter.next_op()?;
        if !next_op.get_data().starts_with(NEW_LINE) {
            return None;
        }

        let mut reset_attribute = RichTextAttributes::new();
        if next_op.get_attributes().contains_key(&RichTextAttributeKey::Header) {
            reset_attribute.delete(&RichTextAttributeKey::Header);
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
