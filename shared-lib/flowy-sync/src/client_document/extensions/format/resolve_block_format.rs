use lib_ot::core::AttributeEntry;
use lib_ot::text_delta::is_block;
use lib_ot::{
    core::{DeltaOperationBuilder, Interval, OperationIterator},
    text_delta::{empty_attributes, AttributeScope, DeltaTextOperations},
};

use crate::{
    client_document::{extensions::helper::line_break, FormatExt},
    util::find_newline,
};

pub struct ResolveBlockFormat {}
impl FormatExt for ResolveBlockFormat {
    fn ext_name(&self) -> &str {
        "ResolveBlockFormat"
    }

    fn apply(
        &self,
        delta: &DeltaTextOperations,
        interval: Interval,
        attribute: &AttributeEntry,
    ) -> Option<DeltaTextOperations> {
        if !is_block(&attribute.key) {
            return None;
        }

        let mut new_delta = DeltaOperationBuilder::new().retain(interval.start).build();
        let mut iter = OperationIterator::from_offset(delta, interval.start);
        let mut start = 0;
        let end = interval.size();
        while start < end && iter.has_next() {
            let next_op = iter.next_op_with_len(end - start).unwrap();
            match find_newline(next_op.get_data()) {
                None => new_delta.retain(next_op.len(), empty_attributes()),
                Some(_) => {
                    let tmp_delta = line_break(&next_op, attribute, AttributeScope::Block);
                    new_delta.extend(tmp_delta);
                }
            }

            start += next_op.len();
        }

        while iter.has_next() {
            let op = iter.next_op().expect("Unexpected None, iter.has_next() must return op");

            match find_newline(op.get_data()) {
                None => new_delta.retain(op.len(), empty_attributes()),
                Some(line_break) => {
                    new_delta.retain(line_break, empty_attributes());
                    new_delta.retain(1, attribute.clone().into());
                    break;
                }
            }
        }

        Some(new_delta)
    }
}
