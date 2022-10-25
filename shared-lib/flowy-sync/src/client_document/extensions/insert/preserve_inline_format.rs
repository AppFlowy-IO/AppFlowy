use crate::{
    client_document::InsertExt,
    util::{contain_newline, is_newline},
};
use lib_ot::{
    core::{DeltaOperationBuilder, OpNewline, OperationIterator, NEW_LINE},
    text_delta::{empty_attributes, BuildInTextAttributeKey, DeltaTextOperations},
};

pub struct PreserveInlineFormat {}
impl InsertExt for PreserveInlineFormat {
    fn ext_name(&self) -> &str {
        "PreserveInlineFormat"
    }

    fn apply(
        &self,
        delta: &DeltaTextOperations,
        replace_len: usize,
        text: &str,
        index: usize,
    ) -> Option<DeltaTextOperations> {
        if contain_newline(text) {
            return None;
        }

        let mut iter = OperationIterator::new(delta);
        let prev = iter.next_op_with_len(index)?;
        if OpNewline::parse(&prev).is_contain() {
            return None;
        }

        let mut attributes = prev.get_attributes();
        if attributes.is_empty() || !attributes.contains_key(BuildInTextAttributeKey::Link.as_ref()) {
            return Some(
                DeltaOperationBuilder::new()
                    .retain(index + replace_len)
                    .insert_with_attributes(text, attributes)
                    .build(),
            );
        }

        let next = iter.next_op();
        match &next {
            None => attributes = empty_attributes(),
            Some(next) => {
                if OpNewline::parse(next).is_equal() {
                    attributes = empty_attributes();
                }
            }
        }

        let new_delta = DeltaOperationBuilder::new()
            .retain(index + replace_len)
            .insert_with_attributes(text, attributes)
            .build();

        Some(new_delta)
    }
}

pub struct PreserveLineFormatOnSplit {}
impl InsertExt for PreserveLineFormatOnSplit {
    fn ext_name(&self) -> &str {
        "PreserveLineFormatOnSplit"
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
        let prev = iter.next_op_with_len(index)?;
        if OpNewline::parse(&prev).is_end() {
            return None;
        }

        let next = iter.next_op()?;
        let newline_status = OpNewline::parse(&next);
        if newline_status.is_end() {
            return None;
        }

        let mut new_delta = DeltaTextOperations::new();
        new_delta.retain(index + replace_len, empty_attributes());

        if newline_status.is_contain() {
            debug_assert!(!next.has_attribute());
            new_delta.insert(NEW_LINE, empty_attributes());
            return Some(new_delta);
        }

        match iter.next_op_with_newline() {
            None => {}
            Some((newline_op, _)) => {
                new_delta.insert(NEW_LINE, newline_op.get_attributes());
            }
        }

        Some(new_delta)
    }
}
