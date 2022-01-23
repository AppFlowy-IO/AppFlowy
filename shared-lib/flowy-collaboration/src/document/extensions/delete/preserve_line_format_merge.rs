use crate::{document::DeleteExt, util::is_newline};
use lib_ot::{
    core::{Attributes, DeltaBuilder, DeltaIter, Interval, Utf16CodeUnitMetric, NEW_LINE},
    rich_text::{plain_attributes, RichTextDelta},
};

pub struct PreserveLineFormatOnMerge {}
impl DeleteExt for PreserveLineFormatOnMerge {
    fn ext_name(&self) -> &str {
        "PreserveLineFormatOnMerge"
    }

    fn apply(&self, delta: &RichTextDelta, interval: Interval) -> Option<RichTextDelta> {
        if interval.is_empty() {
            return None;
        }

        // seek to the  interval start pos. e.g. You backspace enter pos
        let mut iter = DeltaIter::from_offset(delta, interval.start);

        // op will be the "\n"
        let newline_op = iter.next_op_with_len(1)?;
        if !is_newline(newline_op.get_data()) {
            return None;
        }

        iter.seek::<Utf16CodeUnitMetric>(interval.size() - 1);
        let mut new_delta = DeltaBuilder::new()
            .retain(interval.start)
            .delete(interval.size())
            .build();

        while iter.has_next() {
            match iter.next() {
                None => log::error!("op must be not None when has_next() return true"),
                Some(op) => {
                    //
                    match op.get_data().find(NEW_LINE) {
                        None => {
                            new_delta.retain(op.len(), plain_attributes());
                            continue;
                        }
                        Some(line_break) => {
                            let mut attributes = op.get_attributes();
                            attributes.mark_all_as_removed_except(None);

                            if newline_op.has_attribute() {
                                attributes.extend_other(newline_op.get_attributes());
                            }

                            new_delta.retain(line_break, plain_attributes());
                            new_delta.retain(1, attributes);
                            break;
                        }
                    }
                }
            }
        }

        Some(new_delta)
    }
}
