use crate::{
    client_document::InsertExt,
    util::{contain_newline, is_newline},
};
use lib_ot::{
    core::{DeltaBuilder, DeltaIter, OpNewline, NEW_LINE},
    rich_text::{plain_attributes, RichTextAttributeKey, RichTextDelta},
};

pub struct PreserveInlineFormat {}
impl InsertExt for PreserveInlineFormat {
    fn ext_name(&self) -> &str {
        "PreserveInlineFormat"
    }

    fn apply(&self, delta: &RichTextDelta, replace_len: usize, text: &str, index: usize) -> Option<RichTextDelta> {
        if contain_newline(text) {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        let prev = iter.next_op_with_len(index)?;
        if OpNewline::parse(&prev).is_contain() {
            return None;
        }

        let mut attributes = prev.get_attributes();
        if attributes.is_empty() || !attributes.contains_key(&RichTextAttributeKey::Link) {
            return Some(
                DeltaBuilder::new()
                    .retain(index + replace_len)
                    .insert_with_attributes(text, attributes)
                    .build(),
            );
        }

        let next = iter.next_op();
        match &next {
            None => attributes = plain_attributes(),
            Some(next) => {
                if OpNewline::parse(next).is_equal() {
                    attributes = plain_attributes();
                }
            }
        }

        let new_delta = DeltaBuilder::new()
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

    fn apply(&self, delta: &RichTextDelta, replace_len: usize, text: &str, index: usize) -> Option<RichTextDelta> {
        if !is_newline(text) {
            return None;
        }

        let mut iter = DeltaIter::new(delta);
        let prev = iter.next_op_with_len(index)?;
        if OpNewline::parse(&prev).is_end() {
            return None;
        }

        let next = iter.next_op()?;
        let newline_status = OpNewline::parse(&next);
        if newline_status.is_end() {
            return None;
        }

        let mut new_delta = RichTextDelta::new();
        new_delta.retain(index + replace_len, plain_attributes());

        if newline_status.is_contain() {
            debug_assert!(!next.has_attribute());
            new_delta.insert(NEW_LINE, plain_attributes());
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
