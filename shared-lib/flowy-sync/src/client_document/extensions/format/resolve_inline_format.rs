use lib_ot::core::AttributeEntry;
use lib_ot::text_delta::is_inline;
use lib_ot::{
    core::{Interval, OperationBuilder, OperationIterator},
    text_delta::{AttributeScope, TextDelta},
};

use crate::{
    client_document::{extensions::helper::line_break, FormatExt},
    util::find_newline,
};

pub struct ResolveInlineFormat {}
impl FormatExt for ResolveInlineFormat {
    fn ext_name(&self) -> &str {
        "ResolveInlineFormat"
    }

    fn apply(&self, delta: &TextDelta, interval: Interval, attribute: &AttributeEntry) -> Option<TextDelta> {
        if !is_inline(&attribute.key) {
            return None;
        }
        let mut new_delta = OperationBuilder::new().retain(interval.start).build();
        let mut iter = OperationIterator::from_offset(delta, interval.start);
        let mut start = 0;
        let end = interval.size();

        while start < end && iter.has_next() {
            let next_op = iter.next_op_with_len(end - start).unwrap();
            match find_newline(next_op.get_data()) {
                None => new_delta.retain(next_op.len(), attribute.clone().into()),
                Some(_) => {
                    let tmp_delta = line_break(&next_op, attribute, AttributeScope::Inline);
                    new_delta.extend(tmp_delta);
                }
            }

            start += next_op.len();
        }

        Some(new_delta)
    }
}
