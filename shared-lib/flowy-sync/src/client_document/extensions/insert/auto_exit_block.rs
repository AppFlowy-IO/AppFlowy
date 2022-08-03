use crate::{client_document::InsertExt, util::is_newline};
use lib_ot::core::{is_empty_line_at_index, DeltaBuilder, DeltaIterator};
use lib_ot::rich_text::{attributes_except_header, RichTextAttributeKey, RichTextDelta};

pub struct AutoExitBlock {}

impl InsertExt for AutoExitBlock {
    fn ext_name(&self) -> &str {
        "AutoExitBlock"
    }

    fn apply(&self, delta: &RichTextDelta, replace_len: usize, text: &str, index: usize) -> Option<RichTextDelta> {
        // Auto exit block will be triggered by enter two new lines
        if !is_newline(text) {
            return None;
        }

        if !is_empty_line_at_index(delta, index) {
            return None;
        }

        let mut iter = DeltaIterator::from_offset(delta, index);
        let next = iter.next_op()?;
        let mut attributes = next.get_attributes();

        let block_attributes = attributes_except_header(&next);
        if block_attributes.is_empty() {
            return None;
        }

        if next.len() > 1 {
            return None;
        }

        match iter.next_op_with_newline() {
            None => {}
            Some((newline_op, _)) => {
                let newline_attributes = attributes_except_header(&newline_op);
                if block_attributes == newline_attributes {
                    return None;
                }
            }
        }

        attributes.mark_all_as_removed_except(Some(RichTextAttributeKey::Header));

        Some(
            DeltaBuilder::new()
                .retain(index + replace_len)
                .retain_with_attributes(1, attributes)
                .build(),
        )
    }
}
