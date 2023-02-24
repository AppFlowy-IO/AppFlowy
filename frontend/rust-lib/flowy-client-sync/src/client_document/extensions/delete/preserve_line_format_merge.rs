use crate::{client_document::DeleteExt, util::is_newline};
use lib_ot::{
  core::{
    DeltaOperationBuilder, Interval, OperationAttributes, OperationIterator, Utf16CodeUnitMetric,
    NEW_LINE,
  },
  text_delta::{empty_attributes, DeltaTextOperations},
};

pub struct PreserveLineFormatOnMerge {}
impl DeleteExt for PreserveLineFormatOnMerge {
  fn ext_name(&self) -> &str {
    "PreserveLineFormatOnMerge"
  }

  fn apply(&self, delta: &DeltaTextOperations, interval: Interval) -> Option<DeltaTextOperations> {
    if interval.is_empty() {
      return None;
    }

    // seek to the  interval start pos. e.g. You backspace enter pos
    let mut iter = OperationIterator::from_offset(delta, interval.start);

    // op will be the "\n"
    let newline_op = iter.next_op_with_len(1)?;
    if !is_newline(newline_op.get_data()) {
      return None;
    }

    iter.seek::<Utf16CodeUnitMetric>(interval.size() - 1);
    let mut new_delta = DeltaOperationBuilder::new()
      .retain(interval.start)
      .delete(interval.size())
      .build();

    while iter.has_next() {
      match iter.next() {
        None => tracing::error!("op must be not None when has_next() return true"),
        Some(op) => {
          //
          match op.get_data().find(NEW_LINE) {
            None => {
              new_delta.retain(op.len(), empty_attributes());
              continue;
            },
            Some(line_break) => {
              let mut attributes = op.get_attributes();
              attributes.remove_all_value();

              if newline_op.has_attribute() {
                attributes.extend(newline_op.get_attributes());
              }

              new_delta.retain(line_break, empty_attributes());
              new_delta.retain(1, attributes);
              break;
            },
          }
        },
      }
    }

    Some(new_delta)
  }
}
