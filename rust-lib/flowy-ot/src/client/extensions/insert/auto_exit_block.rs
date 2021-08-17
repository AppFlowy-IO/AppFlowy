use crate::{
    client::{extensions::InsertExt, util::is_newline},
    core::{
        AttributeKey,
        AttributeValue,
        Attributes,
        CharMetric,
        Delta,
        DeltaBuilder,
        DeltaIter,
        Operation,
    },
};

use crate::core::{attributes_except_header, is_empty_line_at_index};

pub struct AutoExitBlock {}

impl InsertExt for AutoExitBlock {
    fn ext_name(&self) -> &str { std::any::type_name::<AutoExitBlock>() }

    fn apply(&self, delta: &Delta, replace_len: usize, text: &str, index: usize) -> Option<Delta> {
        // Auto exit block will be triggered by enter two new lines
        if !is_newline(text) {
            return None;
        }

        if !is_empty_line_at_index(delta, index) {
            return None;
        }

        let mut iter = DeltaIter::from_offset(delta, index);
        let next = iter.next_op()?;
        let mut attributes = next.get_attributes();

        let block_attributes = attributes_except_header(&next);
        if block_attributes.is_empty() {
            return None;
        }

        if next.len() > 1 {
            return None;
        }

        match iter.first_newline_op() {
            None => {},
            Some((newline_op, _)) => {
                let newline_attributes = attributes_except_header(&newline_op);
                if block_attributes == newline_attributes {
                    return None;
                }
            },
        }

        attributes.mark_as_removed_except(&AttributeKey::Header);

        Some(
            DeltaBuilder::new()
                .retain(index + replace_len)
                .retain_with_attributes(1, attributes)
                .build(),
        )
    }
}
