use crate::{client_document::InsertExt, util::is_newline};
use lib_ot::core::AttributeHashMap;
use lib_ot::{
    core::{DeltaOperationBuilder, OperationIterator, Utf16CodeUnitMetric, NEW_LINE},
    text_delta::{BuildInTextAttributeKey, DeltaTextOperations},
};

pub struct ResetLineFormatOnNewLine {}
impl InsertExt for ResetLineFormatOnNewLine {
    fn ext_name(&self) -> &str {
        "ResetLineFormatOnNewLine"
    }

    fn apply(
        &self,
        delta: &DeltaTextOperations,
        replace_len: usize,
        text: &str,
        index: usize,
    ) -> Option<DeltaTextOperations> {
        if !is_newline(text) {
            return None;
        }

        let mut iter = OperationIterator::new(delta);
        iter.seek::<Utf16CodeUnitMetric>(index);
        let next_op = iter.next_op()?;
        if !next_op.get_data().starts_with(NEW_LINE) {
            return None;
        }

        let mut reset_attribute = AttributeHashMap::new();
        if next_op
            .get_attributes()
            .contains_key(BuildInTextAttributeKey::Header.as_ref())
        {
            reset_attribute.remove_value(BuildInTextAttributeKey::Header);
        }

        let len = index + replace_len;
        Some(
            DeltaOperationBuilder::new()
                .retain(len)
                .insert_with_attributes(NEW_LINE, next_op.get_attributes())
                .retain_with_attributes(1, reset_attribute)
                .trim()
                .build(),
        )
    }
}
